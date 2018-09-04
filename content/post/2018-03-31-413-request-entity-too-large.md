---
layout:     post
title:      "Kubernetes - 413 Request Entity Too Large"
subtitle:   "Configuring the NGINX Ingress Controller"
date:       2018-03-24
author:     "Craig Johnston"
URL:        "413-request-entity-too-large/"
image:      "/img/post/tooth.jpg"
twitter_image: "/img/post/tooth_876_438.jpg"
tags:
- Kubernetes
- ingress
- nginx
series:
- Kubernetes
- ingress
---

When setting up [nginx ingress] on [Kubernetes] for a private [Docker Registry], I ran into an error when trying to push an image to it.

```
Error parsing HTTP response: invalid character '<' looking for beginning of value: "<html>\r\n<head><title>413 Request Entity Too Large</title></head>\r\n<body bgcolor=\"white\">\r\n<center><h1>413 Request Entity Too Large</h1></center>\r\n<hr><center>nginx/1.9.14</center>\r\n</body>\r\n</html>\r\n"
```

The "413 Request Entity Too Large" error is something many accustomed to running [nginx] as a standard web server/proxy. [nginx] is configured to restrict the size of files it will allow over a post. This restriction helps avoid some DoS attacks. The default values are easy to adjust in the Nginx configuration. However, in the [Kubernetes] world things are a bit different. I prefer to do things the [Kubernetes] way; however, there is still a lack of established configuration idioms, since part of its appeal is flexibility. One thousand different ways of doing something means ten thousand variations of remedies to every potential problem. Googling errors in the [Kubernetes] world leads to a mess of solutions not always explicitly tied to an implementation. I am hoping that as [Kubernetes] continues to gain popularity more care will be taken to provide context for solutions to common problems.

### Context

I now use the official [NGINX Ingress Controller], there are quite a few options out there, so this solution only applies to the official [NGINX Ingress Controller]. If you don't already have it, you can follow the easy [ingress controller deployment] instructions.

I found this solution in the [Ingress examples] folder in the [Github repository]. I probably should have started there on my journey to set up a private [Docker registry] on my [Kubernetes] cluster.

<script src="https://gist.github.com/cjimti/4cd7fdb93787fa5aca84b4d386b757aa.js"></script>

Using **annotations** you can customize various configuration settings. In the case of nginx upload limits, use the annotation below:

 ```
 nginx.ingress.kubernetes.io/proxy-body-size: "0"
 ```

The annotation (see its context in the gist: [Registry Ingress Example] above) removes any restriction on upload size. Of course, you can set this to a size appropriate to your situation.

### Still Not Working?

Maybe you installed the [NGINX Ingress Controller] wrong as I did. I was rushing to get a project done at 3 am, cutting and pasting commands like a wild monkey. I installed the non-RBAC based configuration; however, my cluster uses RBAC. To make things worse, everything else was working fine for some reason (at least it seemed to) until this configuration issue came up and the annotations were not working. Double check your [install steps].

### Not the Ingress Controller you are using?

Here are some solutions for alternative implementations:

- [413 Request Entity Too Large](https://github.com/nginxinc/kubernetes-ingress/issues/21) NGINX Ingress Controller **by nginx**
- [File upload limit in Kubernetes & Nginx](http://blog.pragtechnologies.com/file-upload-limit-in-kubernetes/)


[Ingress examples]: https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples
[install steps]: https://github.com/kubernetes/ingress-nginx/tree/master/deploy
[ingress controller deployment]: https://github.com/kubernetes/ingress-nginx/tree/master/deploy
[Github repository]: https://github.com/kubernetes/ingress-nginx
[NGINX Ingress Controller]: https://github.com/kubernetes/ingress-nginx
[nginx]: https://www.nginx.com/
[nginx ingress]: https://github.com/kubernetes/ingress-nginx
[Kubernetes]: https://kubernetes.io/
[Docker Registry]: https://hub.docker.com/_/registry/
[Registry Ingress Example]: https://gist.github.com/cjimti/4cd7fdb93787fa5aca84b4d386b757aa