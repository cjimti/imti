---
layout:     post
title:      "Ingress on Custom Kubernetes"
subtitle:   "Setting up ingress-nginx on a custom cluster."
date:       2018-05-15
author:     "Craig Johnston"
URL:        "web-cluster-ingress/"
image:      "/img/post/hoses.jpg"
twitter_image: "/img/post/hoses_876_438.jpg"
tags:
- Kubernetes
- ingress
- nginx
series:
- Kubernetes
---

There are more than a handful of ways to set up port **80** and **443** web [ingress] on a custom [Kubernetes] cluster. Specifically a bare metal cluster. If you are looking to experiment or learn on a non-production cluster, but something more true to production than [minikube], I suggest you check out my previous article [Production Hobby Cluster], a step-by-step guide for setting up a custom production capable Kubernetes cluster.

<!--more-->

This article builds on the [Production Hobby Cluster] guide. The following closely the official [deploy ingress] Installation Guide with a few adjustments suitable for the [Production Hobby Cluster], specifically the use of a [DaemonSet] rather than a [Deployment] and leveraging **hostNetwork** and **hostPort** for the [Pod]s on our [DaemonSet]. There are quite a few [ingress nginx examples] in the official repository if you are looking for a more specific implementation.

By now you may be managing multiple clusters. [kubectl] is a great tool to use on your local workstation to manage remote clusters, and with little effort you can quickly point it to a new cluster and switch between them all day. Check out my article [kubectl Context Multiple Clusters](/kubectl-remote-context/) for a quick tutorial.

{{< content-ad >}}

### Namespace

Setup a new [namespace] called **ingress-nginx**

<script src="https://gist.github.com/cjimti/591d65a6940a87e7136bf0f51f438088.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/591d65a6940a87e7136bf0f51f438088/raw/0c5db06855d285d8a8b5bac1bfa6c9ed64b00c3b/00-namespace.yml
```

### Default Backend

Next, create a [Deployment] and a [Service] for the ingress controller.

<script src="https://gist.github.com/cjimti/78a8ce1be09a9e874f6af54a6c8e4714.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/78a8ce1be09a9e874f6af54a6c8e4714/raw/95b172435fbc2b4551daf375e19f569bd9cc3aec/01-default-backend.yml
```

### Ingress Nginx [ConfigMap]

Create an empty [ConfigMap] for **ingress-nginx**.

<script src="https://gist.github.com/cjimti/dc2841651c68a463b8990e6ce2ddb0c8.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/dc2841651c68a463b8990e6ce2ddb0c8/raw/2d4af61ac416e7494dac37c2eaf8bb024a1306a2/02-empty-configmap.yml
```

### TCP Services [ConfigMap]

Create an empty [ConfigMap] for **ingress-nginx** TCP Services.

<script src="https://gist.github.com/cjimti/66605e303591b61e1baa347547336f2c.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/66605e303591b61e1baa347547336f2c/raw/eb6d3a6d1c5d0a47e4105a21d73573cb8e844406/03-tcp-services-configmap.yaml
```

### UDP Services [ConfigMap]

Create an empty [ConfigMap] for **ingress-nginx** UDP Services.

<script src="https://gist.github.com/cjimti/ddb750c825e42ffd398da4590d4b61f7.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/ddb750c825e42ffd398da4590d4b61f7/raw/88061f9096e11be3457967b3ad5be6c2a1dcf68e/04-udp-services-configmap.yaml
```

### RBAC - Ingress Roles and Permissions

Here we setup a [ServiceAccount] named **nginx-ingress-serviceaccount**, a [ClusterRole] named **nginx-ingress-clusterrole**, a [Role] named **nginx-ingress-role**, a [RoleBinding] named **nginx-ingress-role-nisa-binding** and a [ClusterRoleBinding] named
**nginx-ingress-clusterrole-nisa-binding**:

<script src="https://gist.github.com/cjimti/b06886efc6313192282224d7c84c2151.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/b06886efc6313192282224d7c84c2151/raw/0c0c6501124c96d7229cafaeafe9f2a00db3fbea/05-rbac.yml
```

### [DaemonSet]

Creating a [DaemonSet] ensures that we have one Ingress Nginx controller [Pod] running on each node. Having an Ingress Controller on each node is crucial since we are using the host network and assigning the host ports 80 and 443 for HTTP and HTTPS ingress on each node. When adding a new node to the cluster, the [DaemonSet] ensures it gets an Ingress Nginx controller [Pod].

<script src="https://gist.github.com/cjimti/b9e820a18b06bd8a735b3b0676724826.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/b9e820a18b06bd8a735b3b0676724826/raw/d4a0317cfe4ae4c4739d1d04e94c55b8d1426a98/06-ds.yaml
```

### Service

Add an **ingress-nginx** [Service].

<script src="https://gist.github.com/cjimti/d733ed08d59b3779233fb6edc175bb75.js"></script>

Create using the configuration:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/d733ed08d59b3779233fb6edc175bb75/raw/a62765921f4fff395032d0e1f0a6db2cb773ab1c/07-service-nodeport.yaml
```

