---
draft: false
layout:   post
title:    "Kafka on Kubernetes"
subtitle: "Deploy a highly available Kafka cluster on Kubernetes."
date:     2018-09-25
author:   "Craig Johnston"
URL:      "kafka-kubernetes/"
image:    "/img/post/kafka.jpg"
twitter_image:  "/img/post/kafka_876_438.jpg"
tags:
- Kafka
- Kubernetes
- Data
series:
- Kubernetes
- Kafka
- Data
---

[Kafka] is a fast, horizontally scalable, fault-tolerant, message queue service. [Kafka] is used for building real-time data pipelines and streaming apps.

There are a few [Helm] based installers out there including the official Kubernetes [incubator/kafka]. However, in this article, I walk through applying a surprisingly small set of Kubernetes configuration files needed to stand up high performance, highly available Kafka. Manually applying Kubernetes configurations gives you a step-by-step understanding of the system you are deploying and limitless opportunities to customize.

If you want a separate Kubernetes cluster to run or experiment with Kafka, I recommend reading my article on setting up a Kubernetes [Production Hobby Cluster] for a quick and inexpensive way to deploy a production capable cluster.

{{< toc >}}

{{< content-ad >}}


## Setting up Kafka on Kubernetes

This guide set up a three-node [Kafka] cluster and a three-node [Zookeeper] cluster required by Kafka. Kafka and Zookeeper can be manually scaled up at any time by altering and re-applying configuration. Kubernetes also provides features for autoscaling, read more about [auto scaling] Kubernetes Pods should that be a requirement.

### Namespace

In this guide, I use the fictional [namespace] **the-project**. You can create this namespace in your cluster or use your own.

Create the file `000-namespace.yml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: the-project
```

Apply the configuration:
```bash
kubectl create -f ./000-namespace.yml
```

If you wish to use your own [namespace] for this Kafka installation, be sure to replace **the-project** in the configurations below.

### Zookeeper

[Kafka] requires [Zookeeper] for maintaining configuration information, naming, providing distributed synchronization, and providing group services to coordinate its nodes.

#### Zookeeper Service

Kubernetes Services are persistent and provide a stable and reliable way to connect to Pods.

Setup a Kubernetes [Service] named **kafka-zookeeper** in namespace **the-project**. The **kafka-zookeeper** service resolves the domain name **kafka-zookeeper** to an internal ClusterIP. The automatically assigned ClusterIP uses Kubernetes internal proxy to load balance calls to any Pods found from the configured selector, in this case, `app: kafka-zookeeper`.

After setting up the **kafka-zookeeper** Service, a DNS lookup from within the cluster may produce a result similar to the following:

```bash
# nslookup kafka-zookeeper
Server:        10.96.0.10
Address:    10.96.0.10#53

Name:    kafka-zookeeper.the-project.svc.cluster.local
Address: 10.103.184.71
```

In the example above, 10.103.184.71 is the internal IP address of the ** **kafka-zookeeper*** service itself and proxies calls to one of the Zookeeper Pods it finds labeled **app: kafka-zookeeper**. At this point, no Pods are available until added further down. However, the service finds them when they become active.

Create the file `110-zookeeper-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-zookeeper
  namespace: the-project
spec:
  ports:
  - name: client
    port: 2181
    protocol: TCP
    targetPort: client
  selector:
    app: kafka-zookeeper
  sessionAffinity: None
  type: ClusterIP
```

Apply the configuration:
```bash
kubectl create -f ./110-zookeeper-service.yml
```

#### Zookeeper Headless Service

A Kubernetes Headless Service does not resolve to a single IP; instead, Headless Services returns the IP addresses of any Pods found by their selector, in this case, Pods labeled **app: kafka-zookeeper**.

Once Pods labeled **app: kafka-zookeeper** are running, this Headless Service returns the results of an in-cluster DNS lookup similar to the following:

```bash
# nslookup kafka-zookeeper-headless
Server:        10.96.0.10
Address:    10.96.0.10#53

Name:    kafka-zookeeper-headless.the-project.svc.cluster.local
Address: 192.168.108.150
Name:    kafka-zookeeper-headless.the-project.svc.cluster.local
Address: 192.168.108.181
Name:    kafka-zookeeper-headless.the-project.svc.cluster.local
Address: 192.168.108.132
```

In the example above, the Kubernetes Service **kafka-zookeeper-headless** returned the internal IP addresses of three individual Pods.

At this point, no Pod IPs can be returned until the Pods are configured in the StatefulSet further down.

Create the file `110-zookeeper-service-headless.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-zookeeper-headless
  namespace: the-project
spec:
  clusterIP: None
  ports:
  - name: client
    port: 2181
    protocol: TCP
    targetPort: 2181
  - name: election
    port: 3888
    protocol: TCP
    targetPort: 3888
  - name: server
    port: 2888
    protocol: TCP
    targetPort: 2888
  selector:
    app: kafka-zookeeper
  sessionAffinity: None
  type: ClusterIP
```

