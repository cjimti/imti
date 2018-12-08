---
layout:     post
title:      "Let's Encrypt, Kubernetes"
subtitle:   "Automated, secure and free 443/https with signed x509 certificates for Ingress."
date:       2018-05-18
author:     "Craig Johnston"
URL:        "lets-encrypt-kubernetes/"
image:      "/img/post/seal.jpg"
twitter_image: "/img/post/seal_876_438.jpg"
tags:
- Kubernetes
- Security
- Ingress
series:
- Kubernetes
---

Use [cert-manager] to get port 443/https running with signed x509 certificates for [Ingress] on your Kubernetes [Production Hobby Cluster]. [cert-manager] is the successor to **kube-lego** and the preferred way to "[automatically obtain browser-trusted certificates, without any human intervention.](https://letsencrypt.org/how-it-works/)" using [Let's Encrypt].

You need to [install Helm] first if you do not already have it. Otherwise, check out my article [Helm on Custom Kubernetes], especially if you are following along with my [Production Hobby Cluster] guides.

### Install [cert-manager]

```bash
helm install --name cert-manager --namespace kube-system stable/cert-manager
```

After [Helm] installs [cert-manager] you end up with a [ServiceAccount] [ClusterRole], [ClusterRoleBinding], [Deployment] and a couple of [Pod]s named **cert-manager-cert-manager** in the **kube-system** [namespace]. [Helm] additionaly installs three [CustomResourceDefinition]s for [cert-manager] (custom resources are not namespaced):

- certificates.certmanager.k8s.io
- clusterissuers.certmanager.k8s.io
- issuers.certmanager.k8s.io

It's good to know what [Helm] installed for [cert-manager] and these three [CustomResourceDefinition]s represent the configurations we are creating in the next steps.

[cert-manager] uses ether an [Issuer] or [ClusterIssuer] to represent a certificate authority. [Issuer] is bound to a [namespace] so for our [Production Hobby Cluster] we will use a [ClusterIssuer].

We will setup a **letsencrypt-staging** and a **letsencrypt-prod** [ClusterIssuer].

### Create a [ClusterIssuer]

First, we need to have a functional [Ingress] on our Kubernetes cluster. If you have not done so, check out my article [Ingress on Custom Kubernetes].

Create a file called `10-cluster-issuer-letsencrypt-staging.yml` for the [ClusterIssuer], add the following configuration and change the email address to your own.

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  namespace: default
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: someone@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the HTTP-01 challenge provider
    http01: {}
```

Create the staging [ClusterIssuer] with `kubectl`:
```bash
kubectl create -f 10-cluster-issuer-letsencrypt-staging.yml
```

Expect output similar to the following:

```bash
clusterissuer.certmanager.k8s.io "letsencrypt-staging" created
```

Check the status of the new [ClusterIssuer]:

```bash
kubectl describe ClusterIssuer
```

Under the status section you should get output similar to the following:

```yaml
  Conditions:
    Last Transition Time:  2018-05-18T08:05:09Z
    Message:               The ACME account was registered with the ACME server
    Reason:                ACMEAccountRegistered
    Status:                True
    Type:                  Ready
```

Now we can create a production [ClusterIssuer], for use only after we test with our staging configuration; otherwise, we are likely to hit rate limits while testing.

The only essential difference between the staging and production [ClusterIssuer] is the `server:` URL.

- **Staging**: `server: https://acme-staging.api.letsencrypt.org/directory`
- **Production**: `server: https://acme-v01.api.letsencrypt.org/directory`

Create a production [ClusterIssuer] with the configuration below, make sure to change the email address to a valid account. The configured email address may receive messages from [Let's Encrypt].

Create a file called `20-cluster-issuer-letsencrypt-production.yml` for the [ClusterIssuer], add the following configuration and change the email address.

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
  namespace: default
spec:
  acme:
    # The ACME server URL
    server: https://acme-v01.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: someone@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-production
    # Enable the HTTP-01 challenge provider
    http01: {}
```

Create the production [ClusterIssuer] with `kubectl`:
```bash
kubectl create -f 20-cluster-issuer-letsencrypt-production.yml
```

Ensure both [ClusterIssuer]s are present:

```bash
kubectl get ClusterIssuer
```

Output:

```bash
NAME                     AGE
letsencrypt-production   3m
letsencrypt-staging      5m
```

### Obtain a Certificate

Create a file named `30-Cert-DOMAIN.yml`, replacing **DOMAIN** with your domain. Copy the below configuration and change all the example domain references to your own. This configuration generates a test certificate from [Let's Encrypt]'s staging environment.

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-staging-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: example.com
  dnsNames:
  - www.example.com
  acme:
    config:
    - http01:
        ingressClass: nginx
      domains:
      - example.com
    - http01:
        ingress: my-ingress
      domains:
      - www.example.com
```

The two `http01` sections under `acme:` demonstrate using the http-01 challenge with and without an existing ingress. The http-01 challenge creates or uses an existing ingress to create a route for [Let's Encrypt] to determine that you control the domain. If you do not yet have an [ingress] configuration or have [Ingress] setup yet, I suggest checking out my article [Ingress on Custom Kubernetes], which builds on the [Production Hobby Cluster] guide.

Create the test [Certificate] with `kubectl`:
```bash
kubectl create -f 30-Cert-DOMAIN.yml`
```

Once we create the [Certificate] object we can check the status can find any errors. Generating staging certs give us opportunities to fix any mistakes and run the request for a cert multiple times without running into rate limitations.

Check the status with the following:

```bash
kubectl describe certificate example-com
```

Under `Conditions:` look for **Certificate issued successfully**. If the certificate issued successfully, you can view it in the [Secret] defined in your configuration. In our example, the secret is named `example-com-staging-tls`.

```bash
kubectl get secret example-com-staging-tls -o yaml
```

In my experience you should include the [Let's Encrypt] environment in the [Secret] name, this avoids confusion when you update the [Certificate] to production, you want to see the new **production** secret generated.

### Production

Edit the [Certificate] configuration to point to the [Let's Encrypt] production environment URL, `server: https://acme-v01.api.letsencrypt.org/directory`. Change the secret name to include the work **production** rather than **staging** and apply the updated configuration.

Apply the production changes to the [Certificate] configuration with `kubectl`:
```bash
kubectl apply -f 30-Cert-DOMAIN.yml`
```

Once again, check the status:

```bash
kubectl describe certificate example-com
```

If you get **Certificate issued successfully** then you are now ready to use the new **example-com-production-tls** secret (cert) assuming you named it after your real domain.

### Using the new cert for [Ingress]

Now comes the easiest part, using the new [Let's Encrypt] signed x509 certificate. I'll stick with using the domains example.com and www.example.com for purposes of illustration.

Sample [Ingress] using example cert:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: example
  labels:
    app: example
    system: test
spec:
  rules:
  - host: example.com
    http:
      paths:
      - backend:
          serviceName: "ok"
          servicePort: 5001
        path: /
  tls:
  - hosts:
    - example.com
    - www.example.com
    secretName: example-com-production-tls
```

### Real Life Example

The following is my [Certificate] and [Ingress] configuration for the domains [phc.imti.co](https://phc.imti.co), [phc.txn2.com](https://phc.txn2.com) and [phc.txn2.net](https://phc.txn2.net). I'll refrain from publishing my actual TLS certificate [Secret]. [Let's Encrypt] produces a Multi-Domain (SAN) Certificate, and as you might have noticed imti.co is hanging out at the bottom of the list; A separate TLD like this works but should probably be a separate cert, if I were concerned with having a matching [common name]. However, the sub-domain phc.imti.co is destined for a redirect, so it's not necessary.

I created the [Certificate] configuration with the file name `00-phc-cert.yml`. I set these certs up before I added [Ingress] rules but after I first pointed the DNS to the cluster. [cert-manager] uses the **nginx** [Ingress] as specified under `http01:` `ingressClass:` to temporarily create routes for [Let's Encrypt] to verify the ownership of the domain.

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: phc
  namespace: default
spec:
  secretName: phc-production-tls
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: phc.txn2.net
  dnsNames:
  - phc.txn2.net
  - phc.txn2.com
  - phc.imti.co
  acme:
    config:
    - http01:
        ingressClass: nginx
      domains:
      - phc.txn2.net
      - phc.txn2.com
      - phc.imti.co
```

I named the [Ingress] configuration `10-ingress.yml` and all the domains use a
in the TLS [Secret] defined in `secretName: phc-production-tls`.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ok-phc
  labels:
    app: ok-phc
    system: test
spec:
  rules:
  - host: phc.imti.co
    http:
      paths:
      - backend:
          serviceName: "ok"
          servicePort: 5001
        path: /
  - host: phc.txn2.net
    http:
      paths:
      - backend:
          serviceName: "ok"
          servicePort: 5001
        path: /
  - host: phc.txn2.com
    http:
      paths:
      - backend:
          serviceName: "ok"
          servicePort: 5001
        path: /
  tls:
  - hosts:
    - phc.txn2.net
    - phc.txn2.com
    - phc.imti.co
    secretName: phc-production-tls
```
I could have easily created a seperate cert for imti.co and grouped it under a seperate `hosts:` section. However I'll probably be redirecting it in the future so it suits my need at the moment.

## Port Forwarding / Local Development

Check out [kubefwd](https://github.com/txn2/kubefwd) for a simple command line utility that bulk forwards services of one or more namespaces to your local workstation.

---

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance [Hobby Cluster]s) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)

[common name]: https://www.quora.com/What-does-the-CN-name-in-a-client-certificate-refer-to
[Helm on Custom Kubernetes]: /helm-on-custom-cluster/
[install Helm]: /helm-on-custom-cluster/
[Ingress]: /web-cluster-ingress/
[cert-manager]: https://github.com/jetstack/cert-manager/
[Production Hobby Cluster]: /hobby-cluster/
[Let's Encrypt]: https://letsencrypt.org/
[Hobby Cluster]: /hobby-cluster/
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[vultr]: https://www.vultr.com/?ref=7418713
[Helm]: https://helm.sh/
[Pod]: https://kubernetes.io/docs/concepts/workloads/pods/pod/
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[ServiceAccount]: https://kubernetes.io/docs/admin/service-accounts-admin/
[ClusterRole]: https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole
[ClusterRoleBinding]: https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding
[namespace]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[CustomResourceDefinition]: https://kubernetes.io/docs/tasks/access-kubernetes-api/extend-api-custom-resource-definitions/
[ClusterIssuer]: https://cert-manager.readthedocs.io/en/latest/reference/clusterissuers.html
[Issuer]: https://cert-manager.readthedocs.io/en/latest/reference/issuers.html
[Certificate]: https://cert-manager.readthedocs.io/en/latest/reference/certificates.html
[Secret]: https://kubernetes.io/docs/concepts/configuration/secret/
[Ingress on Custom Kubernetes]: /web-cluster-ingress/