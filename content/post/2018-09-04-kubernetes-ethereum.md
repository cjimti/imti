---
draft: true
layout:   post
title:    "Ethereum Blockchain on Kubernetes"
subtitle: "Deploy a Private Ethereum Blockchain on a Custom Kubernetes Cluster."
date:     2018-09-04
author:   "Craig Johnston"
URL:      "ethereum-kubernetes/"
image:    "/img/post/kubeeth.jpg"
twitter_image:  "/img/post/kubeeth.jpg"
tags:
- Ethereum
- Kubernetes
- Blockchain
series:
- Blockchain
- Kubernetes
---

Blockchain technologies have been made popular by Cryptocurencies shuch as Bitcoin and Ethereum. However, the concepts behind [Blockchain] are fore more reaching than their support for currency. Blockchain technologies now support any digital asset, from signal data to complex messaging, to the execution of business logic through code. Blockchain technologies are rapidly forming a new decentralized internet of transactions.

[Kubernetes] is an efficient and productive platform for the configuration, deployment and management of private blockchains. Blockchain technology is intended to provide a decentralized transaction ledger, making it a perfect fit for the distributed nature of Kubernetes Pod deployments. The Kubernetes network infrastructure provides the necessary elements for security, scalability and fault tolerance needed for private or protected Blockchains.

Ethereum is a Cryptocurency as well as a platform. [Ethereum] "is a decentralized platform that runs smart contracts: applications that run exactly as programmed without any possibility of downtime, censorship, fraud or third-party interference."

{{< toc >}}

## Setting up Ethereum on Kubernetes

In my opinion the best way to learn and understand the capabilities of this technology is by implementing your own private **production ready** Blockchain. Beginner tutorials often get you up and running on a local workstation leaving out important production implementation details, other quick start guides use package managers like Helm that do all the work for you. However both these aproaches leave gaps, ether in in understanding how to migrate and scale into a production system in the case of local development or in the case of package managers hiding implementation details and limiting configuration options.

The follow is an idiomatic Kubernetes setup. Providing and describing each configuration step in leveraging Kubernetes core concept of declarative state configuration.

### Bare Metal / Custom Kubernetes

To avoid vendor lock-in or vendor specific instructions, this guide builds a private Ethereum Blockchain on a custom Kubernetes cluster. If you don't already have a cluster I recommend setting up a [production ready Kubernetes hobby cluster][Kubernetes Hobby Cluster].

### Resource Organization / Namespaces

[Namespaces] in Kubernetes allow you to separate [services] or projects into a logical groups. In this guide I will use the fictional namespace **the-project**. Applications within the namespace can easily find each other by their Service name. Networking within a Kubernetes [Pod] uses internal DNS to locate a service by it's name (or name.namespace).

[RBAC] or Role Base Access Control for a [Namespaces] offers a suitable solution to securing the configuration and opperation of private blockchain to group of external users or systems. See [Kubernetes Team Access - RBAC for developers and QA][RBAC] for details on Namespace based security.

### Private Blockchain Network Topology

The articles [Using Helm to Deploy Blockchain to Kubernetes] and [Building a Private Ethereum Consortium] on Microsoft's Developer Blog offer some very clear illustrations of this private Blockchain setup, following implementation is deconstruction of the referenced Helm Chart.

### Bootnode

A **bootnode** is a "Stripped down version of our Ethereum client implementation that only takes part in the network node discovery protocol, but does not run any of the higher level application protocols. It can be used as a lightweight bootstrap node to aid in finding peers in private networks."

#### Bootnode Service

The **Bootnode Service** provides the endpoints `eth-bootnode:30301` and `eth-bootnode:8080` to Pod with the selector **eth-bootnode** defined further down in the **Bootnode Deployment**.

Create the file `110-bootnode-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: eth-bootnode
  namespace: the-project
  labels:
    app: eth-bootnode
spec:
  selector:
    app: eth-bootnode
  clusterIP: None
  ports:
  - name: discovery
    port: 30301
    protocol: UDP
  - name: http
    port: 8080
```

Apply the configuration:
```bash
kubectl create -f ./110-bootnode-service.yml
```

#### Bootnode Deployment

Bootnode Pods use the official **[ethereum/client-go]** Docker container, in this case, version **alltools-release-1.8**. Bootnode Pods start with an initialization container (initContainers section) named **genkey**. The genkey init container run the command `bootnode --genkey=/etc/bootnode/node.key`.

> As can be seen the bootnode asks for a key. Each ethereum node, including a bootnode is identified by an enode identifier. These identifiers are derived from a key. Therefore you will need to give the bootnode such key. Since we currently don't have one we can instruct the bootnode to generate a key (and store it in a file) before it starts.

Once the **genkey** init container has completed the Bootnode Pod run two containers, **bootnode** on port **30301/UDP** is the running bootnode and **bootnode-server** is a simple command-line web server that responds on port **8080/TCP** with the Ethereum node address.

The following is an example response from the **bootnode-server** exposed by the service added above (ellipses added for brevity):

```bash
curl eth-bootnode:8080
enode://e01bcec287...ceb1a7ada4f@192.168.108.136:30301
```

Create the file `120-bootnode-deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eth-bootnode
  namespace: the-project
  labels:
    app: eth-bootnode
spec:
  replicas: 2
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: eth-bootnode
  template:
    metadata:
      labels:
        app: eth-bootnode
    spec:
      containers:
      - name: bootnode
        image: ethereum/client-go:alltools-release-1.8
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: ".5"
          requests:
            cpu: "0.25"
        command: ["/bin/sh"]
        args:
        - "-c"
        - "bootnode --nodekey=/etc/bootnode/node.key --verbosity=4"
        volumeMounts:
        - name: data
          mountPath: /etc/bootnode
        ports:
        - name: discovery
          containerPort: 30301
          protocol: UDP
      - name: bootnode-server
        image: ethereum/client-go:alltools-release-1.8
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args:
        - "-c"
        - "while [ 1 ]; do echo -e \"HTTP/1.1 200 OK\n\nenode://$(bootnode -writeaddress --nodekey=/etc/bootnode/node.key)@$(POD_IP):30301\" | nc -l -v -p 8080 || break; done;"
        volumeMounts:
        - name: data
          mountPath: /etc/bootnode
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        ports:
        - containerPort: 8080
      initContainers:
      - name: genkey
        image: ethereum/client-go:alltools-release-1.8
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args:
        - "-c"
        - "bootnode --genkey=/etc/bootnode/node.key"
        volumeMounts:
        - name: data
          mountPath: /etc/bootnode
      volumes:
      - name: data
        emptyDir: {}
```

Apply the configuration:
```bash
kubectl create -f ./120-bootnode-deployment.yml
```

### Bootnode Registrar

[bootnode-registrar] is a "Registrar for Geth Bootnodes. bootnode-registrar will resolve a DNS address record to a enode addresses that can then be consumed by geth --bootnodes=<enodes>." written by [Jason Poon].

Later on in this configuration the **miner** and **tx** Pods initialize by calling the **eth-bootnode-registrar:80** service to receive a comma-separated list of bootnodes as Ethereum node address.

An example response from this services (ellipses added for brevity):
```plain
enode://e01bc...672ceb1a7ada4f@192.168.108.136:30301,enode://a5f65...d7c9e356d@192.168.59.1:30301
```

#### Bootnode Registrar Service

Create the file `130-bootnode-registrar-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: eth-bootnode-registrar
  namespace: the-project
  labels:
    app: eth-bootnode-registrar
spec:
  selector:
    app: eth-bootnode-registrar
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 9898
```

Apply the configuration:
```bash
kubectl create -f ./130-bootnode-registrar-service.yml
```

#### Bootnode Registrar Deployment

The Bootnode Registrar Deployment uses the [bootnode-registrar] container. [bootnode-registrar] is open source and you can easily build your own custom container with the provided [Dockerfile](https://github.com/jpoon/bootnode-registrar/blob/master/Dockerfile). In this configuration the pre-build container is used.

If you are using a custom namespace be sure to change the **BOOTNODE_SERVICE** environment variable to the namespace you are using: "eth-bootnode.**the-project**.svc.cluster.local".

The [bootnode-registrar] Pod runs a single Docker container named `bootnode-registrar`, running the `jpoon/bootnode-registrar:v1.0.0` image from Docker hub.

Create the file `140-bootnode-registrar-deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eth-bootnode-registrar
  namespace: the-project
  labels:
    app: eth-bootnode-registrar
spec:
  replicas: 1
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: eth-bootnode-registrar
  template:
    metadata:
      labels:
        app: eth-bootnode-registrar
    spec:
      containers:
      - name: bootnode-registrar
        image: jpoon/bootnode-registrar:v1.0.0
        imagePullPolicy: IfNotPresent
        env:
        - name: BOOTNODE_SERVICE
          value: "eth-bootnode.the-project.svc.cluster.local"
        ports:
        - containerPort: 9898
```

Apply the configuration:
```bash
kubectl create -f ./140-bootnode-registrar-deployment.yml
```

### Ethstats Dashboard

The [eth-netstats] project provides an incredible dashboard interface for monitoring Ethereum nodes. [eth-netstats] consumes stats provided by the Ethereum [geth] nodes. [Geth] is the the command line interface for running a full Ethereum node implemented in Go and deployed as **miner** and **tx**

[![Ethstats Dashboard](/img/post/ethstats.jpg)](/ethereum-ethstats/)

Read the article [Ethereum Ethstats / Describing the metrics.](/ethereum-ethstats/) if you are new to Blockchain or Ethereum terminology. In the article I review essential metrics and their meaning.


#### Ethstats Dashboard Service

Create the file `210-ethstats-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: eth-ethstats
  namespace: the-project
  labels:
    app: eth-ethstats
spec:
  selector:
    app: eth-ethstats
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
```

Apply the configuration:
```bash
kubectl create -f ./210-ethstats-service.yml
```

#### Ethstats Dashboard Secret

The [geth] nodes pass their Hostname and a common password to Ethstats. The password is stored in a Kubernetes Secret as a base64 encoded string.

You can create a password on MacOs or Linux terminals by piping a string to the command base64, or you can use the site [base64decode.org](https://www.base64decode.org/) to create a base64 encoded string.

Create Ethstats API Password:
```bash
 echo -n 'changeme' | base64
 Y2hhbmdlbWU=
```

The following Secret `eth-ethstats` will be mounted by Ethstats and the [geth] node Pods further down this guide.

Create the file `220-ethstats-secret.yml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: eth-ethstats
  namespace: the-project
  labels:
    app: eth-ethstats
type: Opaque
data:
  # "changeme"
  WS_SECRET: "Y2hhbmdlbWU="
```

Apply the configuration:
```bash
kubectl create -f ./220-ethstats-secret.yml
```

#### Ethstats Dashboard Deployment

Create the file `230-ethstats-deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eth-ethstats
  namespace: the-project
  labels:
    app: eth-ethstats
spec:
  replicas: 1
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: eth-ethstats
  template:
    metadata:
      labels:
        app: eth-ethstats
    spec:
      containers:
      - name: ethstats
        image: ethereumex/eth-stats-dashboard:latest
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 3000
        env:
        - name: WS_SECRET
          valueFrom:
            secretKeyRef:
              name: eth-ethstats
              key: WS_SECRET
```

Apply the configuration:
```bash
kubectl create -f ./230-ethstats-deployment.yml
```

[ethereumex/eth-stats-dashboard container]

#### Ethstats Dashboard Ingress

Create the file `240-ethstats-ingress.yml`:
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: eth-ethstats
  namespace: the-project
  labels:
    app: eth-ethstats
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: imti-basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  rules:
  - host: ethstats.dcp.dev.d4l.cloud
    http:
      paths:
      - backend:
          serviceName: eth-ethstats
          servicePort: 80
        path: /
  tls:
  - hosts:
    - ethstats.eth.imti.co
    secretName: imti-dev-production-tls
```

Apply the configuration:
```bash
kubectl create -f ./240-ethstats-ingress.yml
```

### Geth Configuration

#### Ethereum Genesis Block

#### Geth ConfigMap

### Geth Miner Nodes

#### Geth Miner Secret

#### Geth Miner Deployment

### Geth Transaction Nodes

#### Geth Transaction Nodes Deployment

### Diagnostics

#### DAG and The First Block

#### txpool


## Additional Resources

- [go-ethereum Private-network] Github Wiki
- [leveraging Kubernetes to run a private production ready Ethereum network] by Maximilian Meister
- [bootnode-registrar] bootnode DNS services
- [static bootnode-registrar] static bootnode DNS services

[Kubernetes]:https://kubernetes.io/
[Namespaces]:https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[Pod]:https://kubernetes.io/docs/concepts/workloads/pods/pod/
[services]:https://kubernetes.io/docs/concepts/services-networking/service/
[Ethereum]:https://www.ethereum.org/
[Blockchain]: http://imti.co/blockchain/
[Kubernetes Hobby Cluster]:https://imti.co/hobby-cluster/
[RBAC]:https://imti.co/team-kubernetes-remote-access/
[Using Helm to Deploy Blockchain to Kubernetes]:https://www.microsoft.com/developerblog/2018/02/09/using-helm-deploy-blockchain-kubernetes/
[Building a Private Ethereum Consortium]:https://www.microsoft.com/developerblog/2018/06/01/creating-private-ethereum-consortium-kubernetes/
[bootnode-registrar]:https://github.com/jpoon/bootnode-registrar
[static bootnode-registrar]:https://github.com/EthereumEx/bootnode-registrar
[go-ethereum Private-network]:https://github.com/ethereum/go-ethereum/wiki/Private-network
[leveraging Kubernetes to run a private production ready Ethereum network]:https://medium.com/@cryptoctl/leveraging-kubernetes-to-run-a-private-production-ready-ethereum-network-b6f9b49098df
[ethereum/client-go]:https://hub.docker.com/r/ethereum/client-go/
[bootnode-registrar]:https://github.com/jpoon/bootnode-registrar
[Jason Poon]:http://jasonpoon.ca/
[ethereumex/eth-stats-dashboard container]:https://hub.docker.com/r/ethereumex/eth-stats-dashboard/
[eth-netstats]:https://github.com/cubedro/eth-netstats
[geth]:https://github.com/ethereum/go-ethereum/wiki/geth