Apply the configuration:
```bash
kubectl create -f ./110-zookeeper-service-headless.yml
```

#### Zookeeper StatefulSet

Kubernetes [StatefulSet]s offer stable and unique network identifiers, persistent storage, ordered deployments, scaling, deletion, termination, and automated rolling updates.

Unique network identifiers and persistent storage are essential for stateful cluster nodes in systems like Zookeeper and Kafka. While it seems strange to have a coordinator like Zookeeper running inside a Kubernetes cluster sitting on its own coordinator Etcd, it makes sense since these systems are built to run independently. Kubernettes supports running services like Zookeeper and Kafka with features like headless services and stateful sets which demonstrates the flexibility of Kubernetes as both a microservices platform and a type of virtual infrastructure.

The following configuration creates three **kafka-zookeeper** Pods, kafka-zookeeper-0, kafka-zookeeper-1, kafka-zookeeper-2 and can be scaled to as many as desired. Ensure that the number of specified replicas matches the environment variable **ZK_REPLICAS** specified in the container spec.

Pods in this [StatefulSet] run the Zookeeper Docker image `gcr.io/google_samples/k8szk:v3`, which is a **sample image** provided by Google for testing GKE, it is recommended to use custom and maintained Zookeeper image once you are familiar with this setup.

Create the file `140-zookeeper-statefulset.yml`:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka-zookeeper
  namespace: the-project
spec:
  podManagementPolicy: OrderedReady
  replicas: 3
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: kafka-zookeeper
  serviceName: kafka-zookeeper-headless
  template:
    metadata:
      labels:
        app: kafka-zookeeper
    spec:
      containers:
      - command:
        - /bin/bash
        - -xec
        - zkGenConfig.sh && exec zkServer.sh start-foreground
        env:
        - name: ZK_REPLICAS
          value: "3"
        - name: JMXAUTH
          value: "false"
        - name: JMXDISABLE
          value: "false"
        - name: JMXPORT
          value: "1099"
        - name: JMXSSL
          value: "false"
        - name: ZK_CLIENT_PORT
          value: "2181"
        - name: ZK_ELECTION_PORT
          value: "3888"
        - name: ZK_HEAP_SIZE
          value: 1G
        - name: ZK_INIT_LIMIT
          value: "5"
        - name: ZK_LOG_LEVEL
          value: INFO
        - name: ZK_MAX_CLIENT_CNXNS
          value: "60"
        - name: ZK_MAX_SESSION_TIMEOUT
          value: "40000"
        - name: ZK_MIN_SESSION_TIMEOUT
          value: "4000"
        - name: ZK_PURGE_INTERVAL
          value: "0"
        - name: ZK_SERVER_PORT
          value: "2888"
        - name: ZK_SNAP_RETAIN_COUNT
          value: "3"
        - name: ZK_SYNC_LIMIT
          value: "10"
        - name: ZK_TICK_TIME
          value: "2000"
        image: gcr.io/google_samples/k8szk:v3
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - zkOk.sh
          failureThreshold: 3
          initialDelaySeconds: 20
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        name: zookeeper
        ports:
        - containerPort: 2181
          name: client
          protocol: TCP
        - containerPort: 3888
          name: election
          protocol: TCP
        - containerPort: 2888
          name: server
          protocol: TCP
        readinessProbe:
          exec:
            command:
            - zkOk.sh
          failureThreshold: 3
          initialDelaySeconds: 20
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/lib/zookeeper
          name: data
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: data
  updateStrategy:
    type: OnDelete
```

Apply the configuration:
```bash
kubectl create -f ./140-zookeeper-statefulset.yml
```

#### Zookeeper PodDisruptionBudget

[PodDisruptionBudget] can help keep the Zookeeper service stable during Kubernetes administrative events such as draining a node or updating Pods.

From the official documentation for PDB ([PodDisruptionBudget]):

> A PDB specifies the number of replicas that an application can tolerate having, relative to how many it is intended to have. For example, a Deployment which has a .spec.replicas: 5 is supposed to have 5 pods at any given time. If its PDB allows for there to be 4 at a time, then the Eviction API will allow voluntary disruption of one, but not two pods, at a time.

The configuration below tells Kubernetes that we can only tolerate one of our Zookeeper Pods down at any given time. **maxUnavailable** may be set to a higher number if we increase the number of Zookeeper Pods in the StatefulSet.

Create the file `150-zookeeper-disruptionbudget.yml`:
```yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  labels:
    app: kafka-zookeeper
  name: kafka-zookeeper
  namespace: the-project
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: kafka-zookeeper
```

Apply the configuration:
```bash
kubectl create -f ./150-zookeeper-disruptionbudget.yml
```

### Kafka

Once [Zookeeper] is up and running we have satisfied the requirements for Kafka. Kafka is set up in a similar configuration to Zookeeper, utilizing a [Service], Headless Service and a [StatefulSet].

#### Kafka Service

The following [Service] provides a persistent internal Cluster IP address that proxies and load balance requests to Kafka Pods found with the label **app: kafka** and exposing the port **9092**.

Create the file `210-kafka-service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: the-project
spec:
  ports:
  - name: broker
    port: 9092
    protocol: TCP
    targetPort: kafka
  selector:
    app: kafka
  sessionAffinity: None
  type: ClusterIP

