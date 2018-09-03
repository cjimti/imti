---
layout:     post
title:      "Don't Install Emacs"
subtitle:   "Containers as utility applications"
date:       2018-03-01
author:     "Craig Johnston"
URL:        "dont-install-emacs/"
image:      "/img/post/gnu.jpg"
twitter_image: "/img/post/gnu_876_438.jpg"
tags:
- Emacs
- Docker
---

I grew up on [emacs]. One of my first jobs I sat down at a terminal and was editing some files with [pico], it's what I knew since I used that fantastic email client [pine]. I was quickly told by my the lead developer that I need to use a **real** text editor if I'm going to progress in my career. He told me I need to try [emacs], and after suffering through a few weeks of memorizing multi command-char sequences and [training the muscle memory in my pinky to perform bizarre contortions] of my left hand just to save my file, I became a convert. I found out a few months later that the developer who convinced me to use [emacs] was a [vi] user all along. I think I was a victim of a cruel joke or hazing ritual, but I learned to love [emacs], and when I am not coding in a desktop IDE ([IntelliJ]) then I am using [emacs].

However most base server installs don't come with [emacs], and [emacs] installs a ton of extra libraries and dependencies. [Emacs] often takes a considerable bit of time to install as packages are downloaded and compiled depending on the platform.

As the world, and my company has been rapidly moving to containerization, I find [Docker] installed on more servers. [Docker] lets me leverage something I have been doing a lot of lately: container-as-command. Like monolithic or microservices, websites, databases, and on and on, containers give us dependency isolation. So with the only requirement being [Docker], I can run any utility that I can slide into a little [Alpine Linux] container.

## Running [emacs]

Since I don't want to type out a long `docker run` command every time I want [emacs] I give my `.bashrc` an alias command.

```bash
alias emacs='docker run --rm -it -v "$PWD":/src -v "$HOME":/root cjimti/emacs'
```

Now I source my `.bashrc` with `source ~/.bashrc` and I instantly have [emacs] on any [Docker] installed server or workstation. I use this on my local workstation as well as servers.

**WARNING:** Mounting a home directory with an unknown container can be a big security problem, and you would need a lot of trust in the container you are letting mount this directory. 

1. You can use the [cjimti/emacs] container as-is and trust me.
2. You can use the [cjimti/emacs] container as-is and adjust the alias not to mount your home directory. Use a [persistent volume] for .emacs and related files.
3. [You can make your own container](https://github.com/cjimti/cmd-emacs).

[persistent volume]: https://docs.docker.com/storage/volumes/
[training the muscle memory in my pinky to perform bizarre contortions]: https://en.wikipedia.org/wiki/Emacs#Emacs_pinky
[cjimti/emacs]: https://hub.docker.com/r/cjimti/emacs/
[emacs]: https://www.gnu.org/software/emacs/
[pico]: https://en.wikipedia.org/wiki/Pico_(text_editor)
[pine]: https://en.wikipedia.org/wiki/Pine_(email_client)
[vi]: https://en.wikipedia.org/wiki/Vi
[IntelliJ]: https://www.jetbrains.com/
[Docker]: https://www.docker.com/
[Alpine Linux]: https://alpinelinux.org/
