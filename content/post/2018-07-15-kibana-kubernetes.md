---
layout:     post
title:      "Kibana on Kubernetes"
subtitle:   "Visualize your Elasticsearch data."
date:       2018-07-15
author:     "Craig Johnston"
URL:        "kibana-kubernetes/"
image:      "/img/post/k.jpg"
twitter_image: "/img/post/k_876_438.jpg"
tags:
- Kubernetes
- Elasticsearch
- Data
- Kibana
series:
- Kubernetes
---

This guide walks through a process for setting up [Kibana] within a [namespace] on a Kubernetes cluster. If you followed along with [Production Grade Elasticsearch on Kubernetes] then aside from personal or corporate preferences, little modifications are necessary for the configurations below.

<!--more-->

{{< toc >}}

{{< content-ad >}}

## Project [Namespace]

I use `the-project` as a namespace for all my examples and testing. [Kubernetes Namespaces] are the main delimiter I use for security and organization. Configuration files are organized by project, and in Kubernetes, these projects are separated by namespace; therefore I always include a namespace configuration. There is no harm in asking Kubernetes to create a namespace that already exists; an error is returned confirming its existence.

`00-namespace.yml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: the-project
  labels:
    env: dev
```

Create the namespace:
```bash
kubectl create -f 00-namespace.yml
```

## [Service]

I prefer setting up a [Service] early on in the process of configuring up a new application. In Kubernetes, [Service]s persist where many other components can come and go. Microservices in Kubernetes communicate through services rather than having to discover or rely on [Pods] directly. The service name and port automatically route traffic to Pods found with their selector.

`20-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: the-project
  labels:
    app: kibana
    env: dev
spec:
  selector:
    app: kibana
  ports:
  - protocol: "TCP"
    port: 80
    targetPort: 5601
  type: ClusterIP
```

Create the service:
```bash
kubectl create -f 20-service.yml
```

In the configuration above, communicating within the Kubernetes cluster and in `the-project` namespace, the url http://kibana:80 uses the new service to route traffic to any pods with the [label] **app: kibana** listening on port 5601.

The ports are internal to the service and the Pods and can be assigned any legal value. Kibana listens on port 5601 by default, so we leave that as is. Port 80 on the [service] is to remind us that this is an HTTP web service, but can easily be any legal port value. We use [ingress] in later steps to direct external traffic to the new [kibana service].

## Kibana [ConfigMap]

Kibana uses the configuration file **[kibana.yml]**. Pods running Kibana are set up in the deployment further down this guide. The deployment instructs the Pods to mount this [ConfigMap] as a file system from which Kibana accesses the data key `kibana.yml:` as a file.

`30-configmap.yml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kibana
  namespace: the-project
  labels:
    app: kibana
    env: dev
data:
  # kibana.yml is mounted into the Kibana container
  # see https://github.com/elastic/kibana/blob/master/config/kibana.yml
  # Kubernetes Ingress is used to route kib.the-project.d4ldev.txn2.com
  kibana.yml: |-
    server.name: kib.the-project.d4ldev.txn2.com
    server.host: "0"
    elasticsearch.url: http://elasticsearch:9200
```

Create the configmap:
```bash
kubectl create -f 30-configmap.yml
```

## Deployment

The Kubernetes Kibana deployment below is set to create one replica, that is one Pod in the [ReplicaSet] automatically created by the Deployment. The Deployment and can be scaled as needed by changing **replicas: 1** to a suitable value.

