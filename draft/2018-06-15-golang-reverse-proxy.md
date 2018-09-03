---
published: true
layout: post
title: Reverse Proxy in Golang
tags: coding golang docker cli
featured: coding golang docker cli
mast: proxy
---
Reverse proxies are standard components in many web architectures, from [Nginx] in front of [php-fpm] serving [Drupal] or [Wordpress], to endless mixtures of load balancers, security appliances, and popular firewall applications. [Reverse proxies differ from forward proxies][Forward Proxy vs. Reverse Proxy] in little but their intended implementation, be it service-side or client side. The following information is useful in either context. However, I focus on a service-side architecture. Further down this article, I'll be going over the reasonably simple [go] code needed to develop a basic, yet production quality proxy, but first I'll give you my take on why they solve so many problems and offer up my little workhorse, [n2proxy].

## Reverse Proxies

So why do we write custom Reverse Proxies? We don't need to write another [Nginx] or [HAProxy] unless we are directly in the business to do so. Reverse Proxies have the capability of providing a variety solutions beyond their common usage. Custom reverse proxies are great solutions for:

- Middleware logging into message queues
- Event triggering
- API adaptors and translators
- Message Buffering

Proxies give you complete control over the communication between a client and a service, without needing to modify either, whether it be impractical or impossible. It's like tapping a phone line where you don't just get to listen but modify the conversation itself.

## n2proxy

