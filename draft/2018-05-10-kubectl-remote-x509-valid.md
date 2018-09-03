---
published: true
layout: post
title: Kubectl x509 Unable to Connect 
tags: kubernetes kubectl cli
featured: kubernetes cli
mast: broken
---

Just set up a brand new cluster? Changed the domain or IP of your admin node? Then you may have encountered the error
**Unable to connect to the server: x509: certificate is valid for ...**. The following is a fix for this common issue. However, there are often other reasons to rebuild your cluster cert, and it's relatively easy.

TL;DR: "I don't care about the fix I need to remote control my cluster. Security? Whats that?": 
```bash
kubectl --insecure-skip-tls-verify --context=some-context get pods
```

Let's say you want to fix the issue and not just **skip-tls-verify**. Ssh to the admin node and run the following 
(assuming Kubernetes 1.8 or greater):

```bash
# remove the certs
rm /etc/kubernetes/pki/apiserver.*

# re-create with updated --apiserver-cert-extra-sans
kubeadm alpha phase certs all --apiserver-advertise-address=0.0.0.0 --apiserver-cert-extra-sans=new.example.com

# remove the kubernetes api server container
docker rm -f `docker ps -q -f 'name=k8s_kube-apiserver*'`

# restart the kublet
systemctl restart kubelet
```

### Resources

- [systemctl] - How To Use Systemctl to Manage Systemd Services and Units
- [Kubernetes]
- [kubeadm] - Using kubeadm to Create a Cluster
- [Stack Overflow]

[systemctl]: https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units
[Kubernetes]: https://kubernetes.io/
[kubeadm]: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
[Stack Overflow]: https://stackoverflow.com/questions/46360361/invalid-x509-certificate-for-kubernetes-master?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa