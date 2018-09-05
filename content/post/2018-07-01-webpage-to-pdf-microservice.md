---
layout:     post
title:      "Webpage to PDF Microservice"
subtitle:   "Automate PDF Report Generation"
date:       2018-07-01
author:     "Craig Johnston"
URL:        "webpage-to-pdf-microservice/"
image:      "/img/post/briefcase.jpg"
twitter_image: "/img/post/briefcase_876_438.jpg"
tags:
- Microservice
- PDF
- Data
- Docker
- Kubernetes
---

I create a lot of data visualizations for clients, many of which are internal, portal-style websites that present data in real time, as well as give options for viewing reports from previous time-frames. PDFs are useful for data such as bank statements or any form of time-snapshot progress reporting. It is common for clients to want PDF versions generated on a regular basis for sharing through email or other technologies.

[![txn2/txpdf](https://raw.githubusercontent.com/txn2/txpdf/master/assets/mast.jpg)](https://github.com/txn2/txpdf)

## Background (HTML to PDF)

The [wkhtmltopdf] utility has been around awhile and works great when you get it working correctly on your platform. However, the newest version as of this writing **0.12.5** has a [bug] prevening TOC generation on some platforms. Some Linux platforms require the installation of Microsoft font packs, and compiling from [source][wkhtmltopdf source] leads you down a rabbit hole of dependency hell.

[txpdf] is a web server written in [golang] and utilizes the go library [go-wkhtmltopdf] interact with a custom [wkhtmltopdf] binary explicitly compiled for an [Alpine Linux] container with all the necessary dependencies. With [txpdf], [Docker] is the only dependency, and therefore running web (html) to PDF conversion service.

## Docker and Microservices

[txpdf] wraps [wkhtmltopdf] in a small [Alpine Linux] container and exposes an API endpoint (/getPdf) on port 8080 by default.

### Run [txn2/txpdf]

To test it out make sure you have [Docker] installed. Open a terminal and run the following command:

```bash
docker run --rm -p 8080:8080 -e DEBUG=true txn2/txpdf
```

Docker pulls the latest [txn2/txpdf] container, and forwards the port **8080** on your host machine to **8080** on the container. The `-e DEBUG=true` sets the environment variable `DEBUG` to `true`, which produces additional log data while you are testing.

### Configuration

[txpdf] is configured on each call to it by posting JSON data. The easiest way to test is by using [curl]. If you use MacOs and don't already have it, I recommend installing it with [homebrew] by typing `brew install curl`.

Download or create a sample JSON configuration and use [curl] to POST this configuration to the API running on the Docker container. You can download the and browse [example JSON] configurations from the example folder in the [txpdf] project. I routinely use [wget] to download single files onto my mac; another easy [homebrew] install: `brew install wget`.

```bash
wget https://raw.githubusercontent.com/txn2/txpdf/master/examples/simple.json
```

You can download the `simple.json` with the command above, or create it in a text editor.

```json
{
  "options": {
    "print_media_type": true
  },
  "pages": [
    {
      "Location": "https://www.example.com"
    }
  ]
}
```

If you are not accustomed to working with JSON data then I recommend using an editor that checks for proper syntax, any errors prevent it from being parsed by the service. Sites like [jsoneditoronline.org](https://jsoneditoronline.org/) are great for testing.

### POST

Issue an HTTP POST request to the container with the following `curl` command:

```bash
curl -d "@simple.json" -X POST http://localhost:8080/getPdf --output test.pd
```

`curl` POSTs the contents of `simple.json` to the path `/getPdf` on `localhost:8080`.

**Example:**

In the terminal on top, I issue the Docker run command. The container runs a server and remains running until I stop the container. I could, of course, specify the `-d` flag to docker and run this in the background; however we are just testing. The end goal would be to run this container in a [Custom Kubernetes Cluster] or a hosting provider capable of running Docker images.

![Docker Run Example](/images/content/docker_run_example.gif)

You now have a file called `test.pdf` in the current directory. The directory in which you ran the `curl` command. The PDF should have the contents of the site https://example.com.

**simple.json** contains a simple example of a single page site with no cover page or table of contents.

## Advanced Options and Templating

[txpdf] treats the inbound JSON data as a [go template] before being processed as configuration. This template pre-processing allows you to add dynamic content to the configuration and is useful for situations where you have a cron job or another automated process issue the same post on a particular interval, consider the example below. [txpdf] also includes the [sprig] library to extend the basic functionality of [go template]s.


The following pulls a week of blog posts from [hackaday] and starts with a **Table of Contents**, demonstrating multiple pages and **date commands** provided by [sprig]:

```json
{% raw %}
{
  "options": {
    "toc_xsl_skip": true,
    "toc_header_text": "Week of Hackaday {{now | date `2006/1/2` }}",
    "footer_left": "[section]",
    "footer_right": "Page [page] of [topage]",
    "custom_headers": {
      "User-Agent": "txpdf"
    },
    "custom_header_propagation": true,
    "print_media_type": true,
    "no_background": true,
    "disable_javascript": true,
    "javascript_delay": 2000
  },
  "toc": true,
  "pages": [
    {
      "Location": "https://hackaday.com/{{now | date `2006/1/2` }}/"
    },
    {
      "Location": "https://hackaday.com/{{now | date_modify `-24h` | date `2006/1/2` }}/"
    },
    {
      "Location": "https://hackaday.com/{{now | date_modify `-48h` | date `2006/1/2` }}/"
    },
    {
      "Location": "https://hackaday.com/{{now | date_modify `-72h` | date `2006/1/2` }}/"
    },
    {
      "Location": "https://hackaday.com/{{now | date_modify `-96h` | date `2006/1/2` }}/"
    },
    {
      "Location": "https://hackaday.com/{{now | date_modify `-96h` | date `2006/1/2` }}/"
    },
    {
      "Location": "https://hackaday.com/{{now | date_modify `-120h` | date `2006/1/2` }}/"
    }
  ]
}
{% endraw %}
```

To test this out, grab the JSON directly from the examples on Github with `wget`:

```bash
wget https://raw.githubusercontent.com/txn2/txpdf/master/examples/days.json
```

Make a call to the [txpdf] container with `curl` using the new `days.json` downloaded above:

```bash
curl -d "@days.json" -X POST http://localhost:8080/getPdf --output had.pdf
```

Check out the new file **had.pdf** with a **Table of Contents** and about a week's worth of [hackaday]. It's not a great looking PDF, and the [hackaday] site is probably not designed for PDFs or printers, but it's a good example to get the point. A week of hackaday is 55 pages. However, I have generated reports with over 200 pages and a cover sheet.


![hackaday pdf](/images/content/hackaday.png)

### Conclusion

If you develop pages that you intend to convert to PDF you should design them with additional CSS for the print [@media] type. CSS @media types allow you to have a separate layout for screen and print, along with hiding elements like navigation or any interactive component.

Check out [Designing For Print With CSS] by Rachel Andrew on SmashingMag for an excellent introduction.

### Security

[txpdf] is not intended to be run on the public internet without some form of security. [txpdf] is intended as a backend [Microservice], a component of a more extensive system of services and therefore is intentionally limited in its scope as a standalone application.


### Resources

- [n2pdf] container wrapped [wkhtmltopdf]
- [txpdf] web service
- [Custom Kubernetes Cluster]

[wget]:https://www.gnu.org/software/wget/
[example JSON]:https://github.com/txn2/txpdf/tree/master/examples
[homebrew]: https://brew.sh/
[curl]: https://curl.haxx.se/
[txn2/txpdf]: https://hub.docker.com/r/txn2/txpdf/
[Docker]: https://docs.docker.com/install/
[Alpine Linux]: https://alpinelinux.org/
[n2pdf]: https://github.com/txn2/n2pdf
[txpdf]: https://github.com/txn2/txpdf
[wkhtmltopdf]: https://wkhtmltopdf.org/
[bug]: https://github.com/wkhtmltopdf/wkhtmltopdf/issues
[wkhtmltopdf source]: https://github.com/wkhtmltopdf/wkhtmltopdf
[Custom Kubernetes Cluster]: https://mk.imti.co/hobby-cluster/
[golang]: https://golang.org
[go-wkhtmltopdf]:https://github.com/SebastiaanKlippert/go-wkhtmltopdf
[go template]: https://golang.org/pkg/text/template/
[sprig]: http://masterminds.github.io/sprig/
[hackaday]:https://hackaday.com/
[@media]:https://developer.mozilla.org/en-US/docs/Web/CSS/@media
[Designing For Print With CSS]:https://www.smashingmagazine.com/2015/01/designing-for-print-with-css/
[Microservice]:https://mk.imti.co/microservices/