![n2proxy](https://raw.githubusercontent.com/txn2/n2proxy/master/mast.jpg)

I put [n2proxy] together from a few different projects that had very different needs but the same underpinning solution. A common problem, are older or proprietary systems that lack reasonable security standards, these older sites and web apps suffer routinely from [XSS], [SQL injection] and many vulnerabilities to malicious data, some legacy systems very architecture prevents a fix at the source.

[n2proxy] is open source, so you can fork it, contribute to it or write your own just like it, or better. If you want to write your own, I'll be going over the source further down.

[n2proxy] was built to:

- Inspect requested URLs and ban them if they match a set of patterns
- Inspect HTTP Post data and nullify it for any data matching a set of patterns.
- Inspect HTTP Post and make modifications based on matched patterns.

[n2proxy] is compiled and tested for Linux, MaxOs and Arm based systems (Raspberry Pi, Tinkerboard, and so on) as well as stand-alone [Docker] implementations or [Kubernetes].

If you are using a Mac I recommend installing [n2proxy] with [brew]:

```bash
brew install txn2/tap/n2proxy

# upgrade later with
brew upgrade n2proxy
```

You need a configuration file to get started:

```bash
wget https://raw.githubusercontent.com/txn2/n2proxy/master/cfg.yml
```

I'll be focusing on three main sections of the configuration. **postBan** for nullifying all post data when the system discovers a match, **urlBan** rewrites the path to "/" (slash) when the system discovers a match, and **postFilter** uses the powerful and fast [go templates] for modifying post data in-line when the system discovers a match. **postFilter** uses [sprig] with [go templates] to provide over 70 template functions in additional to built-in functions. **postFilter** allows you to make nearly any type of mutation to HTTP post body data, all in the confines of a configuration file.

**Sample Configuration**
<script src="https://gist.github.com/cjimti/e664ad48b7f356f9d5b6e66117d6b9ab.js"></script>

Unfortunately **postBan** and **urlBan** might look like alien code, or someone punched their keyboard, however [regular expressions] are an implementation of highly efficient search patterns common to most programming languages. The example set is taken primarily from K. K. Mookhey, and Nilesh Burghate's 2004 article, [Detection of SQL Injection and Cross-site Scripting Attacks]. This list is far from inclusive but get the point across.

Harmful post data and URLs can damage many legacy systems (and even Wordpress and Drupal sites that lack their monthly updates). Since [n2proxy] is a proxy, it exists outside the application layer, there is not much it can do elegantly for the end-user on that layer, but then again an elegant response is not entirely necessary when dealing with an attacker.

**postFilter** is the fun section, and if you are interested building API adaptors and translators, or rewiring the messages of that closed source [IOT] device so it can post data conforming to the interface of some distant web server, this is the section. Although the examples show how to shuffle the letters in the word "taco" and uppercase any instance of "good times", with [go templates] and [sprig] you have a clear jumping off point for considerable number of possibilities.

## Running [n2proxy]

I use the command line `n2proxy` when working and testing patterns locally, however in production use I prefer using the docker container (`docker pull txn2/n2proxy`). See the following examples:

**Command Version**
```bash
n2proxy --port=9099 --backend=https://www.google.com/ --cfg=./cfg.yml
```

**Docker Version**
```bash
docker run --rm -t -v "$(pwd)":/n2p/ -p 9099:9099 \
    txn2/n2proxy --port=9099 --cfg=/n2p/cfg.yml \
    --backend=https://www.google.com/
```

The [Docker] method is preferred when you need it to run in the background or survive reboots.

**Background Docker**

Naming your [Docker] container is a good idea if you plan to run more than one proxy (be sure they each get their own port on the host).
```bash
docker run --name n2p-google -d \
    -v "$(pwd)":/n2p/ \
    -p 9099:9099 \
    --restart=unless-stopped \
    txn2/n2proxy \
    --port=9099 \
    --cfg=/n2p/cfg.yml \
    --backend=https://www.google.com/
    
# tail the logs
docker logs -f n2p-google
```

You now have [https://www.google.com](https://www.google.com) served through [n2proxy] to [http://localhost:9099](http://localhost:9099) on your local workstation.

A Google.com proxy is a sound proof of concept, however, unless we run another HTTP proxy like [Charles]. We can't see what Google is receiving from us. Only it's response.

Now is a good time switch over to using [postman-echo.com] since it's very purpose is to send us back what we sent it. [postman-echo.com] returns [json] data and therefore I highly recommend installing **[jsonpp]** or **[json_pp]** or a number of variations, on MacOs you can use brew:

```bash
brew install jsonpp
```

Now start up a new proxy pointed to [postman-echo.com] as the backend.

```bash
# get a config if you don't already have one
wget https://github.com/txn2/n2proxy/blob/master/cfg.yml

# open a proxy to postman-echo.com on port 9090
n2proxy --port=9090 --backend=https://postman-echo.com/ --cfg=./cfg.yml
```

In a separate terminal window use [curl] to make an HTTP post request:
```bash
curl -s --request POST --url http://localhost:9090/post \
--data 'This taco is expected to be sent back, good   times.' \
| jsonpp
```

Postman sends back what is received, and with this, we can see the correct filtering was performed:

```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {
    "This cato is expected to be sent back, GOODTIMES.": ""
  },
  "headers": {
    "host": "postman-echo.com",
    "content-length": "49",
    "accept": "*/*",
    "accept-encoding": "gzip",
    "content-type": "application/x-www-form-urlencoded",
    "user-agent": "curl/7.60.0",
    "x-forwarded-port": "443",
    "x-forwarded-proto": "https"
  },
  "json": {
    "This cato is expected to be sent back, GOODTIMES.": ""
  },
  "url": "https://postman-echo.com/post"
}
```

In the **form** and **json** sections we see the word **taco** became **cato** as a result of the `shuffle` function in the first **postFilter**  `.Match | shuffle` and **good    times** became **GOODTIMES** from the from the `upper` and `nospace` functions in the second **postFilter** `.Match | upper | nospace`



The response from [postman-echo.com] is a clear indication that rules in **postFilter** are functioning as intended.

For the remainder of this article, I'll be going over the essential pieces of [go] code that are used to create [n2proxy].

## Proxy with Golang

The [go] standard libraries [net/http] and [net/http/httputil] come with all the functionality needed for the proxy.

The following source code is an abstract from the file [server.go], which contains the main application [package].

**HTTP Server**
```go
// server
http.HandleFunc("/", proxy.handle)

if *tls != true {
    logger.Info("Starting proxy in plain HTTP mode.")
    err = http.ListenAndServe(":"+*port, nil)
    if err != nil {
        fmt.Printf("Error starting proxy: %s\n", err.Error())
    }
    os.Exit(0)
}

logger.Info("Starting proxy in TLS mode.")
err = http.ListenAndServeTLS(":"+*port, *crt, *key, nil)
if err != nil {
    fmt.Printf("Error starting proxyin TLS mode: %s\n", err.Error())
}
```

Starting at the implementation, we see that the proxy is merely a path handler on the standard [go] HTTP server.  The **handle** method on the **proxy** object passed all HTTP requests sent to the server beginning with `/`.

Using an environment variable or flag (`if *tls != true {`) we can choose between serving plain HTTP with [http.ListenAndServe] or encrypted HTTP over TLS (HTTPS) with [http.ListenAndServeTLS].

Working from the implementation up, we see the **proxy** object is created with three arguments: **backend**, **cfg** and **logger***:

```bash
proxy := NewProxy(*backend, *cfg, logger)
```

Because I am using the command line [flag] package from [go], I must dereference pointers to values with a `*`, since the `NewProxy` function is expecting values.

-  **backend** - example: https://postman-echo.com/
-  **cfg** - example: ./cfg.yml
-  **logger** - a configured [zap] logger (speed is essential)

### New Proxy

The `NewProxy` function returns an object with a `handle` method we passed to the [http.HandleFunc] in the implementation above. Since `handle` is a method of the new proxy object created by `NewProxy` it has access to its configuration. The `proxy` object is a [go] struct with a method called `handle`:

```go
type Proxy struct {
    target  *url.URL
    proxy   *httputil.ReverseProxy
    cfgFile string
    logger  *zap.Logger
    eng     *rweng.Eng
}
```

The core component of this proxy object is a pointer to a [ReverseProxy] object created by the [httputil] package's [NewSingleHostReverseProxy] function:

```go
func NewProxy(target string, cfgFile string, logger *zap.Logger) *Proxy {
    targetUrl, err := url.Parse(target)
    if err != nil {
        fmt.Printf("Unable to parse URL: %s\n", err.Error())
        os.Exit(1)
    }

    // create an rweng engine from a yaml configuration
    eng, err := rweng.NewEngFromYml(cfgFile, logger)
    if err != nil {
        fmt.Printf("Engine failure: %s\n", err.Error())
        os.Exit(1)
    }

    pxy := httputil.NewSingleHostReverseProxy(targetUrl)

    proxy := &Proxy{
        target: targetUrl,
        proxy:  pxy,
        logger: logger,
        eng:    eng,
    }

    return proxy
}
```

Filtering and blocking is the central purpose of this proxy. The `handle` method below has access to `eng` where a method called `ProcessRequest` gets a shot at modifying the response and request data. You can think of it as a proxy within a proxy. The following code shows **http.ResponseWriter** and **http.Request** objects are sent first to `p.eng.ProcessRequest(w, r)` and finally handled by `p.proxy.ServeHTTP(w, r)`:

```go
func (p *Proxy) handle(w http.ResponseWriter, r *http.Request) {

    start := time.Now()
    reqPath := r.URL.Path
    reqMethod := r.Method

    end := time.Now()
    latency := end.Sub(start)

    p.logger.Info(reqPath,
        zap.String("method", reqMethod),
        zap.String("path", reqPath),
        zap.String("time", end.Format(time.RFC3339)),
        zap.Duration("latency", latency),
    )

    r.Host = p.target.Host

    // process request
    p.eng.ProcessRequest(w, r)

    p.proxy.ServeHTTP(w, r)
}
```

If you are curious how `p.eng.ProcessRequest(w, r)` filters data check out the method `ProcessRequest` in the [rweng] source code (read/write engine). In [rweng] the function **NewEngFromYml** is where the [yaml configuration] file is Unmarshaled into a configuration struct after which all [regex patterns] and [go templates] are pre-compiled.

### Next Steps

**Middleware**: The method `p.eng.ProcessRequest(w, r)` is called before `p.proxy.ServeHTTP(w, r)` and of course this would be a great place to call dynamically any number of handler middlewares. We can also inject middleware higher up in the [net/http] package.

**Concurrency**: In the [rweng] method `ProcessRequest` filters run serially, however, if dealing with a vast number of rules, a more sophisticated Fan-out, fan-in solution can chunk the rules and process them concurrently (assuming you are working on copies of data). See [Go Concurrency Patterns: Pipelines and cancellation].



## Resources

- [Charles] HTTP proxy
- [brew] is the missing package manager for macOS
- [haproxy] is a reliable, high performance TCP/HTTP load balancer
- [nginx] started as a web server / proxy and now considers itself a platform.
- [n2proxy] for contraband filtering reverse proxy for plain HTTP and SSL.
- The [go] programming language.
- [Forward Proxy vs. Reverse Proxy]
- [regular expressions]
- [Detection of SQL Injection and Cross-site Scripting Attacks]
- [Go Concurrency Patterns: Pipelines and cancellation]
- [go templates]
- [sprig] - Over 70 template functions for Go’s template language.
- [postman-echo.com] - test your REST clients and make sample API calls.

[postman-echo.com]:https://docs.postman-echo.com/
[Charles]:https://www.charlesproxy.com/
[Detection of SQL Injection and Cross-site Scripting Attacks]:https://www.symantec.com/connect/articles/detection-sql-injection-and-cross-site-scripting-attacks
[regular expressions]:https://en.wikipedia.org/wiki/Regular_expression
[sprig]: http://masterminds.github.io/sprig/
[brew]: https://brew.sh/
[Kubernetes]: https://mk.imti.co/tag/kubernetes/
[Docker]: https://www.docker.com/
[haproxy]: http://www.haproxy.org/
[nginx]: https://www.nginx.com/
[SQL injection]: https://www.owasp.org/index.php/SQL_Injection
[XSS]: https://www.owasp.org/index.php/Cross-site_Scripting_(XSS)
[n2proxy]:https://github.com/txn2/n2proxy
[go]: https://golang.org/
[Forward Proxy vs. Reverse Proxy]:https://www.jscape.com/blog/bid/87783/Forward-Proxy-vs-Reverse-Proxy
[IOT]: https://en.wikipedia.org/wiki/Internet_of_things
[json]: https://www.json.org/
[curl]: https://curl.haxx.se/docs/manpage.html
[net/http/httputil]:https://golang.org/pkg/net/http/httputil/
[net/http]: https://golang.org/pkg/net/http/
[http.ListenAndServe]:https://golang.org/pkg/net/http/#ListenAndServe
[http.ListenAndServeTLS]:https://golang.org/pkg/net/http/#ListenAndServeTLS
[server.go]: https://github.com/txn2/n2proxy/blob/master/server.go
[package]: https://thenewstack.io/understanding-golang-packages/
[json_pp]: https://www.google.com/search?q=json_pp
[jsonpp]: https://www.google.com/search?q=jsonpp
[flag]: https://golang.org/pkg/flag/
[zap]: https://github.com/uber-go/zap
[http.HandleFunc]: https://golang.org/pkg/net/http/#HandleFunc
[NewSingleHostReverseProxy]:https://golang.org/pkg/net/http/httputil/#NewSingleHostReverseProxy
[ReverseProxy]:https://golang.org/pkg/net/http/httputil/#ReverseProxy
[httputil]: https://golang.org/pkg/net/http/httputil/
[rweng]: https://github.com/txn2/n2proxy/blob/master/rweng/rweng.go
[yaml configuration]: https://github.com/txn2/n2proxy/blob/master/cfg.yml
[regex patterns]: http://www.rexegg.com/regex-quickstart.html
[go templates]: https://blog.gopheracademy.com/advent-2017/using-go-templates/
[Go Concurrency Patterns: Pipelines and cancellation]:https://blog.golang.org/pipelines
[php-fpm]: https://php-fpm.org/
[Drupal]: http://www.drupal.com/
[Wordpress]: https://wordpress.org/