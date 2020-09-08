---
layout:     post
title:      "Microservices & Kubernetes"
subtitle:   "Overview"
date:       2018-03-24
author:     "Craig Johnston"
URL:        "microservices/"
image:      "/img/post/cars.jpg"
twitter_image: "/img/post/cars_876_438.jpg"
tags:
- Kubernetes
- Microservices
series:
- Kubernetes
---

The following is a collection of articles, videos, and notes on [Microservices]. The [Microservices] architecture is a variant of the [service-oriented architecture] (SOA), a collection of loosely coupled services.

{{< content-ad >}}

## Articles
- Background concept - ["Open Data: Small Pieces Loosely Joined"](http://radar.oreilly.com/2006/09/open-data-small-pieces-loosely.html), Tim O’Reilly
- Modern software design problems and solutions - ["12-Fractured Apps"](https://medium.com/@kelseyhightower/12-fractured-apps-1080c73d481c), Kelsey Hightower (SysAdmin @ Google)
- 12-Factor Defined - ["The 12-Factor App"](https://12factor.net/), Adam Wiggins
- Pros and Cons of Microservices - ["Microservices"](https://martinfowler.com/articles/microservices.html) and [Microservice Trade-Offs](https://martinfowler.com/articles/microservice-trade-offs.html), Martin Fowler
- ["What are containers and why do you need them?"](https://www.cio.com/article/2924995/software/what-are-containers-and-why-do-you-need-them.html) - CIO
- ["Containers bring a skinny new world of virtualization to Linux"](http://www.itworld.com/article/2698646/virtualization/containers-bring-a-skinny-new-world-of-virtualization-to-linux.html) - ITWorld

## Videos
- ["Microservices"](https://www.youtube.com/watch?v=wgdBVIX9ifA), Martin Fowler
- ["The Evolution of Microservices"](http://www.ustream.tv/recorded/86151804), Martin Fowler
- ["The State of the Art in Microservices"](https://www.youtube.com/watch?v=pwpxq9-uw_0) with Docker, Adrian Cockroft

## Notes

#### Key Goals of Microservices
- Rapid development
- Continuous deployment

#### Best Practices
- [Version Control](https://12factor.net/codebase) - All code and **configuration** should be versioned.
- [Log to Standard Out](https://12factor.net/logs) - This unifies the log collection process.
- [Package Dependencies](https://12factor.net/dependencies) - Ensure the stability of the build process.

#### Twelve-Factor Principles
- Portable - Service (container) should be able to be run anywhere.
- Continually Deployable - Able to deploy any time without disruption.
- Scalable - Multiple copies should be able to run concurrently (stateless)

#### JSON Web Tokens (JWT) - Client -> Server trust.
- Compact, self-contained method for transferring secure data as a JSON object.
- Use for Authentication and Information Exchange
- See [https://jwt.io/](https://jwt.io/)
- A server creates a token, and the client uses token to make requests.

#### Containers - Docker
- Docker is simply an API on top of existing process isolation technology.
- Independent packages
- Namespace Isolation

#### Alpine Linux
[Alpine Linux](https://alpinelinux.org/) **Small. Simple. Secure.** Alpine Linux is a security-oriented, lightweight Linux distribution based on musl libc and busybox.
- [Alpine container image](https://hub.docker.com/_/alpine/)
- [Docker gets minimalist with plan to migrate images to Alpine Linux](http://siliconangle.com/blog/2016/02/09/docker-gets-minimalist-with-plan-to-migrate-images-to-alpine-linux/)
- [Solomon Hykes, founder and CTO of Docker (on the move to Alpine)](https://news.ycombinator.com/item?id=11000827)

We can demonstrate using an Alpine Linux container by executing the `echo` command included with Alpine: `docker run --rm alpine echo "hello"`. This command pulls the Alpine container if you don't already have it. Since the `echo` command completes after echoing its message, there is nothing else to do and the container ceases execution and remains in a stopped state. However, the `--rm` flag removes the container after it runs, this means you won't end up with a bunch of useless stopped containers after running it multiple times.

## Kubernetes

I use [Minikube] to play with and test helm on my mac laptop. [Minikube] is a great way to learn and experiment with [Kubernetes] without disrupting a production cluster, or having to setup a custom cluster in your datacenter or in the cloud.

### Minikube

In order to follow the examples below you will need to [Install Minikube] and it's dependencies. The command [kubectl] is used to interact with the [kubernetes] cluster.

- Version: `minikube version`

```
minikube version: v0.25.2
```
- Status: `minikube status`

```
minikube: Stopped
cluster:
kubectl:
```
- Start: `minikube start`

```bash
Starting local Kubernetes v1.9.4 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Downloading localkube binary
 163.02 MB / 163.02 MB [============================================] 100.00% 0s
 0 B / 65 B [----------------------------------------------------------]   0.00%
 65 B / 65 B [======================================================] 100.00% 0sSetting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
```
- Addons: `minikube addons list`
- Enable Heapster: `minikube addons enable heapster` to provide CPU and memory usage in the dashboard.

```plain
heapster was successfully enabled
```
- Dashboard: `minikube dashboard`
- Kubernetes cluster status: `kubectl cluster-info`
- Kubernetes nodes in the cluster: `kubectl get nodes`

### Kubernetes: Using Kubernetes

Deployments keep containers running in Pods, even when nodes fail. Create a simple deployment, in this case using the cjimti/go-ok container:

```bash
kubectl run go-ok --image=cjimti/go-ok
```
The `kubectl run` command gave us a **Deployment**, **Pod** and **Replica Set** to support our go-ok container.

In the [Dashboard] you can see the running deployment, pod and replica set. Run `minikube dashboard` to bring it up in a web browser.

![k8s dashboard go-ok](/images/k8s-dashboard.jpg)


#### [Deployments]

List the [deployments] in the cluster (default namespace):
```
kubectl get deployments
```

```plain
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
go-ok     1         1         1            1           2m
```

Get the yaml configuration of the deployment
```bash
kubectl get deployment -o yaml
```
<script src="https://gist.github.com/cjimti/ee9de951e0efececa14432a3b82d8315.js"></script>

#### [Pods]

List all pods on the cluster (default namespace):
```bash
kubectl get pods
```
```plain
NAME                     READY     STATUS    RESTARTS   AGE
go-ok-5bc6b8bf6c-sltjk   1/1       Running   0          12m
```
Get the yaml configuration of the Pod:
```bash
kubectl get pod go-ok-5bc6b8bf6c-sltjk -o yaml
```
<script src="https://gist.github.com/cjimti/530022b6b9cd57db86dff67419f13044.js"></script>

#### [Replica Sets]

> While [ReplicaSets] can be used independently, today it’s mainly used by [Deployments] as a mechanism to orchestrate pod creation, deletion and updates. When you use [Deployments] you don’t have to worry about managing the [ReplicaSets] that they create. Deployments own and manage their [ReplicaSets].


List all [Replica Sets] in the cluster (default namespace):
```bash
kubectl get rs
```
```plain
NAME               DESIRED   CURRENT   READY     AGE
go-ok-5bc6b8bf6c   1         1         1         20m
```
Get the yaml configuration of the Replica Set:
```
kubectl get rs go-ok-5bc6b8bf6c -o yaml
```
<script src="https://gist.github.com/cjimti/97e22b3b779764e8f199d22f565f6a17.js"></script>


#### Expose A Container [Services]

We expose the container with the following:
```bash
kubectl expose deployments go-ok --port 8080 --type NodePort
```
```plain
kubectl get services
```
Use the type NodePort with Minikube. Since we are not on a cloud provider and so unable to use the LoadBalancer type.

> If you set the type field to "NodePort", the Kubernetes master will allocate a port from a flag-configured range (default: 30000-32767), and each Node will proxy that port (the same port number on every  Node) into your Service.

The `go-ok` container listens on it's own port 8080. We ask kubernetes to assign a random port number that will route to a running `go-ok` container to it's port 8080.

List all the services on the cluster (default namespace):
```bash
kubectl get services
```
```plain
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
go-ok        NodePort    10.110.158.111   <none>        8080:32414/TCP   3m
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          24d
```

The go-ok services is now running on port 32414 as is seen in the PORT(S) column: `8080:32414/TCP`

Get the yaml configuration of the service:
```bash
kubectl get service go-ok -o yaml
```
<script src="https://gist.github.com/cjimti/bfb8cc086f9ff122910f1a9411d0be3f.js"></script>

The service is now viewable in the [Dashboard]:
![k8s services dashboard go-ok](/images/k8s-kubernetes-dashboard-services.jpg)


#### Architecture Overview: Deployments

[Deployments] contain [ReplicaSets] which contain [Pods] and [Services]. A good visual illustration of this is in the [Dashboard]:

**Deployment Details**
![k8s dashboard deployment details](/images/k8s-deploument-details.jpg)

**Replica Set Details**
![k8s dashboard replica set details](images/k8s-dashboard-replicaset-details.jpg)

## More on [Pods]

A [Pod] represent a Logical Application. An example application would be some API service or backend webserver and an nginx container, these would run together on a [Pod].

Pods:
- One ore more containers and volumes
- Shared namespaces
- One IP per pod

Manually port forward to a container (on the local network interface):
`kubectl port-forward go-ok-5bc6b8bf6c-sltjk 10080:8080`

## [Secrets] & [Config Maps]

Creating a [Secret].
```bash
kubectl create secret generic tls-certs --from-file=tls
```
```bash
kubectl describe secrets tls-certs
```

Creating a [Config Map].
```bash
kubctl create configmap nginx-proxy-conf --from-file nginx/proxy.conf
```
```bash
kubectp describe configmap nginx-proxy-conf
```

## Declare a [Pod]

Create a `pod.yml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: go-ok
  labels:
    app: go-ok-app
    purpose: example
spec:
  containers:
    - name: go-ok
      image: cjimti/go-ok:v1
      imagePullPolicy: Always
      env:
        - name: PORT
          value: "80"
        - name: GIN_MODE
          value: "release"
      ports:
        - name: http
          containerPort: 80
```

Create the [Pod]:
```bash
kubectl create -f ./pod.yml
```

Get a list of [Pods] using a label selectors:
```bash
kubectl get pods -l app=go-ok-app
```
or
```bash
kubectl get pods -l app=go-ok-app,purpose=example
```
``plain
NAME      READY     STATUS    RESTARTS   AGE
go-ok     1/1       Running   0          3m
```

Add a label to a running [Pod]:
```bash
kubectl label pods go-ok owner=cjimti
```

Delete the pod created from `pod.yaml` as easily as creating it with:
```bash
kubectl delete -f pod.yml
```

Re-create the [Pod] if you are following along.

## [Services]

[Services] are persisten endpoints for [Pods].
- Use [Labels] to select [Pods]
- Internal or External IPs

Create a [Service] using a [Selector]:

`service.yml`:
~~~ yaml
apiVersion: v1
kind: Service
metadata:
  name: "go-ok"
spec:
  selector:
    app: "go-ok"
    purpose: "example"
  ports:
    - protocol: "TCP"
      port: 80
      targetPort: 80
      nodePort: 31000 //port exposed on the node (cluster)
  type: NodePort
~~~

List the service created with the config:
```bash
kubectl get -f service.yml
```

## [Ingress] Controller

Exposing external traffic to our service is done through an [Ingress] controller. Check out [Setting up Nginx Ingress on Kubernetes] for a detailed how-to and also a good write up on [Ingress] itself on Medium: [Kubernetes Ingress]

> Traditionally, you would create a LoadBalancer service for each public system you want to expose. This can get rather expensive. Ingress gives you a way to route requests to services based on the request host or path, centralizing a number of services into a single entrypoint. --[Kubernetes Ingress]

Since I am using [Minikube] on my local workstation I am going to add the domain `local.imti.cloud` to my `/etc/hosts` file and resolve it to the Minikube IP.

Get the Minikube IP:
```bash
minikube status
```

```plain
minikube: Running
cluster: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.99.100
```

My `/etc/hosts' entry should be `192.168.99.100  local.imti.cloud`. Browsing to [http://local.imti.cloud:30000/](http://local.imti.cloud:30000/) will now give me the [dashboard] for my [Minikube] cluster.


### Ingress Resources

- Official [Kubernetes Ingress] Documentation
- [Setting up Nginx Ingress on Kubernetes]
- [Pain(less) NGINX Ingress](http://danielfm.me/posts/painless-nginx-ingress.html)
- [Kubernetes nginx-ingress-controller](https://daemonza.github.io/2017/02/13/kubernetes-nginx-ingress-controller/)

## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

---
[Setting up Nginx Ingress on Kubernetes]: https://hackernoon.com/setting-up-nginx-ingress-on-kubernetes-2b733d8d2f45
[Config Map]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
[Kubernetes Ingress]: https://medium.com/@cashisclay/kubernetes-ingress-82aa960f658e
[Ingress]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[kubectl]: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
[Config Maps]: http://kubernetes.io/docs/user-guide/configmap/
[Secret]: http://kubernetes.io/docs/user-guide/secrets/
[Secrets]: http://kubernetes.io/docs/user-guide/secrets/
[Labels]: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
[Selector]: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
[Labels and Selectors]: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[Services]: https://kubernetes.io/docs/concepts/services-networking/service/
[Replica Sets]: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[Replica Set]: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[ReplicaSets]: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[Pods]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Pod]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[Deployments]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[Dashboard]: https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
[Install Minikube]: https://kubernetes.io/docs/tasks/tools/install-minikube/
[Microservices]: https://en.wikipedia.org/wiki/Microservices
[service-oriented architecture]: https://en.wikipedia.org/wiki/Service-oriented_architecture
[Kubernetes]: https://kubernetes.io/
[Minikube]: https://kubernetes.io/docs/getting-started-guides/minikube/
