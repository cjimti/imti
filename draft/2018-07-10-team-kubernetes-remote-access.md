---
published: true
layout: post
title: Kubernetes Team Access - RBAC for developers and QA
tags: kubernetes
featured: kubernetes
mast: team
---

RBAC (Role Based Access Control) allows our Kubernetes clusters to provide the development team better visibility and access into the development, staging and production environments than it has have ever had in the past. Developers using the command line tool **[kubectl]**, can explore the network topology of running [microservices], tail live server logs, proxy local ports directly to services or even execute shells into running pods.

[Kubernetes and GitlabCI] are the central components of our DevOps toolchain and have increased our productivity by many multiples over the traditional approaches of the past.

If you don't already have a Kubernetes cluster up and running, then I highly suggest you read my article [Production Hobby Cluster] to get you up and running in a custom, vendor-neutral production capable cluster.

> TLDR: If you are reading this article because you received a **token** and the URL of a cluster from your Kubernetes administrator, you can skip ahead to the section [Accessing a Remote Kubernetes Cluster].

**Quick Reference:**

* Do not remove this line (for toc on a rendered blog)
{:toc}

## Our Clusters (Overview)

Development and staging environments share a cluster across many clients and projects. On the production front, more extensive projects and clients get a dedicated cluster, and smaller projects might share a cluster.

We use Kubernetes [namespaces] to separate clients. All of our security revolves around [namespaces], and when [RBAC] is set up correctly, a context in which access granted to a developer can only operate and view within the assigned namespace.

We grant developers read-level access to one common developer account per [namespace] on the development cluster. We tighten access to some resources on production.

We create a separate deployment account for our continuous integration/deployment solution, see my article, [A Microservices Workflow with Golang and Gitlab CI] to get a high-level view of our toolchain and how it integrates cleanly with Kubernetes [RBAC] security model.

## Cluster Setup

These cluster setup steps assume you are a cluster administrator if you are only looking to set up [kubectl] access on your local workstation to an existing cluster skip ahead to the section: [Accessing a Remote Kubernetes Cluster], otherwise I suggestion that you set up a [Production Hobby Cluster] to help you follow along.

### Example Microservice

You can skip the following steps and head directly to [Setup Remote Access] if you already have a [namespace] with projects you plan to provide remote access [kubectl].

To demonstrate team access control we need some pods running in the namespace `the-project`. The example below uses a pre-built Docker container designed specifically for testing called [txn2/ok]. If you are curious about how to automate subsequent deployments using the free and open source [GitlabCI], check out [A Microservices Workflow with Golang and Gitlab CI].

We don't automate the initial configuration, and so the following steps are part of the setup stage of any new project. It is easy to automate this process with the Kubernetes package manager [Helm], but that would be overkill for most of our projects and abstract away some welcome verbosity. [Helm] is a great tool but better-used adjacent to our initial development process. In fact, we use [Helm] to create charts from our initial development configurations, but that is outside the scope of this article.

#### Namespace

I use the term `the-project` as a fictional [namespace] for the examples going forward. If you want to follow along, use the following configuration to create the example [namespace].

`00-namespace.yml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: the-project
  labels:
    client: mk.imti.co
    env: dev
```

