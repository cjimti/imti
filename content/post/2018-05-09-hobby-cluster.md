---
layout:     post
title:      "Production Hobby Cluster"
subtitle:   "Production-grade cluster on a hobby budget."
date:       2018-05-09
author:     "Craig Johnston"
URL:        "hobby-cluster/"
image:      "/img/post/armor.jpg"
twitter_image: "/img/post/armor_876_438.jpg"
tags:
- Kubernetes
series:
- Kubernetes
---

Setting up a production-grade Kubernetes cluster can be done on a hobby budget, and if this is true why mess around with a lesser grade. If you are investing time to learn distributed cloud computing or microservices, is the distance between $0 and **15 dollars a month** worth the time in translating best practices? Kubernetes is designed to host production applications. My personal web applications may only be hobbies, but they might as well be production grade hobbies. 

[![k8s performance hobby clusters](/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)

{{< toc >}}

## Motivation

I have read my thousandth tutorial on how to do things the wrong way; well, the not-good-for-production-way, you know for "learning." The following are my notes as I unlearn the "not for production" tutorial way and re-apply my production notes to a 15 dollar-a-month production grade hobby way.

In this article, I'll be using three $5 servers from [Vultr] (referral link). 
There are a handful of cheap cloud providers these days, and in keeping competitive, they keep getting cheaper and better. Another good pick is [Digital Ocean]. You might want to run a [Vultr] cluster in LA with a set of services and a [Digital Ocean] cluster in New York with another set of services.

For my 15 dollars a month I am getting three 1 vCore, 1G ram and 25G of storage each. I host application primarily written in Go and Python, and they make very efficient use of their resources.

## Infrastructure

Start with three **[Ubuntu 18.04 x64][vultr]** boxes of 1 vCore, 1G ram and 25G of storage each in Los Angeles (because I work in Los Angeles).

I am calling my new servers lax1, lax2, and lax3.

### Security

I don't need my hobby cluster turning into a [crypto-mining platform while I sleep](https://news.bitcoin.com/hackers-target-400000-computers-with-mining-malware/).

#### Firewall

[ufw](https://help.ubuntu.com/community/UFW) makes easy work of security. Fine-grained `iptables` rules are nice (and 
complicated, and easy to get wrong) but `ufw` is just dead-simple, and it's production grade security since it's just 
wrapping more complicated `iptables` rules.

Login to the box and setup security:

<script src="https://gist.github.com/cjimti/4088e76e5016202a8da93fd041dd9fae.js"></script>

```bash
# you can run the gist above directly if you wish
curl -L https://git.io/vpDYI | sh

# enable the firewall
ufw enable
```

### Swap

[Only move stuff to SWAP when you are completely OUT of RAM.](https://askubuntu.com/questions/259739/kswapd0-is-taking-a-lot-of-cpu?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa)

Run the following on each server:

```bash
echo vm.swappiness=0 | sudo tee -a /etc/sysctl.conf
```

### VPN

[WireGuard] is the VPN I use for cluster communication security. [Install WireGuard](https://www.wireguard.com/install/) 
by following their instructions for Ubuntu below:

<script src="https://gist.github.com/cjimti/3402964e0a2a89c076f9fb0430028dff.js"></script>

```bash
# run each command manually or pipe the gist to sh
curl -L https://git.io/vpDYE | sh
```

Although according to the documentation it's okay to run [WireGuard] over the public interface; if your host allows it, you might as well set up a private network. On [Vultr] it is as simple as checking a box setup or clicking on "Add Private Network" in the server settings. However on [Vultr] servers you need to add the new private network interface manually, this is not the case with [Digital Ocean]:

In `/etc/netplan/10-ens7.yaml` add the following lines (replace 10.99.0.200/16 with the assigned private IP and range):
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens7:
      mtu: 1450
      dhcp4: no
      addresses: [10.5.96.4/20]
```

In my case, the subnet mask is 255.255.240.0 which equates to a /20. 
[Check out this cheat sheet for a quick IP range refrence](https://www.aelius.com/njh/subnet_sheet.html)

Then run the command:

```bash
netplan apply
```

You should now be able to run `ifconfig` and get a new interface like this:

```plain
ens7: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.5.96.3  netmask 255.255.240.0  broadcast 10.5.111.255
        inet6 fe80::5800:1ff:fe7c:d24a  prefixlen 64  scopeid 0x20<link>
        ether 5a:00:01:7c:d2:4a  txqueuelen 1000  (Ethernet)
        RX packets 7  bytes 726 (726.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 2  bytes 176 (176.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

You should be able to ping the private IPs of other servers on the same private network out the new interface, 
in my case **ens7**.

```bash
ping -I ens7 10.5.96.4

PING 10.5.96.4 (10.5.96.4) from 10.5.96.3 ens7: 56(84) bytes of data.
64 bytes from 10.5.96.4: icmp_seq=1 ttl=64 time=1.48 ms
64 bytes from 10.5.96.4: icmp_seq=2 ttl=64 time=0.808 ms
^C
--- 10.5.96.4 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.808/1.144/1.481/0.338 ms
```

**Configuring [WireGuard]**

You will need a public and private key for each server. Here is a simple bash script for generating the key 
pairs all at once (thanks [Hobby Kube](https://github.com/hobby-kube/)]:

<script src="https://gist.github.com/cjimti/d04392fb9c726d4b2612f24599b28251.js"></script>

```bash
# you can run the gist directly with a pipe from curl to sh
curl -L https://git.io/vpDYP |sh
```

Example output
```plain
Server 1 private key: cB8gRedh0f03ndqmQZCbFPL2D9zEyi101kF3xeRRwGI=
Server 1 public key:  BXIF16yXX9F5yR0uYxpAbT1TbDXTsfXH+pi2nQgtz10=
Server 2 private key: OB2rLNluGmM9XlYOErTaZV/hD41dVKX1cH5jl7HV0Gg=
Server 2 public key:  rJd1kLa3Ru51c3bpsPfGZhCfT7sjBtj93nlOKG+oako=
Server 3 private key: qKhwlt8Hhwl+YCvr6cQzvC+ByzySEVpm3WgnAOhHAHk=
Server 3 public key:  7n07YYLqTWxokR8Tg2q2Vs7aGe++5YAhr2fAFz2EVDY=
```

Cut and paste the output somewhere safe as you will need it for configuring each server.

The [WireGuard] VPN Configuration will setup another interface, **wg0** Each server will have a configuration file similar to this:

```bash
# /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.1.1
PrivateKey = <PRIVATE_KEY_KUBE1>
ListenPort = 51820

[Peer]
PublicKey = <PUBLIC_KEY_KUBE2>
AllowedIps = 10.0.1.2/32
Endpoint = 10.8.23.94:51820

[Peer]
PublicKey = <PUBLIC_KEY_KUBE3>
AllowedIps = 10.0.1.3/32
Endpoint = 10.8.23.95:51820
```

You will need to open up the port 51820 on the new private interface for each server. On my new servers, the interface is **ens7** as seen when we ran `ifconfig` above.

```bash
ufw allow in on ens7 to any port 51820
ufw allow in on wg0
ufw reload
```

Next ensure that ip forwarding is enabled. If running `sysctl net.ipv4.ip_forward` returns 0 then you will need to run 
the following commands:

```bash
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf # enable ip4 forwarding
sysctl -p # apply settings from /etc/sysctl.conf
```

To enable the VPN and run on startup, execute the following commands on each server:

```bash
systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0
```

## Kubernetes

### Install Docker

On each server run:

```bash
apt-get install docker.io -y
```

Ensure the proper **DOCKER_OPS** are set by creating the file
`/etc/systemd/system/docker.service.d/10-docker-opts.conf` and adding
the following line:

```plain
Environment="DOCKER_OPTS=--iptables=false --ip-masq=false"
```

You will need to restart Docker and reload daemons:

```bash
systemctl restart docker
systemctl daemon-reload
```

### Install [Etcd] (in cluster mode)

Maunally install version 3.2.13:

```bash
export ETCD_VERSION="v3.2.13"
mkdir -p /opt/etcd
curl -L https://storage.googleapis.com/etcd/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
  -o /opt/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
tar xzvf /opt/etcd-${ETCD_VERSION}-linux-amd64.tar.gz -C /opt/etcd --strip-components=1
```

Creating the systemd unit file `/etc/systemd/system/etcd.service` on each server. We are configuring [Etcd] to communicate 
over our new VPN, so we don't need many of the provided security options.

On our three node cluster, the configuration for lax1 looks like this:

```bash
[Unit]
Description=etcd
After=network.target wg-quick@wg0.service

[Service]
Type=notify
ExecStart=/opt/etcd/etcd --name lax1 \
  --data-dir /var/lib/etcd \
  --listen-client-urls "http://10.0.1.1:2379,http://localhost:2379" \
  --advertise-client-urls "http://10.0.1.1:2379" \
  --listen-peer-urls "http://10.0.1.1:2380" \
  --initial-cluster "lax1=http://10.0.1.1:2380,lax2=http://10.0.1.2:2380,lax3=http://10.0.1.3:2380" \
  --initial-advertise-peer-urls "http://10.0.1.1:2380" \
  --heartbeat-interval 200 \
  --election-timeout 5000
Restart=always
RestartSec=5
TimeoutStartSec=0
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
```

The config key `--initial-cluster` is just the initial cluster. You can quickly add more nodes in the future without modifying this value.

Enable startup and run [Etcd] on each server:

```bash
systemctl enable etcd.service # launch etcd during system boot
systemctl start etcd.service
```

Run the command `journalctl -xe` if you encounter any errors. The first time I started up [etcd], it failed due to a typo.

Check the status of the new [Etcd] cluster:

```bash
/opt/etcd/etcdctl member list

83520a64ae261035: name=lax1 peerURLs=http://10.0.1.1:2380 clientURLs=http://10.0.1.1:2379 isLeader=true
920054c1ee3bca8a: name=lax3 peerURLs=http://10.0.1.3:2380 clientURLs=http://10.0.1.3:2379 isLeader=false
950feae803ed7835: name=lax2 peerURLs=http://10.0.1.2:2380 clientURLs=http://10.0.1.2:2379 isLeader=false
```

### Install Kubernetes

Run the following commands on each server:

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
```

```bash
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
EOF
```

```bash
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
```

#### Initialize the master node

Create the configuration file `/tmp/master-configuration.yml` and
replace PUBLIC_IP_LAX1 with the servers public ip address:

```yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: 10.0.1.1
etcd:
  endpoints:
  - http://10.0.1.1:2379
  - http://10.0.1.2:2379
  - http://10.0.1.3:2379
apiServerCertSANs:
  - <PUBLIC_IP_LAX1>
```

Run the following command on lax1:

```bash
kubeadm init --config /tmp/master-configuration.yml
```

After running `kubeadm init` make sure you copy the output, specifically the `--token`, it will look something like 
this `3b1e9s.t21tgbbyx1yt7lrp`.

Next, we will use [Weave Net] to create a Pod network. [Weave Net] is excellent since it is stable, production ready 
and has no configuration.

Create a `.kube` directory for the current user (in my case root).  `kubectl` will access the local Kubernetes with a 
symlinked config file in the logged-in users home path.

```bash
[ -d $HOME/.kube ] || mkdir -p $HOME/.kube
ln -s /etc/kubernetes/admin.conf $HOME/.kube/config
```

Install [Weave Net]:

```bash
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

Open the firewall for weave:

```bash
ufw allow in on weave
ufw reload
```

Check your rules on each server:

```bash
ufw status

Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
6443                       ALLOW       Anywhere
80                         ALLOW       Anywhere
443                        ALLOW       Anywhere
51820 on eth1              ALLOW       Anywhere
Anywhere on wg0            ALLOW       Anywhere
Anywhere on weave          ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
6443 (v6)                  ALLOW       Anywhere (v6)
80 (v6)                    ALLOW       Anywhere (v6)
443 (v6)                   ALLOW       Anywhere (v6)
51820 (v6) on eth1         ALLOW       Anywhere (v6)
Anywhere (v6) on wg0       ALLOW       Anywhere (v6)
Anywhere (v6) on weave     ALLOW       Anywhere (v6)
```

We need [Weave Net] to route traffic over our VPN. With the following commands, we can set **10.96.0.0/16** 
as an overlay network route for Wireguard.

On each of the servers run the following command replacing the 10.0.1.1 with .2 and .3 to match the server's VPN IP.

```bash
ip route add 10.96.0.0/16 dev wg0 src 10.0.1.1 # .2, .3 etc..
```

Add the [systemd] service unit file `/etc/systemd/system/overlay-route.service` to ensure this network configuration happens on boot.

Make sure to change 10.0.1.1 to 10.0.1.2 and 10.0.1.3 for the corresponding servers.

```bash
[Unit]
Description=Overlay network route for Wireguard
After=wg-quick@wg0.service

[Service]
Type=oneshot
User=root
ExecStart=/sbin/ip route add 10.96.0.0/16 dev wg0 src 10.0.1.1

[Install]
WantedBy=multi-user.target
```

Enable the new service on each node:

```bash
systemctl enable overlay-route.service
```


### Joining the Cluster

Use the token we received after running the `kubeadm init` command in the "Initialize the master node" section above.

```bash
kubeadm join --token=<TOKEN> 10.0.1.1:6443 --discovery-token-unsafe-skip-ca-verification
```

### Permissions: RBAC (Role Based Access Control)

Setup permissive RBAC. A permissive RBAC does not affect a clusters ability to be "production grade" since security models can change based on the requirements of the cluster. You want a secure cluster, and you get that with the security setup in the steps above. What you don't need in a small cluster is a complicated security model. You can add that later.

```bash
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
```

### kubectl: Remote Access

The easiest way to connect to the new cluster is to download and use its configuration file.

```bash
# if you don't have kubectl installed use homebrew (https://brew.sh/) to install it.
brew install kubectl

# on your local workstation
cd ~/.kube
scp root@lax1.example.com:./.kube/config lax1_config
```

Edit the new lax1_config file and change the yaml key **server** under the **cluster** 
section to the location of your server `server: https://lax1.example.com:6443` you may also 
want to change the context name to something more descriptive like **lax1**.

The environment variable **[KUBECONFIG]** holds paths to config files for `kubectl`. In your shell profile 
(`.bash_profile` or `.bashrc`) add:
 
 ```plain
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config:$HOME/.kube/lax1_config
 ```
 
Logging in to a new terminal on your workstation and try switching between contexts
(`kubectl config use-context lax1`):

```bash
# kubectl configuration help
kubectl config -h

# display the configs visible to kubectl
kubectl config view

# get the current context
kubectl config current-context

# use the new lax1 context
kubectl config use-context lax1

# get the list of nodes from lax
kubectl get nodes

```


### Deploy an Application

Create a file called `tcp-echo-service.yml`

<script src="https://gist.github.com/cjimti/cb051976caa20f5c53311a7a75e85487.js"></script>

kubectl can use URLs or local files for input:

```bash
# create a service
kubectl create -f https://bit.ly/tcp-echo-service

# list services
kubectl get services

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          1d
tcp-echo     NodePort    10.109.249.93   <none>        5000:30552/TCP   3m
```

In my case, the port **32413** was assigned to the new TCP echo service.

Create a deployment configuration called `tcp-echo-deployment.yml`:

<script src="https://gist.github.com/cjimti/f936f728b28cdaf3f0edb26b2a7b8c99.js"></script>

kubectl can use URLs or local files for input:

```bash
kubectl create -f http://bit.ly/tcp-echo-deployment

# describe the deployment
kubectl describe deployment tcp-echo

# ensure that your pods are up and running
Replicas: 2 desired | 2 updated | 2 total | 2 available | 0 unavailable

```
> Pods not communicating? If you run a `kubectl describe pod NAMEOFPOD` and get back **unreachable:NoExecute** under the **Tolerations** section, you may need to check your `ufw` status.

```plain
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
```

Run `ufw status` again and ensure that you have **Anywhere on wg0** and **Anywhere on weave** rules in place.

```
Anywhere on wg0            ALLOW       Anywhere
Anywhere on weave          ALLOW       Anywhere
```

If these rules are not there run:

```bash
ufw allow in on wg0
ufw allow in on weave
ufw reload
```

If everything looks correct but the pods are still not communicating, disable the firewall and re-deploy in order to rule out any firewall issues.

```bash
# disable the firewall
ufw disable

# delete deployment
kubectl delete -f http://bit.ly/tcp-echo-deployment

# re-create deployment
kubectl create -f http://bit.ly/tcp-echo-deployment
```

#### Testing the Cluster

In my case, using NodePort without specifying a port, lets the cluster assign one at random. The `tcp-echo` service got port 30552. If networking is set up, currently we should be able to contact the new TCP echo server at that port on all three servers.

Use netcat to test the new TCP echo service. This test service returns some useful diagnostic information, namely the node we connected to (lax2 in the case below lax2,) the specific pod name, the pod IP access, the namespace and the data we sent to it.

First, we can test the port on the physical node with netcat:

```bash
nc -vz lax1.example.com 30552

found 0 associations
found 1 connections:
     1:    flags=82<CONNECTED,PREFERRED>
    outif en0
    src 192.168.86.24 port 54133
    dst 206.189.232.176 port 30552
    rank info not available
    TCP aux info available

```

In my case, lax1 is at 206.189.232.176 (at the moment), and we were able to connect to the port. Next, we can send some data and review the output from the tcp-echo server.

```bash
echo "testing 1,2,3..." | nc lax1.example 30552

Welcome, you are connected to node lax2.
Running on Pod tcp-echo-5f7fdcf7bc-rm6qt.
In namespace default.
With IP address 10.34.0.1.
Service default.
testing 1,2,3...
```
No pods are running on lax1, lax2 serviced the request. The output demonstrates that our network is operating as intended and the `tcp-echo` service passed along the message to a `tcp-echo` pod running on lax2.

Let's scale our two `tcp-echo` pods to four.

```bash
kubectl scale deployments/tcp-echo --replicas=4

kubectl get pods -o wide

NAME                        READY     STATUS    RESTARTS   AGE       IP          NODE
tcp-echo-5f7fdcf7bc-7v5tc   1/1       Running   0          1h        10.40.0.2   lax2
tcp-echo-5f7fdcf7bc-h4k7z   1/1       Running   0          24m       10.34.0.2   lax3
tcp-echo-5f7fdcf7bc-rm6qt   1/1       Running   0          1h        10.34.0.1   lax3
tcp-echo-5f7fdcf7bc-tkmhl   1/1       Running   0          24m       10.40.0.3   lax2

```

The scaling works, but I don't want my extra $5 a month node to go to waste merely hosting the master. To allow the master to run pods, it must be untainted.

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-

node "lax1" untainted
taint "node-role.kubernetes.io/master:" not found
taint "node-role.kubernetes.io/master:" not found
```

In order to test our lax1 node as a pod host, we need give the cluster a reason to use it.

```bash
# scale back our tcp-echo 
kubectl scale deployments/tcp-echo --replicas=2

# then scale up again to 4
kubectl scale deployments/tcp-echo --replicas=4

kubectl get pods -o wide

NAME                        READY     STATUS    RESTARTS   AGE       IP          NODE
tcp-echo-5f7fdcf7bc-7v5tc   1/1       Running   0          1h        10.40.0.2   lax2
tcp-echo-5f7fdcf7bc-86tpz   1/1       Running   0          4s        10.32.0.2   lax1
tcp-echo-5f7fdcf7bc-c47z5   1/1       Running   0          4s        10.40.0.3   lax2
tcp-echo-5f7fdcf7bc-rm6qt   1/1       Running   0          1h        10.34.0.1   lax3

```

We now have two pods running on lax2, one on each lax1 and lax3.

I am going to end this post here at a good place. The example above is not the fastest cluster on earth, but that has everything to do with the budgeted $5 instances and not much in regards to configuration. If we needed this to handle an enterprise workload all we need to do is upgrade the server instances, not re-architect our entire infrastructure. Scaling to handle enterprise workloads might take only an hour or two of adding nodes.

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance Hobby Clusters) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)


I maintain three personal hobby clusters, one with [Digital Ocean] hosted in New York and one with [Vultr] hosted in Los Angeles and another with [Linode] in Japan. I recommend my employer Deasil. If you need enterprise-level hosting including co-location, data center, and NOC services, Contact [Deasil Networks](https://deasil.network/about). If you need any software development check out [Deasil Works](https://deasil.works/).

Are you in the business or collecting, moving, buffering, queueing, processing or presenting data on your cluster? If so, check out [txn2.com](https://txn2.com/).

## Resources

- [Linode]
- [Digital Ocean]
- [Vultr]
- [KUBECONFIG]
- [systemd]
- [Weave Net]
- [Etcd]
- [WireGuard]
- [Hobby Kube] A fantastic write-up (with teraform scripts) and how I got started.

[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[Digital Ocean]: https://m.do.co/c/97b733e7eba4
[vultr]: https://www.vultr.com/?ref=7418713
[KUBECONFIG]: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
[systemd]: https://wiki.ubuntu.com/systemd
[WireGuard]: https://www.wireguard.io/
[Weave Net]: https://www.weave.works/oss/net/
[Etcd]: https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html
[Hobby Kube]: https://github.com/hobby-kube/guide
