---
layout:     post
title:      "Production Grade Elasticsearch on Kubernetes"
subtitle:   "Setup a fast, custom production grade Elasticsearch cluster."
date:       2018-07-14
author:     "Craig Johnston"
URL:        "kubernetes-production-elasticsearch/"
image:      "/img/post/nav.jpg"
twitter_image: "/img/post/nav_876_438.jpg?card"
tags:
- Kubernetes
- Elasticsearch
- Data
series:
- Kubernetes
---

Installing production ready, Elasticsearch 6.2 on Kubernetes requires a hand full of simple configurations. The following guide is a high-level overview of an installation process using Elastic's [recommendations for best practices]. The Github project [kubernetes-elasticsearch-cluster] is used for the Elastic Docker container and built to operate Elasticsearch with nodes dedicated as Master, Data, and Client/Ingest.

The Docker container [docker-elasticsearch], a "Ready to use, lean and highly configurable Elasticsearch container image." by [pires] is sufficient for use in this guide. However, the [txn2/k8s-es] wraps it with a few minor preset environment variables to simplify configuration. I use the docker image [txn2/k8s-es:v6.2.3] in the examples below.

The Github repository [kubernetes-elasticsearch-cluster] contains detailed documentation and configuration for using [docker-elasticsearch] with Kubernetes.

If you need to set up a quick, yet custom production grade cluster, check out my article [Production Hobby Cluster] to get you started.

{{< toc >}}

{{< content-ad >}}

### Project [Namespace]

In the examples below I'll use the namespace **the-project** for all the configurations. The file names are suggestions and may be adjusted to your standards.

`00-namespace.yml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: the-project
  labels:
    env: dev
```

Create the namespace:
```bash
kubectl create -f 00-namespace.yml
```

### [RBAC] for Access and Security

Your Kubernetes cluster should be set up to use [RBAC]. If you are just getting started, you may want to set up a [permissive RBAC] implementation for your development cluster.

This [RBAC] step is optional and only intended as a suggestion for tighter security. If you have [permissive RBAC] there is no need to create this configuration now, as the following steps do not require it.

Creating a [ServiceAccount] called `sa-elasticsearch` for Elasticsearch in `the-project` namespace.

```bash
kubectl create serviceaccount sa-elasticsearch -n the-project
```

Next, create a [Role and RoleBinding] for the new `sa-elasticsearch` [ServiceAccount], it makes sense to group tease in the same configuration file.

`10-rbac.yml`
```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: elasticsearch
  namespace: the-project
  labels:
    env: dev
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: elasticsearch
  namespace: the-project
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: elasticsearch
subjects:
- kind: ServiceAccount
  name: sa-elasticsearch
  namespace: the-project
```

Create the [Role and RoleBinding]:
```bash
kubectl create -f 10-rbac.yml
```

### [Services] for Communication

You need  Kubernetes [Services] for each of the Elasticsearch node types, Master, Data and Ingest. [Services] are a persistent communication bridge to a [Pod]. Because Services use [selectors] to find the appropriate [Pod], they are up first. [Services] are accustomed to Pods coming and going, and route to them when they are available, this happens once we add Deployments further down.

Combine all three Services in the same configuration file to keep things simple.

`20-services.yml`:
```yaml
---
apiVersion: v1
kind: Service
metadata:
  namespace: the-project 
  name: elasticsearch
  labels:
    env: dev
spec:
  type: ClusterIP
  selector:
    app: elasticsearch-client
  ports:
  - name: http
    port: 9200
    protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  namespace: the-project 
  name: elasticsearch-data
  labels:
    env: dev
spec:
  clusterIP: None
  selector:
    app: elasticsearch-data
  ports:
  - port: 9300
    name: transport
---
apiVersion: v1
kind: Service
metadata:
  namespace: the-project 
  name: elasticsearch-discovery
  labels:
    env: dev
spec:
  selector:
    app: elasticsearch-master
  ports:
  - name: transport
    port: 9300
    protocol: TCP
```

### [StatefulSet] for [Data] nodes

Next, we configure a Kubernetes [StatefulSet] to manage our Elasticsearch **[Data]** nodes ([Pods][Pod]). A [StatefulSet] "manages the deployment and scaling of a set of Pods, and provides guarantees about the ordering and uniqueness of these Pods."

Since a Kubernetes [Deployment] creates [ReplicaSets] and not [StatefulSet], we need to create a [StatefulSet] directly for the Elasticsearch **[data]** nodes. The **[Master]** and **[Ingest]** nodes use [Deployment]s which automatically generate [ReplicaSets] for them.

`30-statefulset-data.yml`:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch-data
  namespace: the-project
  labels:
    app: elasticsearch-data
    env: dev
