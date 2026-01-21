---
layout:     post
title:      "Kubernetes Remote Control"
subtitle:   "Using kubectl to Control a Remote Kubernetes Cluster"
date:       2018-03-24
author:     "Craig Johnston"
URL:        "kubectl-remote/"
aliases:
  - "/kubctl-remote/"
image:      "/img/post/containercrain.jpg"
twitter_image: "/img/post/containercrain_876_438.jpg"
tags:
    - Kubernetes
    - kubectl
series:
    - Kubernetes
    - kubectl
---

I use [Minikube] to run a local [Kubernetes] single node cluster (cluster?). However, I also work with a custom production cluster for work. This cluster consists of development and production nodes. I often need to switch between working on my local [Minikube] and the online [Kubernetes] cluster.

<!--more-->

TIP: Visit the [kubectl Cheat Sheet] often.

{{< content-ad >}}

The default configuration `kubectl` is stored in `~/.kube/config` and
if you have [Minikube] installed, it added the context **minikube** to your config.

With `kubectl` you can specify a config to use with the command flag `--kubeconfig`.

Below I am just pointing to default config. However, you can replace that with a different config to test.

```bash
kubectl --kubeconfig=/Users/enochroot/.kube/config config view
```

In addition to specifying a configuration file to use, `kubectl` configs also contain **contexts**. Each configuration file can have multiple contexts.


## Current Context

A context is a combination of **cluster**, **namespace** and **user**.

View the current context:
~~~ bash
kubectl config view
~~~
You should now see the output the default configuration file.

<script src="https://gist.github.com/cjimti/907264f486f2f4118b33969ce184e20d.js"></script>

You can see we have only one context by default on a workstation that just installed [Minikube]. You can also see the key `current-context:` is set to  `minikube`.

Check the current config context:

```bash
kubectl config current-context
```

Output:
```bash
minikube
```

## Add a Cluster

Get the public certificate from your cluster or use `--insecure-skip-tls-verify`:

```bash
kubectl config set-cluster example --server https://example.com:6443 --certificate-authority=example.ca
```

Output
```bash
Cluster "example" set.
```

## Add a User

Users in the configuration can use a path to a certificate `--client-certificate` or use the certificate data directly `--client-certificate-data`

```bash
kubectl config set-credentials example \
    --client-certificate=/some/path/example.crt \
    --client-key=/some/path/example.key
```

## Add a Context

Add a context to tie a user and cluster together.

```bash
kubectl config set-context deasil --cluster=example \
    --namespace=default --user=example-admin
```

## Change Current Context

At this point you can change your current context from `minikube` to example:

```bash
kubectl config use-context example
```

Output:
```bash
example
```

Of course, `kubectl config use-context minikube` will put you back
to managing your local [Minikube].


## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

{{< content-ad >}}

## Resources

- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
- [stackoverflow]
- [kubectl Cheat Sheet]

[kubectl Cheat Sheet]: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[Helm]: https://helm.sh/
[Kubernetes]: https://kubernetes.io/
[Minikube]: https://kubernetes.io/docs/getting-started-guides/minikube/
[stackoverflow]: https://stackoverflow.com/questions/36306904/configure-kubectl-command-to-access-remote-kubernetes-cluster-on-azure