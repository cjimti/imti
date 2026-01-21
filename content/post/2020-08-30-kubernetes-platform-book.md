---
draft:    false
layout:   post
title:    "Advanced Platform Development with Kubernetes"
subtitle: "Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning"
date:     2020-08-30
author:   "Craig Johnston"
URL:      "kubernetes-platform-book/"
image:    "/img/post/apk8s.jpg"
twitter_image:  "/img/post/apk8sdiag_876_438-3.jpg"
tags:
- Kubernetes
- Data
- Machine Learning
- Blockchain
- IoT
- Data Science
series:
- Kubernetes
---

I've been distracted for over a year now, writing a (~500 page) end-to-end tutorial on constructing data-centric platforms with Kubernetes. The book is titled "[Advanced Platform Development with Kubernetes: Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning]"

<!--more-->

A little more than a year ago, Apress reached out and asked if I would write a book on Kubernetes for them, mirroring the wide range of projects I develop (and write about) for my clients. I have been building data-centric platforms for almost twenty years, spanning everything from my early days on the aggregation of massive volumes of international log files for Disney to fan-driven location data for Nine Inch Nails. And in the last decade, retailers with point-of-sale, logistics, and inventory systems, marketers leveraging social media metrics, fleet operators with demanding telematics platforms, and manufacturers with advanced IIoT (industrial internet of things) networks.

{{< content-ad >}}

Furthermore, the clients behind these verticals have begun looking for an edge, often found beyond standard PaaS offerings available today. Yet these clients from established organizations and age-old industries have little tolerance for the risk associated with a multi-year development on technologies whose value is speculative. Will blockchain revolutionize logistics and finance? Will machine learning produce artificial intelligence capable of replacing legacy decisions making systems? The safe bet is to wait. If there is gold in any of these mountains the hyper clouds will find it, and they will happily sell it to everyone, by the hour, megabyte, or IOPS.

Not every organization should be developing custom software, let alone advanced data platforms. However, the barrier to entry is lowering every day. I have been building platforms for twenty years, and never has a single technology increased productivity in this practice more than Kubernetes has in the last five. Kubernetes is truly a platform for building platforms, capable of harnessing the wide breadth of new technologies released into the open-source landscape almost daily.

On October 28, 2018, IBM announced a $34 billion deal to buy Red Hat, the company behind Red Hat Enterprise Linux (RHEL) and, more recently, Red Hat OpenShift, an enterprise Kubernetes-based application platform. What we see is $34 billion of evidence that Cloud-native and open source technologies centered on the Linux ecosystem and empowered by Kubernetes is leading disruption in enterprise software application development. IBM sells platforms, and yet it looks to capitalize on the value of a system tailored to platform development. IBM is speculating that the next trend in PaaS offerings is itself a platform for developing platforms. An organization does not spend $34 billion to on-board brand and technology without a market. Who is demanding the capabilities of OpenShift/Kubernetes? Systems, solutions, and software architects, full-stack developers, programmers, integrators, and DevOps engineers. These are the people and roles responsible for the technology that powers the business logic.