spec:
  serviceName: elasticsearch-data
  replicas: 1 # scale when desired
  selector:
    matchLabels:
      app: elasticsearch-data
  template:
    metadata:
      labels:
        app: elasticsearch-data
    spec:
      initContainers:
      - name: init-sysctl
        image: busybox:1.27.2
        command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        securityContext:
          privileged: true
      containers:
      - name: elasticsearch-data
        image: txn2/k8s-es:v6.2.3
        imagePullPolicy: Always
        env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: DISCOVERY_SERVICE
          value: elasticsearch-discovery
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_DATA
          value: "true"
        - name: NODE_MASTER
          value: "false"
        - name: NODE_INGEST
          value: "false"
        - name: HTTP_ENABLE
          value: "false"
        - name: ES_JAVA_OPTS
          value: -Xms256m -Xmx256m
        - name: PROCESSORS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
        resources:
          limits:
            cpu: 1
        ports:
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: elasticsearch-data-storage
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-data-storage
    spec:
      storageClassName: rook-block
      accessModes: [ ReadWriteOnce ]
      resources:
        requests:
          storage: 2Gi # small for dev / testing
```

### [Deployment] for [Master] Nodes

The **[Master]** Elasticsearch nodes are "responsible for lightweight cluster-wide actions such as creating or deleting an index, tracking which nodes are part of the cluster, and deciding which shards to allocate to which nodes. It is important for cluster health to have a stable master node."

`40-deployment-master.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch-master
  namespace: the-project
  labels:
    app: elasticsearch-master
    env: dev
spec:
  replicas: 2 # scale as desired (see NUMBER_OF_MASTERS below)
  selector:
    matchLabels:
      app: elasticsearch-master
  template:
    metadata:
      labels:
        app: elasticsearch-master
        env: dev
    spec:
      initContainers:
      - name: init-sysctl
        image: busybox:1.27.2
        command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        securityContext:
          privileged: true
      containers:
      - name: elasticsearch-master
        image: txn2/k8s-es:v6.2.3
        imagePullPolicy: Always
        env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: DISCOVERY_SERVICE
          value: elasticsearch-discovery
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NUMBER_OF_MASTERS
          value: "2"
        - name: NODE_MASTER
          value: "true"
        - name: NODE_INGEST
          value: "false"
        - name: NODE_DATA
          value: "false"
        - name: HTTP_ENABLE
          value: "false"
        - name: ES_JAVA_OPTS
          value: -Xms256m -Xmx256m
        - name: PROCESSORS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
        resources:
          limits:
            cpu: 1
        ports:
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: storage
          mountPath: /data
      volumes:
      - emptyDir:
          medium: ""
        name: "storage"
```

### [Deployment] for Client and [Ingest] Nodes

For the sake of simplicity, we use our **client** nodes for [ingest] and queries. These can easily be separated out once you have determined your load model. Separate **[Ingest]** nodes allow you to "pre-process documents before the actual document indexing happens. The ingest node intercepts bulk and index requests, it applies transformations, and it then passes the documents back to the index or bulk APIs." By default, Elasticsearch nodes allow [ingest], so clients remain in this default mode.

`60-deployment-client.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch-client
  namespace: the-project
  labels:
    app: elasticsearch-client
    env: dev
spec:
  replicas: 1 # scale as desired
  selector:
    matchLabels:
      app: elasticsearch-client
  template:
    metadata:
      labels:
        app: elasticsearch-client
        env: dev
    spec:
      initContainers:
      - name: init-sysctl
        image: busybox:1.27.2
        command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        securityContext:
          privileged: true
      containers:
      - name: elasticsearch-client
        image: txn2/k8s-es:v6.2.3
        imagePullPolicy: Always
        env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: DISCOVERY_SERVICE
          value: elasticsearch-discovery
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_MASTER
          value: "false"
        - name: NETWORK_HOST
          value: "0.0.0.0"
        - name: NODE_INGEST
          value: "true"
        - name: NODE_DATA
          value: "false"
        - name: HTTP_ENABLE
          value: "true"
        - name: ES_JAVA_OPTS
          value: -Xms256m -Xmx256m
        - name: PROCESSORS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
        resources:
          limits:
            cpu: 1
        ports:
        - containerPort: 9200
          name: http
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: storage
          mountPath: /data
      volumes:
      - emptyDir:
          medium: ""
        name: "storage"