The volume **kibana-config-volume** is configured as part of the **spec:** for the Pod template in the Deployment. **kibana-config-volume** attaches to the [Kibana ConfigMap](#kibana-configmap) created above. Later, in the containers section, the **volumeMounts:** this **kibana-config-volume** to the directory **/usr/share/kibana/config** inside the Kibana container. By default Kibana looks in **/usr/share/kibana/config** to find the [kibana.yml] configuration file.

Elastic maintains an official set of Docker containers for Kibana at [www.docker.elastic.co]. If you followed along with the previous article [Production Grade Elasticsearch on Kubernetes], you might remember setting **CLUSTER_NAME** to **elasticsearch** in the StatefulSet and Deployments.

The **containerPort: 5601** is exposed as Kibana listens on 5601 by default unless changed in the [Kibana ConfigMap](#kibana-configmap) above.

`40-deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: the-project
  labels:
    app: kibana
    env: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
        env: dev
    spec:
      volumes:
      - name: kibana-config-volume
        configMap:
          name: kibana
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana-oss:6.2.4
        imagePullPolicy: Always
        volumeMounts:
        - name: kibana-config-volume
          mountPath: /usr/share/kibana/config
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        ports:
        - name: http
          containerPort: 5601
```

Create the deployment:
```bash
kubectl create -f 40-deployment.yml
```

## [Basic Auth] (Optional)

Described below are a few commands to get you started, however, for a more in-depth review check out my article [Basic Auth on Kubernetes Ingress].

The [kubectl] makes it easy to create a Kubernetes [Secret] we can use for Basic Auth on our [Ingress Nginx][Ingress on Custom Kubernetes] we set up further down this guide.

Begin with using the [htpasswd] command to generate the file `auth` with a user named **kibop** and a password specified when prompted. [kubectl] uses this file as-generated to create the appropriate [Secret] needed for Basic Auth.

```bash
htpasswd -c ./auth kibop
```

In this example, I create a user named **kibop** for Basic Auth, kubectl pulls the user and password combination for **kibop** from the **auth** file created above and uses the filename as the key. It is essential to name the file **auth** since this is a necessary key for Ingress to find the Basic Auth credentials.

```bash
kubectl create secret generic kibop-basic-auth --from-file auth -n the-project
```

Our namespace `the-project` now has the secret **kibop-basic-auth** we use to password-protect Kibana in the [ingress] configuration further down.

## TLS Certificate (Optional)

It is highly recommended to encrypt all traffic to and from Kibana with TLS (HTTPS). I recommend configuring your Kubernetes cluster to use [Let's Encrypt], it's secure, free and takes about 15 minutes to set up. After setting up [Let's Encrypt], you can generate and renew certificates automatically.


`50-cert.yml`:
```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: kib-dev-cert
  namespace: the-project
spec:
  secretName: kib-dev-production-tls
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: kib.the-project.d4ldev.txn2.com
  dnsNames:
  - kib.the-project.d4ldev.txn2.com
  acme:
    config:
    - http01:
        ingressClass: nginx
      domains:
      - kib.the-project.d4ldev.txn2.com
    - http01:
        ingressClass: nginx
      domains:
      - kib.the-project.d4ldev.txn2.com
```

Create the certificate:
```bash
kubectl create -f 50-cert.yml
```

## [Ingress]

[Ingress] on Kubernetes routes outside traffic to a [Service] inside the cluster. You need an Ingress controller for this step. In this example, we configure the [Ingress Nginx][Ingress on Custom Kubernetes] controller. If you are using a different Ingress controller, you need to consult the appropriate documentation. If you do not already have an Ingress controller, then I recommend reading [Ingress on Custom Kubernetes] for a quick guide on setting up [Ingress Nginx][Ingress on Custom Kubernetes].

`60-ingress.yml`:
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kibana
  namespace: the-project
  labels:
    app: kibana
    env: dev
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: kibop-basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  rules:
  - host: kib.the-project.d4ldev.txn2.com
    http:
      paths:
      - backend:
          serviceName: kibana
          servicePort: 80
        path: /
  tls:
  - hosts:
    - kib.the-project.d4ldev.txn2.com
    secretName: kib-dev-production-tls

```

If you are not using **Basic Auth** or **TLS** certificates you need to omit the **annotations** and **tls** sections. However, setting up [Let's Encrypt] and [Basic Auth](#basic-auth-optional) is quick and relatively simple.

Create the ingress:
```bash
kubectl create -f 60-ingress.yml
```

## Conclusion

You now have [Kibana] up and running in Kubernetes and pointed to your [Production Grade Elasticsearch on Kubernetes]. Check out the official [Kibana Documentation].

## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

## Resources

- [Production Grade Elasticsearch on Kubernetes]
- [Kibana]
- [Basic Auth on Kubernetes Ingress]
- Setting up [Let's Encrypt] on Kubernetes

[www.docker.elastic.co]:https://www.docker.elastic.co/#kibana
[kibana service]: #service
[Kubernetes Namespaces]:https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[namespace]: /kubernetes-production-elasticsearch/#project-namespace
[Kibana]: https://www.elastic.co/products/kibana
[Production Grade Elasticsearch on Kubernetes]: /kubernetes-production-elasticsearch/
[Service]:https://kubernetes.io/docs/concepts/services-networking/service/
[Pods]:https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/
[label]:https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
[ConfigMap]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap
[kibana.yml]:https://github.com/elastic/kibana/blob/master/config/kibana.yml
[ReplicaSet]:https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[Basic Auth]: /kubernetes-ingress-basic-auth/
[Basic Auth on Kubernetes Ingress]: /kubernetes-ingress-basic-auth/
[kubectl]:https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[Ingress]:/web-cluster-ingress/
[Ingress on Custom Kubernetes]:/web-cluster-ingress/
[Secret]:https://kubernetes.io/docs/concepts/configuration/secret/
[htpasswd]:https://httpd.apache.org/docs/2.4/programs/htpasswd.html
[Let's Encrypt]:/lets-encrypt-kubernetes/
[Kibana Documentation]: https://www.elastic.co/guide/en/kibana/current/index.html
