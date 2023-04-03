# dotfiles

## これは

irukasano 用 dotfiles です。

* lessで h を左スクロール、l を右スクロールにする
* less で色つけする 
* mysql コマンドラインクライアントに色づけする* 
* my default gitignore 

## INSTALL

```bash
$ cd ~
$ git clone https://github.com/irukasano/dotfiles.git
$ cd ~/dotfiles
$ make
```

### grcat

※ CentOS6 の場合、python3 は以下の手順でインストールする

```bash
$ curl -s https://www.python.org/downloads/source/ | grep -i latest
$ wget https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
$ tar Jxf Python-3.8.0.tar.xz
$ cd Python-3.8.0
$ ./configure  --prefix=/usr/local
$ make
$ make altinstall
$ ln -s /usr/local/bin/python3.8 /usr/bin/python3
$ ln -s /usr/local/bin/pip3.8 /usr/bin/pip3
```

### add LESSOPEN, LESSCLOSE

<~/.config/fish/config.fish>
set -x LESS "-R"
set -x LESSOPEN "||/usr/bin/lesspipe.sh %s"
set -x LESSCLOSE "~/dotfiles/lessclose.sh %s %s"

### もしLESSの色付け整形がうまくいかない場合

とくにCentOS6ならlessバージョンが古いので以下パッチをあてる

</usr/bin/lesspipe.sh>

```diff
36a37,44
> # Allow for user defined filters
> if [ -x ~/.lessfilter ]; then
>         ~/.lessfilter "$1"
>         if [ $? -eq 0 ]; then
>                 exit 0
>         fi
> fi
>
```


