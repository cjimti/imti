---
layout:     post
title:      "Kubernetes Port Forwarding for Local Development"
subtitle:   "Using kubefwd"
date:       2018-08-11
author:     "Craig Johnston"
URL: "kubernetes-port-forwarding/"
image:      "/img/post/patchbay.jpg"
twitter_image: "/img/post/patchbay_876_438.jpg?card"
tags:
- Development
- Kubernetes
- Coding
series:
- Kubernetes
---


[kubefwd] helps to enable a seamless and efficient way to develop applications and services on a local workstation. Locally develop applications that intend to interact with other services in a Kubernetes cluster. [kubefwd] allows applications with connection strings like http://elasticsearch:9200/ or tcp://db:3306 to communicate into the remote cluster. [kubefwd] can be used to reduce or eliminate the need for local environment specific connection configurations.

{{< tweet 1059519420064706579 >}}

{{< content-ad >}}

Developing services in a [Microservices] architecture presents local development challenges, especially when the service you are developing needs to interact with a mixture of other services. [Microservices], like any other applications are rarely ever self-contained and often need access to databases, authentication services, and other public or private APIs. Loosely-coupled applications still have couplings, they happen on a higher layer of the application stack and often through TCP networking.

## [kubectl port-forward][port-forward]

The [kubectl] command offers a vast array of features for working with a [Kubernetes] cluster, one of which is the [port-forward] command. Forwarding one or more ports on your local workstation to a Kubernetes service, deployment or individual pod is a simple command. The [kubectl] [port-forward] was likely developed as a debugging utility and works great for that.

In most cases, it makes sense to port forward a Kubernetes [Service]. A Kubernetes Service can listen-on and forward to one or more ports of an associated [Pod]. Services are a persistent resource, as they provide a consistent way to reach a Pod. Pods can come and go, where Services persist and find the appropriate Pod when one is available.

The following is an example of a Kubectl [port-forward] command, forwarding port 8080 on the local workstation to 8080 for the service `ok`, additionally port 8081 on the local workstation to port 80 on `ok` service, in the [Namespace] `the-project`:

```bash
kubectl port-forward service/ok 8080:8080 8081:80 -n the-project
```

Access the Service through `http://localhost:8081/` and `http://localhost:8080/`. Additional services can be port forwarded by back-grounding the command or opening new terminals and issuing more kubectl port-forward commands.

[kubectl port-forward][port-forward] is convenient for quick one-off port forward access to a Services, Deployments or directly to Pods in your cluster. Your application can use environment variables or configuration files along with scripts that set up all the required forwards to bootstrap your local app. However, I find this cumbersome. [kubectl port-forward][port-forward] is great for debugging but falls a bit short for a development utility.

{{< content-ad >}}

## [kubefwd]

[kubefwd] was developed as a command line utility to forward Kubernetes [Service]s as they appear from within a [Namespace]. Running [kubefwd] allows you to access any [Service] from your local workstation just as you would from within another [Pod] in the same Namespace on the cluster.

![kubefwd - Kubernetes port forwarding](/images/content/kubefwd-net.png)

In the following example I forward services from `the-project` namespace:

![ubefwd - example](https://raw.githubusercontent.com/txn2/kubefwd/master/kubefwd_ani.gif)

The example above issues the following command:

```bash
sudo kubefwd services -n the-project
```

**sudo** is required to allow [kubefwd] access to `/etc/hosts` on the local workstation. While [kubefwd] is running, DNS entries are temporarily placed in `/etc/hosts`, pointing all Service names found in the Namespace to the loopback network interface on the local workstation. **sudo** is also required to allow the binding of low port numbers, like port 80 on IP address assigned to the local on the workstation. If you don't have administrator access to the local workstation or don't wish to use **sudo** you can run [kubefwd] in a docker container. I go over specifics for Docker further down in this article.

After [kubefwd] begins forwarding Services from a Namespace they can be accessed directly on the local workstation. The example above illustrates using **curl** to call an HTTP Service called **ok** on port 80 followed Elasticsearch on port 9200.

Local access to a Service named `ok` listening on port 80 in `the-project` Namespace on a remote Kubernetes cluster:
```bash
curl http://ok:80
```

Local access to a Service named `elasticsearch` listening on port 9200 in `the-project` Namespace on a remote Kubernetes cluster:
```bash
curl http://elasticsearch:9200
```

[kubefwd] gives each Service forward its own IP address, allowing multiple services to use the same port just as they may in the cluster. You might have a few services responding to port 80 or 8080 or have multiple databases like `db-customer:3306` and `db-auth:3306`.

## Install [kubefwd]

### MacOs
Installing [kubefwd] on MacOs is simple with [homebrew](http://brew.sh/):

```bash
brew install txn2/tap/kubefwd
```

### Linux
Check the [kubefwd releases] section on [Github] for pre-compiled binary distributions as **.deb**, **.rpm**, **.snap** and **.tar.gz** for Linux based operating systems or Docker containers.

### Windows
[kubefwd] is not tested on Windows. If you are interested in testing and developing [kubefwd] for windows, please contact me on [twitter] [@cjimti].


## [kubefwd] in Docker

Add [kubefwd] to an existing docker container by installing it with one of the binary distributions found in the [kubefwd releases] on Github. You may also use the container [txn2/kubefwd] as the base container for another project.

The [txn2/kubefwd] is based on Alpine linux 3.7 and only contains the [kubefwd] linux binary and the `curl` utility (optional).  See the [txn2/kubefwd] source [Dockerfile] if you are curious.

[kubefwd] does not require [kubectl] to run. However [kubefwd] does require the [kubectl] configuration to connect to the cluster.

```bash
docker run --name fwd -it --rm \
    -v $HOME/.kube/config:/root/.kube/config \
    txn2/kubefwd services -n the-project
```

Test the running Docker container with its built-in curl command:

```bash
docker exec fwd curl -s http://ok
```

## Resources

[kubefwd] is an independent project not affiliated or endorsed by Kubernetes. I welcome any contributions to its development.

- [kubefwd] on [Github]
- kubectl [port-forward] command
- Setting up a [Production Hobby Cluster]
- [Kubernetes Team Access - RBAC for developers and QA]
- [A Microservices Workflow with Golang and Gitlab CI]
- [Kubernetes FaaS - Kubeless Python and Elasticsearch]

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)



[Kubernetes FaaS - Kubeless Python and Elasticsearch]:/fass-kubeless-kubernetes/
[A Microservices Workflow with Golang and Gitlab CI]:/gitlabci-golang-microservices/
[Kubernetes Team Access - RBAC for developers and QA]:/team-kubernetes-remote-access/
[Production Hobby Cluster]:/hobby-cluster/
[Dockerfile]:https://github.com/txn2/kubefwd/blob/master/Dockerfile
[txn2/kubefwd]:https://hub.docker.com/r/txn2/kubefwd/
[@cjimti]: https://twitter.com/cjimti
[twitter]: https://twitter.com/cjimti
[Github]: https://github.com/txn2/kubefwd
[kubefwd releases]:https://github.com/txn2/kubefwd/releases
[Microservices]:https://microservices.io/
[kubectl]:https://kubernetes.io/docs/reference/kubectl/overview/
[Kubernetes]:https://kubernetes.io/
[port-forward]:https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#port-forward
[kubefwd]:https://github.com/txn2/kubefwd
[Service]:https://kubernetes.io/docs/concepts/services-networking/service/
[Pod]:https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Namespace]:https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/