I did not want to write a book on administering Kubernetes or how it works (although you'll likely learn this along the way). There are a ton of excellent books and tutorials on the matter. I wanted to write about what gets the lion's share of hits on my blog: "How to run X on Kubernetes." I don't know why you want to run a Blockchain network on Kubernetes; I have my reasons for doing so. I don't know why you need to interconnect [Kafka], [NiFi], [MinIO], [Hive], [Keycloak], [Cassandra], [MySQL], [Zookeeper], [Mosquitto], [Elasticsearch], [Logstash], [Kibana], [Presto], [OpenFaaS], [Ethereum], [Jupyter], [MLflow], and [Seldon Core]. You don't need Kubernetes to run these excellent applications. You don't need Kubernetes to run containers networked across the globe on various cloud providers communicating over secure VPNs, on-premises, on a mix of bare metal servers and virtual machines. I know that I, and the many roles mentioned above want to, (evidenced by Kubernetes enormous success) and it's likely because they are building sophisticated and modern platforms and see the value Kubernetes brings to this endeavor.

"[Advanced Platform Development with Kubernetes: Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning]" is a 500 page tutorial on the work I do daily. The examples are scaled-down yet real and fully functional. If you are an entrepreneur with dreams of building your own AWS or Azure or if constructing enterprise-capable data-centric platforms is what you do for work or hobby, my book is looking to inspire you and give you traction where I have found it myself.

## Weekend Projects

**All source code and configuration manifests are open source and available online at**: https://github.com/apk8s/book-source

"[Advanced Platform Development with Kubernetes: Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning]" will give you an equivalent of ten weekend projects, covering all the technology mentioned above and more, broken down as follows:
 
- Week 1: DevOps Infrastructure
- Week 2: Development Environment
- Week 3: In-Platform CI/CD
- Week 4: Pipeline
- Week 5: Indexing and Analytics
- Week 6: Data Lakes
- Week 7: Data Warehouses
- Week 8: Routing and Transformation
- Week 9: Platforming Blockchain
- Week 10: Platforming AIML

## Custom Kubernetes

Quite a few books and how-tos specialize in AKS, EKS, and GKE.  "[Advanced Platform Development with Kubernetes: Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning]" focuses on building **Custom Kubernetes** clusters and illustrates this by using generic (and cheap) compute instances (VMs) offered by [Vultr], [Digital Ocean], [Linode], [Hetzner] and [Scaleway].

## Technology

"[Advanced Platform Development with Kubernetes: Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning]" covers the following technology:

- [Chapter 2: **DevOps Infrastructure**] (source)
  - [GitLab]
  - [k3s]
  - [Cert Manager]
- [Chapter 3: **Development Environment**] (source)
  - [WireGuard]
  - [Docker]
  - [Kubernetes] ([kubelet], [kubeadm], [kubectl])
  - [Ingress Nginx]
  - [Rook Ceph]
    - [Ceph Block Storage]
    - [Ceph Filesystem]
  - Monitoring ([kube-prometheus])
- [Chapter 4: **In-Platform CI/CD**] (source)
  - [JupyterLab]
  - [GitLab CI]
  - [Kaniko]
- [Chapter 5: **Pipeline**] (source)
  - [Apache Zookeeper]
  - [Apache Kafka]
  - [Mosquitto] (MQTT)
- [Chapter 6: **Indexing and Analytics**] (source)
  - [Elasticsearch]
  - [Logstash]
  - [Kibana]
  - [Keycloak] (IAM)
  - [JupyterHub]
  - [Kubernetes API]
- [Chapter 7: **Data Lakes**] (source)
  - [MinIO]
  - [Golang]
- [Chapter 8: **Data Warehouses**] (source)
  - [MySQL]
  - [Apache Cassandra]
  - [Apache Hive]
  - [Presto]
- [Chapter 9: **Routing and Transformation**] (source)
  - [OpenFaaS]
  - [Apache NiFi]
- [Chapter 10: **Platforming Blockchain**] (source)
  - [Ethereum]
    - [Geth]
  - [Ethstats]
- [Chapter 11: **Platforming AIML**] (source)
  - [Kilo] (Automated [WireGuard])
  - [Nvidia] / [CUDA]
  - [Bash] / Shell Scripting
  - [Raspberry Pi]
  - [CronJob] with [Python]
  - [MLflow]
  - [Seldon Core]

{{< content-ad >}}

---

[Chapter 2: **DevOps Infrastructure**]: https://github.com/apk8s/book-source/tree/master/chapter-02
[Chapter 3: **Development Environment**]: https://github.com/apk8s/book-source/tree/master/chapter-03
[Chapter 4: **In-Platform CI/CD**]: https://github.com/apk8s/book-source/tree/master/chapter-04
[Chapter 5: **Pipeline**]: https://github.com/apk8s/book-source/tree/master/chapter-05
[Chapter 6: **Indexing and Analytics**]: https://github.com/apk8s/book-source/tree/master/chapter-06
[Chapter 7: **Data Lakes**]: https://github.com/apk8s/book-source/tree/master/chapter-07
[Chapter 8: **Data Warehouses**]: https://github.com/apk8s/book-source/tree/master/chapter-08
[Chapter 9: **Routing and Transformation**]: https://github.com/apk8s/book-source/tree/master/chapter-09
[Chapter 10: **Platforming Blockchain**]: https://github.com/apk8s/book-source/tree/master/chapter-10
[Chapter 11: **Platforming AIML**]: https://github.com/apk8s/book-source/tree/master/chapter-11

[Advanced Platform Development with Kubernetes: Enabling Data Management, the Internet of Things, Blockchain, and Machine Learning]: https://amzn.to/3hAZUvx
[Kafka]: https://kafka.apache.org/
[Apache Kafka]: https://kafka.apache.org/
[Apache NiFi]: https://nifi.apache.org/
[NiFi]: https://nifi.apache.org/
[MinIO]: https://min.io/
[Apache Hive]: https://hive.apache.org/
[Hive]: https://hive.apache.org/
[Keycloak]: https://www.keycloak.org/
[Cassandra]: https://cassandra.apache.org/
[Apache Cassandra]: https://cassandra.apache.org/
[MySQL]: https://www.mysql.com/
[Zookeeper]: https://zookeeper.apache.org/
[Apache Zookeeper]: https://zookeeper.apache.org/
[Mosquitto]: https://mosquitto.org/
[Elasticsearch]: https://www.elastic.co/elasticsearch/
[Logstash]: https://www.elastic.co/logstash
[Kibana]: https://www.elastic.co/kibana
[Presto]: https://prestodb.io/
[OpenFaaS]: https://www.openfaas.com/
[Ethereum]: https://ethereum.org/en/
[MLflow]: https://mlflow.org/
[Seldon Core]: https://www.seldon.io/tech/products/core/
[Jupyter]: https://jupyter.org/
[Vultr]: https://www.vultr.com/?ref=7418713
[Digital Ocean]: https://m.do.co/c/97b733e7eba4
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[Hetzner]: https://hetzner.cloud/?ref=MKrfJcJkRliR
[Scaleway]: https://www.scaleway.com/en/
[GitLab]: https://about.gitlab.com/
[k3s]: https://k3s.io/
[Cert Manager]: https://cert-manager.io/
[WireGuard]: https://www.wireguard.com/
[Docker]: https://www.docker.com/
[Kubernetes]: https://kubernetes.io/
[kubelet]: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
[kubeadm]: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
[kubectl]: https://kubernetes.io/docs/reference/kubectl/overview/
[Ingress Nginx]: https://github.com/kubernetes/ingress-nginx
[Rook Ceph]: https://rook.io/docs/rook/v1.4/ceph-storage.html
[Ceph Block Storage]: https://rook.io/docs/rook/v1.4/ceph-block.html
[Ceph Filesystem]: https://rook.io/docs/rook/v1.4/ceph-filesystem.html
[kube-prometheus]: https://github.com/prometheus-operator/kube-prometheus
[JupyterLab]: https://github.com/jupyterlab/jupyterlab
[GitLab CI]: https://docs.gitlab.com/ce/ci/
[Kaniko]: https://github.com/GoogleContainerTools/kaniko
[JupyterHub]: https://jupyter.org/hub
[Kubernetes API]: https://kubernetes.io/docs/concepts/overview/kubernetes-api/
[Geth]: https://geth.ethereum.org/
[Ethstats]: https://github.com/cubedro/eth-netstats
[Kilo]: https://github.com/squat/kilo
[Nvidia]: https://www.nvidia.com/en-us/
[CUDA]: https://developer.nvidia.com/cuda-zone
[Bash]: https://www.gnu.org/software/bash/
[Raspberry Pi]: https://www.raspberrypi.org/
[CronJob]: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
[Python]: https://www.python.org/
[Golang]: https://golang.org/
