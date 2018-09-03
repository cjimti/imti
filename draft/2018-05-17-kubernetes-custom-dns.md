---
published: true
layout: post
title: Kubernetes Custom Upstream DNS
tags: kubernetes kubectl helm cli dns phc.txn2.net
featured: kubernetes cli
mast: cardindex
---

Customize the [Upstream Nameservers] used by [kube-dns] by [Pods] when looking up external hostnames from within a Kubernetes cluster. I found that adding custom [Upstream Nameservers] to my [kube-dns] solved many issues encountered in in the past with external hostname resolution on individual [Pods].

If you want to experiment on a production-like cluster, I suggest reading my article "[Production Hobby Cluster]" for a guide on setting up a fun, cheap-yet-robust experimental cluster.

The following configuration sets the [Upstream Nameservers] to use Google's [DNS servers] 8.8.8.8 and 8.8.4.4.

<script src="https://gist.github.com/cjimti/3a500e8efffa1fcaedda8b844c7d6aa7.js"></script>

You can apply the above configuration with the following command:

```bash
kubectl apply -f https://gist.githubusercontent.com/cjimti/3a500e8efffa1fcaedda8b844c7d6aa7/raw/ae7329733452dda8cce573fb78f33c22c65cb3fa/00-kube-dns-upstream.yml
```

If you are having trouble with DNS on your Kubernetes cluster, you may want to read the official documentation on [Debugging DNS Resolution].

---

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance [Hobby Cluster]s) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)

[Debugging DNS Resolution]: https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
[Production Hobby Cluster]: https://mk.imti.co/hobby-cluster/
[Pods]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Upstream Nameservers]: https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/
[kube-dns]: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
[Hobby Cluster]: https://mk.imti.co/hobby-cluster/
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[vultr]: https://www.vultr.com/?ref=7418713
[DNS servers]: https://developers.google.com/speed/public-dns/