```

### Testing

Use `kubectl exec` to open a terminal into a Pod in `the-project` namespace and use `curl` to test the new Elasticsearch cluster.

```bash
kubectl exec -it SOME_POD sh -n the-project 
```

Retrieve Elasticsearch cluster stats:

```bash
curl -X GET "elasticsearch:9200/_cluster/stats?human&pretty"
```

Example output:

```json
{
  "_nodes" : {
    "total" : 4,
    "successful" : 4,
    "failed" : 0
  },
  "cluster_name" : "elasticsearch",
  "timestamp" : 1531724609367,
  "status" : "green",
  "indices" : {
    "count" : 0,
    "shards" : { },
    "docs" : {
      "count" : 0,
      "deleted" : 0
    },
    "store" : {
      "size" : "0b",
      "size_in_bytes" : 0
    },
    "fielddata" : {
      "memory_size" : "0b",
      "memory_size_in_bytes" : 0,
      "evictions" : 0
    },
    "query_cache" : {
      "memory_size" : "0b",
      "memory_size_in_bytes" : 0,
      "total_count" : 0,
      "hit_count" : 0,
      "miss_count" : 0,
      "cache_size" : 0,
      "cache_count" : 0,
      "evictions" : 0
    },
    "completion" : {
      "size" : "0b",
      "size_in_bytes" : 0
    },
    "segments" : {
      "count" : 0,
      "memory" : "0b",
      "memory_in_bytes" : 0,
      "terms_memory" : "0b",
      "terms_memory_in_bytes" : 0,
      "stored_fields_memory" : "0b",
      "stored_fields_memory_in_bytes" : 0,
      "term_vectors_memory" : "0b",
      "term_vectors_memory_in_bytes" : 0,
      "norms_memory" : "0b",
      "norms_memory_in_bytes" : 0,
      "points_memory" : "0b",
      "points_memory_in_bytes" : 0,
      "doc_values_memory" : "0b",
      "doc_values_memory_in_bytes" : 0,
      "index_writer_memory" : "0b",
      "index_writer_memory_in_bytes" : 0,
      "version_map_memory" : "0b",
      "version_map_memory_in_bytes" : 0,
      "fixed_bit_set" : "0b",
      "fixed_bit_set_memory_in_bytes" : 0,
      "max_unsafe_auto_id_timestamp" : -9223372036854775808,
      "file_sizes" : { }
    }
  },
  "nodes" : {
    "count" : {
      "total" : 4,
      "data" : 1,
      "coordinating_only" : 0,
      "master" : 2,
      "ingest" : 1
    },
    "versions" : [
      "6.2.3"
    ],
    "os" : {
      "available_processors" : 22,
      "allocated_processors" : 4,
      "names" : [
        {
          "name" : "Linux",
          "count" : 4
        }
      ],
      "mem" : {
        "total" : "37.1gb",
        "total_in_bytes" : 39837057024,
        "free" : "8.4gb",
        "free_in_bytes" : 9092431872,
        "used" : "28.6gb",
        "used_in_bytes" : 30744625152,
        "free_percent" : 23,
        "used_percent" : 77
      }
    },
    "process" : {
      "cpu" : {
        "percent" : 0
      },
      "open_file_descriptors" : {
        "min" : 173,
        "max" : 179,
        "avg" : 175
      }
    },
    "jvm" : {
      "max_uptime" : "1.7h",
      "max_uptime_in_millis" : 6414192,
      "versions" : [
        {
          "version" : "1.8.0_151",
          "vm_name" : "OpenJDK 64-Bit Server VM",
          "vm_version" : "25.151-b12",
          "vm_vendor" : "Oracle Corporation",
          "count" : 4
        }
      ],
      "mem" : {
        "heap_used" : "418.3mb",
        "heap_used_in_bytes" : 438676024,
        "heap_max" : "990mb",
        "heap_max_in_bytes" : 1038090240
      },
      "threads" : 79
    },
    "fs" : {
      "total" : "533gb",
      "total_in_bytes" : 572367089664,
      "free" : "498.7gb",
      "free_in_bytes" : 535527632896,
      "available" : "471.5gb",
      "available_in_bytes" : 506362122240
    },
    "plugins" : [ ],
    "network_types" : {
      "transport_types" : {
        "netty4" : 4
      },
      "http_types" : {
        "netty4" : 4
      }
    }
  }
}
```

## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

### Next

- Setup [Kibana on Kubernetes] for data exploration and visualization.
- Process [High Traffic JSON Data into Elasticsearch on Kubernetes].

[Kibana on Kubernetes]:/kibana-kubernetes/
[High Traffic JSON Data into Elasticsearch on Kubernetes]:/post-json-elasticsearch-kubernetes/
[recommendations for best practices]: https://www.elastic.co/guide/en/elasticsearch/reference/6.2/modules-node.html
[kubernetes-elasticsearch-cluster]: https://github.com/pires/kubernetes-elasticsearch-cluster
[txn2/k8s-es]:https://github.com/txn2/k8s-es
[txn2/k8s-es:v6.2.3]:https://hub.docker.com/r/txn2/k8s-es/tags/
[pires]:https://github.com/pires
[docker-elasticsearch]:https://github.com/pires/docker-elasticsearch
[permissive RBAC]:/hobby-cluster/#permissions-rbac-role-based-access-control
[Production Hobby Cluster]:/hobby-cluster/
[ServiceAccount]:/team-kubernetes-remote-access/#serviceaccount
[Role and RoleBinding]:/team-kubernetes-remote-access/#role-and-rolebinding
[Services]:https://kubernetes.io/docs/concepts/services-networking/service/
[Pod]:https://kubernetes.io/docs/concepts/workloads/pods/pod/
[selectors]:https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
[StatefulSet]:https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[ReplicaSets]:https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[Data]: https://www.elastic.co/guide/en/elasticsearch/reference/6.2/modules-node.html#data-node
[Master]: https://www.elastic.co/guide/en/elasticsearch/reference/6.2/modules-node.html#master-node
[Ingest]: https://www.elastic.co/guide/en/elasticsearch/reference/6.2/ingest.html
[RBAC]:https://kubernetes.io/docs/reference/access-authn-authz/rbac/
[Namespace]:https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/