### Test

Make sure the **default-http-backend** [pod] and **nginx-ingress-controller** controller [pod]s are running, the **nginx-ingress-controller** should be running on each node.

```bash
kubectl get pods -n ingress-nginx -o wide

# example output
NAME                                   READY     STATUS    RESTARTS   AGE       IP               NODE
default-http-backend-5c6d95c48-wbvw9   1/1       Running   0          1d        10.42.0.0        la2
nginx-ingress-controller-v44xz         1/1       Running   0          1d        45.77.71.39      la2
nginx-ingress-controller-wbb52         1/1       Running   0          1d        149.28.77.205    la3
nginx-ingress-controller-wjhcf         1/1       Running   7          1d        108.61.214.169   la1

```

Test each node by issuing a simple `curl` call:

```bash
# Example call
curl -v 45.77.71.39/
*   Trying 45.77.71.39...
* TCP_NODELAY set
* Connected to 45.77.71.39 (45.77.71.39) port 80 (#0)
> GET / HTTP/1.1
> Host: 45.77.71.39
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 404 Not Found
< Server: nginx/1.13.12
< Date: Thu, 17 May 2018 20:50:32 GMT
< Content-Type: text/plain; charset=utf-8
< Content-Length: 21
< Connection: keep-alive
< 
* Connection #0 to host 45.77.71.39 left intact
default backend - 404
~

```

In this case, the **nginx-ingress-controller** [Pod] running on 45.77.71.39 responded adequately by passing the unknown route to the **default-http-backend** which correctly output a basic 404 page. Issue a `curl` call (or browse to them in a web browser) to each of your Nodes to test them.

### Add an Ingress

We are finally at a spot where we can start routing ingress to services. If you don't already have a service to route to, I recommend using the [txn2] **[ok]** service. [ok] is specifically designed to give useful information when testing [Pod] deployments.

#### [ok] Deployment

Here we add a [Deployment] of [ok] with one replica.

<script src="https://gist.github.com/cjimti/bc293996ddcc3bf0cb9e5c3514ef1853.js"></script>

Use the following command to add the [Deployment]:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/bc293996ddcc3bf0cb9e5c3514ef1853/raw/18a26df0df3d239b679446af8b7b55f29d2271ba/00-ok-deployment.yml
```

#### [ok] Service

Create an [ok] service to front-end our new [ok] [Deployment] above.

<script src="https://gist.github.com/cjimti/ae86bb7d3f777ac61e9ff9794ca52521.js"></script>

Use the following command to add the [Service]:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/ae86bb7d3f777ac61e9ff9794ca52521/raw/b4f4bf26bf5526953bcc4e0c538887bfa7be1484/10-ok-service.yml
```

#### [ok] Ingress

Finally, we have the easy task of creating an ingress route. The following is a minimal template since you need to point a domain name to your cluster:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ok
  labels:
    app: ok
    system: test
spec:
  rules:
  - host: ok.la.txn2.net
    http:
      paths:
      - backend:
          serviceName: ok
          servicePort: 8080
        path: /
```

I will go over https and managing certificates in future articles. For now you may want to checkout other [ingress nginx examples].

## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

---

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance [Hobby Cluster]s) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)



## Resources

- Kubernetes [DaemonSet].
- [deploy ingress] on Kubernetes.
- Nginx [ingress] controller.
- [Linode] hosting.
- [Digital Ocean] hosting.
- [Vultr] hosting.
- Using [KUBECONFIG] for multiple configuration files.
- [systemd] help.
- [Weave Net] container networking.
- [Etcd] distributed keystore.
- [WireGuard] VPN.
- [minikube]
- [Hobby Kube] A fantastic write-up (with terraform scripts) and how I got started.

[Nodes]: https://kubernetes.io/docs/concepts/architecture/nodes/
[ingress nginx examples]: https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples
[kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[ok]: https://github.com/txn2/ok
[txn2]: https://txn2.com
[ServiceAccount]: https://kubernetes.io/docs/admin/service-accounts-admin/
[ClusterRole]: https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole
[Role]: https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole
[RoleBinding]: https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding
[ClusterRoleBinding]: https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[namespace]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[ConfigMap]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
[Pod]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[minikube]: https://kubernetes.io/docs/getting-started-guides/minikube/
[Kubernetes]: https://kubernetes.io/
[DaemonSet]: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
[Hobby Cluster]: /hobby-cluster/
[Production Hobby Cluster]: /hobby-cluster/
[deploy ingress]: https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md
[ingress]: https://github.com/kubernetes/ingress-nginx
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[Digital Ocean]: https://m.do.co/c/97b733e7eba4
[vultr]: https://www.vultr.com/?ref=7418713
[KUBECONFIG]: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
[systemd]: https://wiki.ubuntu.com/systemd
[WireGuard]: https://www.wireguard.io/
[Weave Net]: https://www.weave.works/oss/net/
[Etcd]: https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html
[Hobby Kube]: https://github.com/hobby-kube/guide