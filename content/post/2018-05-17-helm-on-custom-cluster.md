---
layout:     post
title:      "Helm on Custom Kubernetes"
subtitle:   "Kubernetes package management."
date:       2018-05-17
author:     "Craig Johnston"
URL:        "helm-on-custom-cluster/"
image:      "/img/post/helm.jpg"
twitter_image: "/img/post/helm_876_438.jpg"
tags:
- Kubernetes
- helm
series:
- Kubernetes
---

[Helm] is the official package manager for [Kubernetes]. If you are looking to start using [Helm] or want to test its capabilities, I suggest you set up a [Production Hobby Cluster]. This article is a continuation of the [Production Hobby Cluster] configuration but should be entirely useful on its own.

> From https://github.com/kubernetes/helm
> - Helm has two parts: a client (helm) and a server (tiller)
> - Tiller runs inside of your Kubernetes cluster and manages releases (installations) of your charts.
>  - Helm runs on your laptop, CI/CD, or wherever you want it to run.
>  - Charts are Helm packages that contain at least two things:
>  - A description of the package (Chart.yaml)
>  - One or more templates, which contain Kubernetes manifest files
>  - Charts can be stored on disk, or fetched from remote chart repositories (like Debian or RedHat packages)

Start with installing [Helm] on your local workstation. Read the [Helm installation instructions] or merely follow along below.

```bash
# on MacOS using homebrew (http://brew.sh)
brew install kubernetes-helm

# on windows using https://chocolatey.org/
choco install kubernetes-helm
```

Since our [Production Hobby Cluster] uses [RBAC] Roles, we start by adding a [ServiceAccount] called **tiller**. Tiller is Kubernetes service that manages [Helm] installs on the cluster.

The following configuration creates a [ServiceAccount] named **tiller** and a [ClusterRoleBinding] between the new **tiller** account and the **cluster-admin** role. Of course, you can define your own [Role] and permissions, however, the **cluster-admin** role has admin access, and that is what we want for a [Production Hobby Cluster]. Permissions can always become more restrictive in the future should our hobby become more sophisticated.

<script src="https://gist.github.com/cjimti/9fab60c0b21a97cbe15688f5e28d940f.js"></script>

You can apply the configuration with the following command:

```bash
kubectl create -f https://gist.githubusercontent.com/cjimti/9fab60c0b21a97cbe15688f5e28d940f/raw/29cbeff70bc528e5212ebc3f63e08fb5a24d5ecd/00-tiller-rbac.yml
```

Next initialize [Helm] while specifying the [ServiceAccount] to use. Use the new **tiller**  [ServiceAccount] we setup above.

```bash
helm init --service-account tiller
```

To see what [Helm] just installed on your cluster run:

```bash
kubectl get all -l app=helm -n kube-system
```

As this point you can see a [Deployment], a [ReplicaSet], a [Pod] and a [Service] named **tiller-deploy** in the **kube-system** namespace.


---

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance [Hobby Cluster]s) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)



## Resources

- [Linode] hosting.
- [Digital Ocean] hosting.
- [Vultr] hosting.

[ReplicaSet]: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[RBAC]: https://kubernetes.io/docs/admin/authorization/rbac/
[Helm installation instructions]: https://github.com/kubernetes/helm/blob/master/docs/install.md
[Helm]: https://helm.sh/
[ServiceAccount]: https://kubernetes.io/docs/admin/service-accounts-admin/
[Role]: https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole
[ClusterRoleBinding]: https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[Pod]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[Kubernetes]: https://kubernetes.io/
[Hobby Cluster]: https://mk.imti.co/hobby-cluster/
[Production Hobby Cluster]: https://mk.imti.co/hobby-cluster/
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[Digital Ocean]: https://m.do.co/c/97b733e7eba4
[vultr]: https://www.vultr.com/?ref=7418713
