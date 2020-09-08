---
layout:     post
title:      "kubectl Context Multiple Clusters"
subtitle:   "Managing multiple clusters with kubectl."
date:       2018-05-15
author:     "Craig Johnston"
URL:        "kubectl-remote-context/"
image:      "/img/post/containerships.jpg"
twitter_image: "/img/post/containerships_876_438.jpg"
tags:
- Kubernetes
- kubectl
series:
- Kubernetes
---

I use a few Kubernetes clusters on a daily basis, and I use [kubectl] to access and configure them from my workstation. There are dozens of ways to configure [kubectl] however I find the following method the easiest for me to manage and not make a mess.

I also set up test clusters from time-to-time, and so keeping my configs organized is, so I don't confuse myself or make a mess.

For this post, I'll talk about four clusters and how I have them organized. The following is a list of the clusters I am managing:

- **minikube**: running on my local workstation
- **work-dev**:  a development cluster for my professional projects
- **work-prod**: a large production cluster I host client projects and services on
- **txn2-phc**: is a [Production Hobby Cluster] I use for experiments in infrastructure and microservices

{{< content-ad >}}

[kubectl] looks at an environment variable called **KUBECONFIG** to hold a colon-separated list of paths to configuration files. [kubectl] configurations can all be confined in one file. However, if multiple files are specified, [kubectl] combines them internally. I prefer the separate config file method since it's a little bit more scalable for my brain.

Each Kubernetes cluster has an admin config file generated when installed. The Kubernetes config is found on the master node typically under:

 `/etc/kubernetes/admin.conf`

[Install kubectl] on your local workstation. If the install went correctly, you should have a `.kube` folder just off your home directory. The `/home/USER/.kube/` holds all of your config files.

`/home/USER/.kube/`

I populate this directory using the `scp` (secure copy) command on my local workstation and download each config into `/home/USER/.kube/`. Of course, you need to replace **USER** with your username. You can also use the tilde character `~` to denote your home directory in most command shells, and I use that here:

```bash
# download the Kubernetes admin config for work dev
scp root@WORK_DEV_SERVER:/etc/kubernetes/admin.conf ~/.kube/config-work-dev`

# download the Kubernetes admin config for work production
scp root@WORK_PROD_SERVER:/etc/kubernetes/admin.conf ~/.kube/config-work-prod`

# download the Kubernetes admin config for txn2 production hobby
scp root@PHC_SERVER:/etc/kubernetes/admin.conf ~/.kube/config-txn2-phc`
```

The above `scp` method is one way to get the files; you can use whatever method you like. The idea is that we need each one in our `.kube` directory and named appropriately. I like to name them `config-`**context**, where context is the name of the configuration context I'll be giving them in the next step.

Each configuration file has three parts I'll be concerned with:

 - clusters
 - users
 - contexts (associates users with clusters)

The **clusters** key in each config hold definitions of one or more clusters. The **name:** of the cluster is likely to be generic and may need adjustment to something more specific. In my configuration file **config-work-dev** I change the **name:** of the cluster to **work-dev-cluster**. The **server:** value is also wrong since it's an internal IP (this will not always be the case), ensure the **server:** points to an IP address accessible from your local workstation and should look something like `n.n.n.n:6443`.

```bash
...
- cluster:
    server: https://1.1.1.1:6443
  name: work-dev-cluster
...
```

Under the **user:** section change the name of the users to match the cluster context, change it to something like:

```bash
users:
- name: work-dev-admin
...
```

Change the **context:** section to properly tie the **user:** and **cluster:** together:

```bash
contexts:
- context:
    cluster: work-dev-cluster
    user: work-dev-admin
  name: work-dev
```

Update each of the config files, in my case

- ~/.kube/config-**work-dev**
- ~/.kube/config-**work-prod**
- ~/.kube/config-**txn2-phc**

Next, we need to set the **KUBECONFIG** environment variable with them. I use my `.bash_profile` script but you can use whatever script your shell uses to set up. Add paths similar to:

```bash
export KUBECONFIG=$HOME/.kube/config-work-dev:$HOME/.kube/config-work-prod:$HOME/.kube/txn2-phc
```

You may need to open a fresh terminal to use the newly configured **KUBECONFIG** environment variable. Check the paths:

```bash
echo $KUBECONFIG

/Users/ME/.kube/config-work-dev:/Users/ME/.kube/config-work-prod:/Users/ME/.kube/txn2-phc
```

You are now able to run some commands to manage your [kubectl] context:

```bash
# get the current context
kubectl config current-context

# use a different context
kubectl config use-context work-dev

```

Now you can make Kubernetes clusters all over the place and have a single `kubectl` on your local workstation to manage them all.

### **Unable to connect to the server: x509: certificate is valid for ...**.

If you changed the cluster server to a hostname (like lax2.example.com) and did not use that name when setting up the cluster with `kubeadm`, then you will need to rebuild the cert on the master. This is easy to do. Check out my article [Kubectl x509 Unable to Connect] for a few simple steps. Otherwise, just use the public IP address of the master node.


## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

---

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance [Hobby Cluster]s) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)


## Resources

- [install kubectl]
- [Production Hobby Cluster] how-to article.
- [vultr] for cheap instance hosting for [Production Hobby Cluster]

[Production Hobby Cluster]: /hobby-cluster/
[install kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[Hobby Cluster]: /hobby-cluster/
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[vultr]: https://www.vultr.com/?ref=7418713
[kubectl]: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[Kubectl x509 Unable to Connect]: /kubectl-remote-x509-valid/