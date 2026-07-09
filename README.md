# dotfiles

## これは

irukasano 用 dotfiles です。

* lessで h を左スクロール、l を右スクロールにする
* less で色つけする
* markdown は `leaf` で閲覧する
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

### add LESSOPEN

<~/.config/fish/config.fish>
set -x LESS "-R"
set -x LESSOPEN "||/usr/bin/lesspipe.sh %s"

### markdown viewer

`leaf` は `make all` に含まれます。単体では `make leaf` でもインストールできます。


