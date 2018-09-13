---
layout:     post
title:      "Basic Auth on Kubernetes Ingress"
subtitle:   "Basic Auth is supported by nearly every major web client, library, and utility."
date:       2018-05-19
author:     "Craig Johnston"
URL:        "kubernetes-ingress-basic-auth/"
image:      "/img/post/lock.jpg"
twitter_image: "/img/post/lock_876_438.jpg"
tags:
- Kubernetes
- Security
- Ingress
series:
- Kubernetes
---

[Basic Auth] is one of the oldest and easiest ways to secure a web page or API endpoint. [Basic Auth] does not have many features and lacks the sophistication of more modern access controls (see [Ingress Nginx Auth Examples]). However, [Basic Auth] is supported by nearly every major web client, library, and utility. [Basic Auth] is secure, stable and perfect for quick security on Kubernetes projects. [Basic Auth]  can easily we swapped out later as requirements demand or provide a foundation for implementations such as [OAuth 2] and [JWT].

First, you need an [Ingress] controller on your Kubernetes cluster and at least one ingress rule that we can apply [Basic Auth]. If you are following along with my articles on building a [Production Hobby Cluster] Kubernetes and do not yet have [Ingress] installed, you should read [Ingress on Custom Kubernetes][Ingress] before getting started.

#### Security

The [Basic Auth] process sends credentials to the server in the clear, although encrypted and [base64]'d, they can be quickly reversed back into a human-readable string. Because of this, it is essential we are issuing calls over [SSL][Let's Encrypt]. However, if the information or service being password protected should be hidden, then [SSL][Let's Encrypt] encrypted communication would already be required.

For the [Production Hobby Cluster] we use [Let's Encrypt], so if you have not done so already you can check out my article on setting up [Let's Encrypt] for your custom cluster read: [Let's Encrypt, Kubernetes].

### Create a User and Password

Start by creating an [htpasswd] file that contains the [Basic Auth] credentials. The following creates a user called **sysop**, choose whatever username you like.

```bash
htpasswd -c ./auth sysop
```

It is important to name the file **auth**. The filename is used as the key in the key-value pair under the `data` section of secret.

After entering a password for the new user twice, you end up with the file `auth`.

### Create a [Secret]

Kubernetes can create a **[generic]** [Secret] from the generated `auth` file, or from any file, however, the format of the htpasswd generated file is necessary for use with [Basic Auth]. The file name is used as the key in Basic Auth secret, therefore its best to name it **auth** and avoid having to edit the secret.  [Ingress] uses the new [Secret] in it's annotation section to provide [Basic Auth].

The [kubectl create secret] command can create a secret from a local file, directory or literal value using the **[generic]** directive. In the example below I call the new secret **sysop**, named after the single set of credentials stored in it. However, if you are grouping many credentials, it would be better to give it a more generic name.

Create the [Secret]:

```bash
kubectl create secret generic sysop --from-file auth
```

Ensure the [Secret] was created successfully by viewing the details:

```bash
kubectl get secret sysop -o yaml
```

You should have a secret similar to the following:

```yaml
apiVersion: v1
data:
  auth: c3avb2A2GGFwcjEkMmo5SwoucC4kcWtDR3NTVUxSDXJmTVkwNUwxUlZYLbo=
kind: Secret
metadata:
  creationTimestamp: 2018-05-18T06:55:51Z
  name: sysop
  namespace: default
  resourceVersion: "265674"
  selfLink: /api/v1/namespaces/default/secrets/sysop
  uid: 2bfb399c-58d6-11e8-b11e-5600017e897a
type: Opaque
```

Of course, you should avoid publishing your new [Secret] like I just did, since the `auth:` value under `data:` is only a [base64] encoded version of the username and encoded password pair. The password may be reversed quickly with a dictionary attack or other password cracking utilities.

### Protect [Ingress]

The following is an example [Ingress] configuration for a test application called [ok] running on the [phc.txn2.net] test cluster.

```yaml
 apiVersion: extensions/v1beta1
 kind: Ingress
 metadata:
   name: ok-auth
   labels:
     app: ok-auth
     system: test
   annotations:
     nginx.ingress.kubernetes.io/auth-type: basic
     nginx.ingress.kubernetes.io/auth-secret: sysop
     nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - ok"
 spec:
   rules:
   - host: ok-auth.la.txn2.net
     http:
       paths:
       - backend:
           serviceName: "ok"
           servicePort: 5001
         path: /
   tls:
   - hosts:
     - ok-auth.la.txn2.net
     secretName: la-txn2-net-tls
```

All that is needed are three [Ingress] annotations:
- nginx.ingress.kubernetes.io/auth-type: basic
- nginx.ingress.kubernetes.io/auth-secret: sysop
- nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - ok."

The [Ingress] for [ok-auth.la.txn2.net](https://ok-auth.la.txn2.net) is now [Basic Auth] protected using credentials in a [Secret] called **sysop**.

{{< content-ad >}}

## Resources

If you found this article useful, you may want to check out all the articles used to build on the [Production Hobby Cluster] tagged with [phc.txn2.net].

Additional examples of [Ingress] authentication can be found at the official [Ingress Nginx Auth Examples] repository.

---

If in a few days you find yourself setting up a cluster in Japan or Germany on [Linode], and another two in Australia and France on [vultr], then you may have just joined the PHC (Performance [Hobby Cluster]s) club. Some people tinker late at night on their truck, we benchmark and test the resilience of node failures on our overseas, budget kubernetes clusters. It's all about going big, on the cheap.

[![k8s performance hobby clusters](https://github.com/cjimti/mk/raw/master/images/content/k8s-tshirt-banner.jpg)](https://amzn.to/2IOe8Yu)

[Ingress Nginx Auth Examples]: https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples/auth
[phc.txn2.net]: http://localhost:4000/tag/phc.txn2.net/
[generic]: https://kubernetes-v1-4.github.io/docs/user-guide/kubectl/kubectl_create_secret_generic/
[kubectl create secret]: https://kubernetes-v1-4.github.io/docs/user-guide/kubectl/kubectl_create_secret/
[htpasswd]: https://httpd.apache.org/docs/current/programs/htpasswd.html
[Let's Encrypt, Kubernetes]: /lets-encrypt-kubernetes/
[base64]: https://en.wikipedia.org/wiki/Base64
[Basic Auth]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication
[OAuth 2]: https://oauth.net/2/
[JWT]: https://jwt.io/
[Ingress]: /web-cluster-ingress/
[Production Hobby Cluster]: /hobby-cluster/
[Let's Encrypt]: https://letsencrypt.org/
[Hobby Cluster]: /hobby-cluster/
[Linode]: https://www.linode.com/?r=848a6b0b21dc8edd33124f05ec8f99207ccddfde
[vultr]: https://www.vultr.com/?ref=7418713
[Secret]: https://kubernetes.io/docs/concepts/configuration/secret/
[ok]: https://github.com/txn2/ok