The filename is not important. I use a numeric value to represent a suggested order in which to apply the configuration, followed by the `kind` of the kubernetes object to create. However, this is not a rigid rule across all projects and only the [namespace[

The `labels` section is optional and only used to give additional sections capabilities to command-line and automated tools.

Create the [namespace] kubernetes object:
```bash
kubectl create -f 00-namespace.yml
```

#### Deployment

After adding the `the-project` [namespace] above, create a Kubernetes [Deployment] in `the-project` to manage [pods] running [txn2/ok] Docker containers.

`10-deployment-ok.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ok
  namespace: the-project
  labels:
    app: ok
    client: mk.imti.co
    env: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ok
  template:
    metadata:
      namespace: the-project
      labels:
        app: ok
        client: mk.imti.co
        env: dev
    spec:
      containers:
        - name: ok
          image: txn2/ok
          imagePullPolicy: Always
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SERVICE_ACCOUNT
              valueFrom:
                fieldRef:
                  fieldPath: spec.serviceAccountName
          ports:
            - name: ok-port
              containerPort: 8080
```

Create the Kubernetes [Deployment] object:
```bash
kubectl create -f 10-deployment-ok.yml
```
#### Service

Kubernetes [Deployment]s manage [Pods]. Consider [Pods] ephemeral, being moved from one node to another, destroyed or re-created at any time. [Service]s are persistent and give us a point to attach our network [ingress]. If you don't already have ingress setup, you might want to read my article [Ingress on Custom Kubernetes] to get started. [Ingress] needs a [service] to attach to; however you don't need ingress to set up a service.

`50-service-ok.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ok
  namespace: the-project
  labels:
    app: ok
    client: mk.imti.co
    env: dev
spec:
  selector:
    app: ok
  ports:
    - protocol: "TCP"
      port: 8080
      targetPort: 8080
  type: ClusterIP
```

Create the Kubernetes [Service] object:
```bash
kubectl create -f 50-service-ok.yml
```
#### Ingress

Setting up [ingress] for the [txn2/ok] service for the sake of completeness. We will configure [ingress] to send HTTP requests for the domain [ok.d4ldev.txn2.com](http://ok.d4ldev.txn2.com/) to the [txn2/ok] service running in `the-project` [namespace].

`80-ingress-ok.yml`:
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ok
  namespace: the-project
  labels:
    app: ok
    client: mk.imti.co
    env: dev
spec:
  rules:
  - host: ok.d4ldev.txn2.com
    http:
      paths:
      - backend:
          serviceName: ok
          servicePort: 8080
        path: /
```

Create the [ingress]:
```bash
kubectl create -f 80-ingress-ok.yml
```

Adding TLS support is easy but out the scope of this article. If you are interested in setting up free, automated TLS certificate using [Let's Encrypt] on Kubernetes, check out my article: [Let's Encrypt, Kubernetes]. Setting up [Let's Encrypt, Kubernetes] should only have to be done once and take only about twenty minutes.

We now have a fully functional test API service answering at [http://ok.d4ldev.txn2.com/](http://ok.d4ldev.txn2.com/). In the next few steps, we create Kubernetes [RBAC] tokens for deployment and ready-only developer access.

### Setup Remote Access

If you skipped setting up the [Example Microservice] this example limits access to the namespace `the-project` exclusively, you could do the same with the `default` [namespace] by simply not providing a `namespace` key in the configuration or setting it to `default`.

#### ServiceAccount

Namespaces are the principal delimiter for our security model. We create deployer and developer [ServiceAccount] for each [namespace], along with [Role] and [RoleBinding] objects used by them. **Deployer** has write access and used for a [kubectl] executed from a Docker container operating GitlabCI [runner]. **Developer** has read access to the namespace.

Use [kubectl] to create a [ServiceAccount]; this will not only configure the ServiceAccount object but also generate the Kubernetes [Secret] containing a **token** used to setup [kubectl] with remote access.

```bash
# create the deployer ServiceAccount
kubectl create serviceaccount sa-deployer -n the-project

# create the developer ServiceAccount
kubectl create serviceaccount sa-developer -n the-project
```

You should see three service accounts, default, sa-deployer and sa-developer. Kubernetes automatically created the default ServiceAccount when we created the namespace.

```bash
kubectl get serviceaccounts -n the-project

NAME           SECRETS   AGE
default        1         30m
sa-deployer    1         3m
sa-developer   1         2m
```

You now have three secrets, assuming this is the new `the-project` namespace.

```bash
kubectl get secrets -n the-project

NAME                       TYPE                                  DATA      AGE
default-token-8t2z6        kubernetes.io/service-account-token   3         30m
sa-deployer-token-qxfsq    kubernetes.io/service-account-token   3         3m
sa-developer-token-pg7m7   kubernetes.io/service-account-token   3         3m
```

You need the tokens generated for `sa-deployer-token-qxfsq` and `sa-developer-token-pg7m7`, of course, your secrets end in different random characters.

```bash
kubectl describe secret sa-deployer-token-qxfsq -n the-project
Name:         sa-deployer-token-qxfsq
Namespace:    the-project
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=sa-deployer
              kubernetes.io/service-account.uid=c2bb12cc-84b5-11e8-9c96-00163ec25389

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  11 bytes
token:      eyYhbfEf7XaMa...REDACTED...
```

In the result above I truncated the token for security and brevity, the unedited token is much longer. Copy this token someplace safe as it is needed later; however you can always fetch it again with `kubectl describe secret`. Retrieve the tokens from sa-deployer-token-... and sa-developer-token-...

#### Role and RoleBinding

Next, we create four Kubernetes objects at one time, two [Role]s and two [RoleBinding][Role]s. One Role and RoleBinding set for **deployer** and one set for **developer**.

`90-RBAC.yml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  namespace: the-project
  name: deployer
rules:
- apiGroups: ["apps","extensions"]
  resources: ["deployments","configmaps","pods","secrets","ingresses"]
  verbs: ["create","get","delete","list","update","edit","watch","exec","patch"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  namespace: the-project
  name: developer
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get","describe","list","watch","exec"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer
  namespace: the-project
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  namespace: the-project
  name: sa-deployer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer
  namespace: the-project
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  namespace: the-project
  name: sa-developer

```

If you want to give your team even more access, you can enable the ability to port-forward a service or pod directly to their local workstation. Add the following to the end of the **developer** role.

```yaml
- apiGroups:
  - '*'
  resources:
  - 'pods/exec'
  - 'pods/portforward'
  - 'services/portforward'
  verbs:
  - create
```

Example `kubectl port-forward` to an `elasticsearch` service running in `the-project` namespace:
```bash
kubectl port-forward svc/elasticsearch 9200:9200 -n the-project
```

Create the new [Role]s and the RoleBindings that connect them to the ServiceAccounts [created with kubectl a bit earlier](#serviceaccount).

Create the [Role]s and RoleBindings:
```bash
kubectl create -f 90-RBAC.yml
```

## Accessing a Remote Kubernetes Cluster

`kubectl` is a command-line tool for interacting with Kubernetes. If you work on MacOs and use [homebrew], issue the following command:

```bash
brew install kubernetes-cli
```

Once installed you have the command `kubectl`. If you are on another platform, you need to follow the official documentation, [Install and Set Up kubectl].

Configuring remote access requires a **token**. If you followed along with the [Example Microservice] or [Setup Remote Access] for an existing Kubernetes [namespace] you find the **token** by running `kubectl describe` on the [Secret] associated an appropriate ServiceAccount.

You also need the IP address of a server running Kubernetes, and the ability to communicate to that IP. Some networks require remote users to first connect to a VPN.

Next, you create a **context**. A `kubectl` **context** is an association between a user and a cluster. Start with setting up the user and cluster in the steps below.

### Add a Cluster to `kubectl`

Give your cluster a descriptive name; this cluster configuration is available for use in multiple contexts, so it's best to name it after it's purpose. In this fictional example world the IP 1.1.1.1 is a development cluster, so **dev** is a pretty good name.

```bash
kubectl config set-cluster dev --server=https://1.1.1.1:6443 --insecure-skip-tls-verify=true
```

### Add User (credentials) to `kubectl`

The user configuration holds the **token** and therefore should have a name descriptive of the access provided by the token. In the case of instructions above to [Setup Remote Access], this token is for a namespace on dev called `the-project` so a good descriptive name would be **the-project-dev***. In the example below replace **THETOKEN** with the one retrieved in the example above or received from your administrator.

```bash
kubectl config set-credentials the-project-dev --token=THETOKEN
```

### Add a Context to `kubectl`

Finally, you tie the new **dev** cluster with the new **the-project-dev** user (credentials.) In the case of our example, the token is joined to a [namespace], specifically `the-project`, so it makes sense here to use the **--namespace** flag to tell `kubectl` to always use that namespace with this new context. However, providing a namespace is optional.

Name the context with the cluster and access it provides. I find it useful to give it the same name as the user (credentials.)

```bash
kubectl config set-context the-project-dev --cluster=dev --user=the-project-dev --namespace the-project
```

To use the new context, issue the command:
```bash
kubectl config use-context the-project-dev
```

Get a list of all your configured contexts along with an indicator of the current context you are in:

```bash
kubectl config get-contexts
```

You now have access to **the-project** namespace on the **dev** cluster. Check out the [kubectl Cheat Sheet] for a quick list of useful commands.



## Resources

- [kubectl] is the essential Kubernetes command line administration utility.
- [kubectl Cheat Sheet]
- [RBAC] on Kubernetes for role-based access control
- Setup a [Production Hobby Cluster], a production capable kubernetes on the cheap.
- [A Microservices Workflow with Golang and Gitlab CI]
- [GitlabCI] for Continuous Integration & Deployment

[kubectl Cheat Sheet]:https://kubernetes.io/docs/reference/kubectl/cheatsheet/#viewing-finding-resources
[Helm]: https://helm.sh/
[Developer Setup]: #developer-setup
[Role]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings
[RBAC]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
[namespace]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[namespaces]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[Kubernetes and GitlabCI]: https://mk.imti.co/gitlabci-golang-microservices/
[microservices]: https://mk.imti.co/microservices/
[kubectl]: https://kubernetes.io/docs/reference/kubectl/kubectl/
[Production Hobby Cluster]:https://mk.imti.co/hobby-cluster/
[A Microservices Workflow with Golang and Gitlab CI]:https://mk.imti.co/gitlabci-golang-microservices/
[txn2/ok]: https://github.com/txn2/ok
[GitlabCI]:https://about.gitlab.com/features/gitlab-ci-cd/
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[pods]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Service]:https://kubernetes.io/docs/concepts/services-networking/service/
[ingress]:https://kubernetes.io/docs/concepts/services-networking/ingress/
[Ingress on Custom Kubernetes]:https://mk.imti.co/web-cluster-ingress/
[Let's Encrypt]:https://letsencrypt.org/
[Let's Encrypt, Kubernetes]:https://mk.imti.co/lets-encrypt-kubernetes/
[ServiceAccount]:https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/
[RoleBinding]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings
[Example Microservice]:#example-microservice
[Setup Remote Access]:#setup-remote-access
[runner]:https://docs.gitlab.com/runner/
[Secret]:https://kubernetes.io/docs/concepts/configuration/secret/
[homebrew]:https://brew.sh/
[Install and Set Up kubectl]:https://kubernetes.io/docs/tasks/tools/install-kubectl/
[Accessing a Remote Kubernetes Cluster]:#accessing-a-remote-kubernetes-cluster