---
draft: true
layout:   post
title:    "Ethereum Blockchain on Kubernetes"
subtitle: "Deploy a Private Ethereum Blockchain on a Custom Kubernetes Cluster."
date:     2018-09-04
author:   "Craig Johnston"
URL:      "ethereum-kubernetes/"
image:    "/img/post/kubeeth.jpg"
twitter_image:  "/img/post/kubeeth_876_438.jpg"
tags:
- Ethereum
- Kubernetes
- Blockchain
series:
- Blockchain
- Kubernetes
---

Blockchain technologies have been made famous by Cryptocurrencies such as Bitcoin and Ethereum. However, the concepts behind [Blockchain] are fore more reaching than their support for cryptocurrency. Blockchain technologies now support any digital asset, from signal data to complex messaging, to the execution of business logic through code. Blockchain technologies are rapidly forming a new decentralized internet of transactions.

[Kubernetes] is an efficient and productive platform for the configuration, deployment, and management of private blockchains. Blockchain technology is intended to provide a decentralized transaction ledger, making it a perfect fit for the distributed nature of Kubernetes Pod deployments. The Kubernetes network infrastructure provides the necessary elements for security, scalability and fault tolerance needed for private or protected Blockchains.

Ethereum is a Cryptocurrency as well as a platform. [Ethereum] "is a decentralized platform that runs smart contracts: applications that run exactly as programmed without any possibility of downtime, censorship, fraud or third-party interference."

{{< toc >}}

## Setting up Ethereum on Kubernetes

In my opinion, the best way to learn and understand the capabilities of this technology is by implementing your own private **production ready** Blockchain. Beginner tutorials often get you up and running on a local workstation leaving out important production implementation details; other quick start guides use package managers like Helm that do all the work for you. However, both these approaches leave gaps, either in understanding how to migrate and scale into a production system in the case of local development or the case of package managers hiding implementation details and limiting configuration options.

The following is an idiomatic Kubernetes setup. Providing and describing each configuration step in leveraging the Kubernetes core concept of declarative state configuration.

The transaction and miner nodes run the official [ethereum/client-go:release-1.8] Docker containers.

### Bare Metal / Custom Kubernetes

This guide builds a private Ethereum Blockchain on a custom Kubernetes cluster and avoids vendor lock-in or vendor specific instructions. If you don't already have a cluster, I recommend setting up a [production ready Kubernetes hobby cluster][Kubernetes Hobby Cluster].

### Resource Organization / Namespaces

[Namespaces] in Kubernetes allow you to separate [services] or projects into logical groups. In this guide, I use the fictional namespace **the-project**. Applications within the namespace can easily find each other by their Service name. Networking within a Kubernetes [Pod] uses internal DNS to locate a service by its name (or name.namespace).

[RBAC] or Role Based Access Control for a [Namespaces] offers a suitable solution to securing the configuration and operation of private blockchain to a group of external users or systems. See [Kubernetes Team Access - RBAC for developers and QA][RBAC] for details on Namespace-based security.

### Private Blockchain Network Topology

The articles [Using Helm to Deploy Blockchain to Kubernetes] and [Building a Private Ethereum Consortium] on Microsoft's Developer Blog offer some great illustrations of this private Blockchain setup, following implementation is a deconstruction of the referenced Helm Chart.

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

> As can be seen the bootnode asks for a key. Each ethereum node, including a bootnode, is identified by an enode identifier. These identifiers are derived from a key. Therefore you will need to give the bootnode such key. Since we currently don't have one, we can instruct the bootnode to generate a key (and store it in a file) before it starts.

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

[bootnode-registrar] is a "Registrar for Geth Bootnodes. bootnode-registrar resolves a DNS address record to a enode addresses that can then be consumed by geth --bootnodes=<enodes>." written by [Jason Poon].

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

The Bootnode Registrar Deployment uses the [bootnode-registrar] container. [bootnode-registrar] is open source and you can quickly build a custom container with the provided [Dockerfile](https://github.com/jpoon/bootnode-registrar/blob/master/Dockerfile). In this configuration uses the pre-built container provided.

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

The [eth-netstats] project provides an incredible dashboard interface for monitoring Ethereum nodes. [eth-netstats] consumes stats provided by the Ethereum [geth] nodes. [Geth] is the command line interface for running a full Ethereum node implemented in Go and deployed as **miner** and **tx**

[![Ethstats Dashboard](/img/post/ethstats.jpg)](/ethereum-ethstats/)

Read the article [Ethereum Ethstats / Describing the metrics.](/ethereum-ethstats/) if you are new to Blockchain or Ethereum terminology. In the article, I review essential metrics and their meaning.


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

The [geth] nodes pass their Hostname and a shared password to Ethstats.  A Kubernetes Secret stores the password as base64 encoded string.

You can create a password on MacOs or Linux terminals by piping a string to the command base64, or you can use the site [base64decode.org](https://www.base64decode.org/) to create a base64 encoded string.

Create Ethstats API Password:
```bash
 echo -n 'changeme' | base64
 Y2hhbmdlbWU=
```

The following Secret `eth-ethstats` is mounted by Ethstats and the [geth] node Pods further down this guide.

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

The Ethstats dashboard Deployment uses the Docker [ethereumex/eth-stats-dashboard container] from [Ethereum Expertise](https://github.com/EthereumEx). The container uses the environment variable **WS_SECRET** to set the password the Ethereum nodes use in calling to report their stats.  The **eth-ethstats** Secret created above defines the password.

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

To access the Ethstats Dashboard from outside of the cluster, you need to have [Ingress] configured on your cluster. If you do not have an [Ingress] controller installed, I suggest reading [Ingress on Custom Kubernetes] for a quick guide on setting up **[ingress-nginx]**.

The example below uses the secret **imti-dev-production-tls** to provide an SSL cert. [Let's Encrypt] is a free, automated, and open Certificate Authority and a simple way to get up and running on a custom Kubernetes cluster. I suggest reading [Let's Encrypt, Kubernetes] to get up and running quickly with SSL.

Lastly, the following Ingress configuration uses annotations to specify a Basic Auth password from the secret **imti-basic-auth**, if you are new to Basic Auth on Kubernetes Ingress I suggest reading [Basic Auth on Kubernetes Ingress], which gives clear instructions for generating a secret that can be used with **[ingress-nginx]**.

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

[Geth] is the command line interface for running a full ethereum node implemented in Go. [Geth] is used to mine Eth, transfer funds between addresses, create contracts and send transactions, explore block history and many other operations.

The following configurations use [Geth] to initialize the new private blockchain, configure miners and operate transaction only nodes.

#### Ethereum Genesis Block

Read [Explaining the Genesis Block in Ethereum](https://arvanaghi.com/blog/explaining-the-genesis-block-in-ethereum/) for a better understanding of the Ethereum Genesis Block.

[Geth] nodes initialize themselves and start the new private blockchain with the first block (Ethereum Genesis Block) defined in the key `genesis.json`.

You should customize the value **networkid** in the ConfigMap and the **"chainId"** in the `genesis.json`. Ethereum nodes must have the same genesis block and networkid to join a network. Large **networkid**s typically indicate private networks.


#### Geth ConfigMap

The [Geth] miner and transaction pods mount the Geth ConfigMap created here.

Along with customizing the **networkid**/**chainId**, you may also add Ethereum accounts to fund when the Genesis Block gets created. These can be any addresses you like. Use [MetaMask] or [MyEtherWallet] for an easy way to manage accounts or [install Geth] on your local workstation and type `geth account new` to create some new accounts.

This private network has a limited number of miners running with restricted CPU access, so we want to keep the difficulty low.

Read the [official documentation on private networks](https://github.com/ethereum/go-ethereum/wiki/Private-network) configuration for more details on choosing a network id and creating the Genesis Block.

Create the file `310-geth-configmap.yml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: eth-geth
  namespace: the-project
  labels:
    app: eth-geth
data:
  networkid: "8189450821"
  genesis.json: |-
    {
        "config": {
            "chainId": 8189450821,
            "homesteadBlock": 0,
            "eip150Block": 0,
            "eip155Block": 0,
            "eip158Block": 0
        },
        "difficulty": "0x400",
        "gasLimit": "2000000",
        "nonce"   : "0x0000000000000000",
        "alloc": {
          "0x58917D55dA991da576F148FD7E3E05a34666988b": { "balance": "100000000000000000000" },
          "0x29bb385cF8ae4Cc49dBd10CcdA5e3d591D831527": { "balance": "200000000000000000000" },
          "0xf1c9C9a1Ba591588147c2A729c470D8AFA91a04d": { "balance": "300000000000000000000" }
        }
    }
```

Apply the configuration:
```bash
kubectl create -f ./310-geth-configmap.yml
```

### Geth Miner Nodes

The following configuration deploys three [Geth] miner nodes that share a [Secret] used for creating their coinbase accounts.

#### Geth Miner Secret

A Kubernetes [Secret] is used to store a common password each miner uses for creating an Ethereum account funded by block creation rewards; this is called the coinbase. This password is used to unlock the associated Ethereum account to transfer Eth gained from the minder nodes to other accounts. However, the coinbase may be configured for each miner can at any time.

You can create a password on MacOs or Linux terminals by piping a string to the command base64, or you can use the site [base64decode.org] to create a base64 encoded string.

Create Ethstats API Password:
```bash
 echo -n 'password' | base64
 cGFzc3dvcmQ=
```

Create the file `320-geth-miner-secret.yml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: eth-geth-miner
  namespace: the-project
  labels:
    app: eth-geth-miner
type: Opaque
data:
  # echo -n 'password' | base64
  accountsecret: "cGFzc3dvcmQ="
```

Apply the configuration:
```bash
kubectl create -f ./320-geth-miner-secret.yml
```

#### Geth Miner Deployment

This configuration starts with three miner Pods but can easily be scaled. Pods consist of one main container named **geth-miner** and two initialization containers named **init-genesis** and **eth-geth-miner**.

The pods request a minimum CPU allotment of 0.25 cores and maximum of 1.

Create the file `330-geth-miner-deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eth-geth-miner
  namespace: the-project
  labels:
    app: eth-geth-miner
spec:
  replicas: 3
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: eth-geth-miner
  template:
    metadata:
      labels:
        app: eth-geth-miner
    spec:
      containers:
      - name: geth-miner
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: ".5"
          requests:
            cpu: "0.25"
        command: ["/bin/sh"]
        args:
        - "-c"
        - "geth --bootnodes=`cat /root/.ethereum/bootnodes` --mine --etherbase=0 --networkid=${NETWORK_ID} --ethstats=${HOSTNAME}:${ETHSTATS_SECRET}@${ETHSTATS_SVC} --verbosity=5"
        env:
        - name: ETHSTATS_SVC
          value: eth-ethstats.dcp
        - name: ETHSTATS_SECRET
          valueFrom:
            secretKeyRef:
              name: eth-ethstats
              key: WS_SECRET
        - name: NETWORK_ID
          valueFrom:
            configMapKeyRef:
              name: eth-geth
              key: networkid
        ports:
        - name: discovery-udp
          containerPort: 30303
          protocol: UDP
        - name: discovery-tcp
          containerPort: 30303
        volumeMounts:
        - name: data
          mountPath: /root/.ethereum
      initContainers:
      - name: init-genesis
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        args:
        - "init"
        - "/var/geth/genesis.json"
        volumeMounts:
        - name: data
          mountPath: /root/.ethereum
        - name: config
          mountPath: /var/geth
      - name: create-account
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args:
        - "-c"
        - "printf '$(ACCOUNT_SECRET)\n$(ACCOUNT_SECRET)\n' | geth account new"
        env:
        - name: ACCOUNT_SECRET
          valueFrom:
            secretKeyRef:
              name: eth-geth-miner
              key: accountsecret
        volumeMounts:
        - name: data
          mountPath: /root/.ethereum
      - name: get-bootnodes
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args:
        - "-c"
        - |-
          apk add --no-cache curl;
          CNT=0;
          echo "retreiving bootnodes from $BOOTNODE_REGISTRAR_SVC"
          while [ $CNT -le 90 ]
          do
            curl -m 5 -s $BOOTNODE_REGISTRAR_SVC | xargs echo -n >> /geth/bootnodes;
            if [ -s /geth/bootnodes ]
            then
              cat /geth/bootnodes;
              exit 0;
            fi;

            echo "no bootnodes found. retrying $CNT...";
            sleep 2 || break;
            CNT=$((CNT+1));
          done;
          echo "WARNING. unable to find bootnodes. continuing but geth may not be able to find any peers.";
          exit 0;
        env:
        - name: BOOTNODE_REGISTRAR_SVC
          value: eth-bootnode-registrar
        volumeMounts:
        - name: data
          mountPath: /geth
      volumes:
      - name: data
        emptyDir: {}
      - name: config
        configMap:
          name: eth-geth
```

Apply the configuration:
```bash
kubectl create -f ./330-geth-miner-deployment.yml
```

### Geth Transaction Nodes

Geth Transaction Nodes **eth-geth-tx** are only used to create transactions on the private blockchain.

#### Geth Transaction Nodes Service

Access to Geth Transaction Nodes is through a [Service] named **eth-geth-tx** on ports 8545 and 8546.

Create the file `410-geth-tx-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: eth-geth-tx
  namespace: the-project
  labels:
    app: eth-geth-tx
spec:
  selector:
    app: eth-geth-tx
  type: ClusterIP
  ports:
  - name: rpc
    port: 8545
  - name: ws
    port: 8546
```

Apply the configuration:
```bash
kubectl create -f ./410-geth-tx-service.yml
```

#### Geth Transaction Nodes Deployment

Issuing transactions on the private Blockchain occur through a set of two Geth Transaction Nodes; these Pods are setup similar to miners running the official [ethereum/client-go:release-1.8]. Geth Transaction Node consist of one main container named **geth-tx** and two initialization containers **init-genesis** and **get-bootnodes**.

Create the file `420-geth-tx-deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eth-geth-tx
  namespace: the-project
  labels:
    app: eth-geth-tx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: eth-geth-tx
  template:
    metadata:
      labels:
        app: eth-geth-tx
    spec:
      containers:
      - name: geth-tx
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args:
        - "-c"
        - "geth --bootnodes=`cat /root/.ethereum/bootnodes` --rpc --rpcapi=eth,net,web3 --rpccorsdomain='*' --ws --networkid=${NETWORK_ID} --ethstats=${HOSTNAME}:${ETHSTATS_SECRET}@${ETHSTATS_SVC} --verbosity=5"
        env:
        - name: ETHSTATS_SVC
          value: eth-ethstats.dcp
        - name: ETHSTATS_SECRET
          valueFrom:
            secretKeyRef:
              name: eth-ethstats
              key: WS_SECRET
        - name: NETWORK_ID
          valueFrom:
            configMapKeyRef:
              name: eth-geth
              key: networkid
        ports:
        - name: rpc
          containerPort: 8545
        - name: ws
          containerPort: 8546
        - name: discovery-udp
          containerPort: 30303
          protocol: UDP
        - name: discovery-tcp
          containerPort: 30303
        volumeMounts:
        - name: data
          mountPath: /root/.ethereum
      initContainers:
      - name: init-genesis
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        args:
        - "init"
        - "/var/geth/genesis.json"
        volumeMounts:
        - name: data
          mountPath: /root/.ethereum
        - name: config
          mountPath: /var/geth
      - name: get-bootnodes
        image: ethereum/client-go:release-1.8
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args:
        - "-c"
        - |-
          apk add --no-cache curl;
          CNT=0;
          echo "retreiving bootnodes from $BOOTNODE_REGISTRAR_SVC"
          while [ $CNT -le 90 ]
          do
            curl -m 5 -s $BOOTNODE_REGISTRAR_SVC | xargs echo -n >> /geth/bootnodes;
            if [ -s /geth/bootnodes ]
            then
              cat /geth/bootnodes;
              exit 0;
            fi;

            echo "no bootnodes found. retrying $CNT...";
            sleep 2 || break;
            CNT=$((CNT+1));
          done;
          echo "WARNING. unable to find bootnodes. continuing but geth may not be able to find any peers.";
          exit 0;
        env:
        - name: BOOTNODE_REGISTRAR_SVC
          value: eth-bootnode-registrar.dcp
        volumeMounts:
        - name: data
          mountPath: /geth
      volumes:
      - name: data
        emptyDir: {}
      - name: config
        configMap:
          name: eth-geth
```

Apply the configuration:
```bash
kubectl create -f ./420-geth-tx-deployment.yml
```

## Conclusion

Depending on your difficulty and resources it may take 10-20 minutes to mine your first block in this private chain. However, the difficulty is automatically adjusted, and you may begin to mine blocks at around 20-30 seconds on average.

## Additional Resources

- [go-ethereum Private-network] Github Wiki
- [MetaMask] Ethereum account management

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
[go-ethereum Private-network]:https://github.com/ethereum/go-ethereum/wiki/Private-network
[ethereum/client-go]:https://hub.docker.com/r/ethereum/client-go/
[bootnode-registrar]:https://github.com/jpoon/bootnode-registrar
[Jason Poon]:http://jasonpoon.ca/
[ethereumex/eth-stats-dashboard container]:https://hub.docker.com/r/ethereumex/eth-stats-dashboard/
[eth-netstats]:https://github.com/cubedro/eth-netstats
[geth]:https://github.com/ethereum/go-ethereum/wiki/geth
[Ingress]:https://kubernetes.io/docs/concepts/services-networking/ingress/
[Ingress on Custom Kubernetes]:https://imti.co/web-cluster-ingress/
[Let's Encrypt]:https://letsencrypt.org/
[Let's Encrypt, Kubernetes]:https://imti.co/lets-encrypt-kubernetes/
[Basic Auth on Kubernetes Ingress]:https://imti.co/kubernetes-ingress-basic-auth/
[ingress-nginx]:https://kubernetes.github.io/ingress-nginx/
[install Geth]:https://github.com/ethereum/go-ethereum/wiki/Installing-Geth
[MyEtherWallet]:https://www.myetherwallet.com/
[MetaMask]:https://metamask.io/
[Secret]:https://kubernetes.io/docs/concepts/configuration/secret/
[base64decode.org]:https://www.base64decode.org/
[Service]:https://kubernetes.io/docs/concepts/services-networking/service/
[ethereum/client-go:release-1.8]:https://hub.docker.com/r/ethereum/client-go/