```

Apply the configuration:
```bash
kubectl create -f ./210-kafka-service.yml
```

#### Kafka Headless Service

The following Headless [Service] provides a list of Pods and their internal IPs found with the label **app: kafka** and exposing the port **9092**. The previously created Service: **kafka** always returns a persistent IP assigned at the creation time of the Service. The following **kafka-headless** services return the domain names and IP address of individual Pods and are liable to change as Pods are added, removed or updated.

Create the file `210-kafka-service-headless.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-headless
  namespace: the-project
spec:
  clusterIP: None
  ports:
  - name: broker
    port: 9092
    protocol: TCP
    targetPort: 9092
  selector:
    app: kafka
  sessionAffinity: None
  type: ClusterIP

```

Apply the configuration:
```bash
kubectl create -f ./210-kafka-service-headless.yml
```

#### Kafka StatefulSet

The following [StatefulSet] deploys Pods running the **confluentinc/cp-kafka:4.1.2-2** Docker image from [Confluent].

Each pod is assigned **1Gi** of storage using the rook-block [storage class]. See [Rook.io](https://rook.io/) for more information on file, block, and object storage services for cloud-native environments.

Create the file `240-kafka-statefulset.yml`:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: kafka
  name: kafka
  namespace: the-project
spec:
  podManagementPolicy: OrderedReady
  replicas: 3
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: kafka
  serviceName: kafka-headless
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - command:
        - sh
        - -exc
        - |
          unset KAFKA_PORT && \
          export KAFKA_BROKER_ID=${HOSTNAME##*-} && \
          export KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://${POD_IP}:9092 && \
          exec /etc/confluent/docker/run
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: KAFKA_HEAP_OPTS
          value: -Xmx1G -Xms1G
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: kafka-zookeeper:2181
        - name: KAFKA_LOG_DIRS
          value: /opt/kafka/data/logs
        - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
          value: "3"
        - name: KAFKA_JMX_PORT
          value: "5555"
        image: confluentinc/cp-kafka:4.1.2-2
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - sh
            - -ec
            - /usr/bin/jps | /bin/grep -q SupportedKafka
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        name: kafka-broker
        ports:
        - containerPort: 9092
          name: kafka
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          tcpSocket:
            port: kafka
          timeoutSeconds: 5
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /opt/kafka/data
          name: datadir
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 60
  updateStrategy:
    type: OnDelete
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: rook-block
```

Apply the configuration:
```bash
kubectl create -f ./240-kafka-statefulset.yml
```

#### Kafka Test Pod

Add a test Pod to help explore and debug your new Kafka cluster. The Confluent Docker image **confluentinc/cp-kafka:4.1.2-2** used for the test Pod is the same as our nodes from the StatefulSet and contain useful command in the **/usr/bin/** folder.

Create the file `400-pod-test.yml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kafka-test-client
  namespace: the-project
spec:
  containers:
  - command:
    - sh
    - -c
    - exec tail -f /dev/null
    image: confluentinc/cp-kafka:4.1.2-2
    imagePullPolicy: IfNotPresent
    name: kafka
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File

```

Apply the configuration:
```bash
kubectl create -f ./400-pod-test.yml
```
## Working with Kafka

If you have deployed the **kafka-test-client** pod from the configuration above, the following commands should get you started with some basic operations:

### List Topics

```bash
kubectl -n the-project exec kafka-test-client -- \
/usr/bin/kafka-topics --zookeeper kafka-zookeeper:2181 --list
```

### Create Topic

```bash
kubectl -n the-project exec kafka-test-client -- \
/usr/bin/kafka-topics --zookeeper kafka-zookeeper:2181 \
--topic test --create --partitions 1 --replication-factor 1
```

### Listen on a Topic

```bash
kubectl -n the-project exec -ti kafka-test-client -- \
/usr/bin/kafka-console-consumer --bootstrap-server kafka:9092 \
--topic test --from-beginning
```


[Kafka]: https://kafka.apache.org/
[helm]: https://helm.sh/
[incubator/kafka]: https://github.com/helm/charts/tree/master/incubator/kafka
[Zookeeper]:https://zookeeper.apache.org/
[auto scaling]:https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
[namespace]:https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[Production Hobby Cluster]:https://imti.co/hobby-cluster/
[StatefulSet]:https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
[PodDisruptionBudget]:https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
[Confluent]:https://www.confluent.io/
[storage class]:https://kubernetes.io/docs/concepts/storage/storage-classes/