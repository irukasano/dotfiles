# dotfiles

## update lesskey

    $ lesskey ~/dotfiles/.lesskey
    $ ls ~/.less

## install grcat

    $ yum install python3
    $ wget http://kassiopeia.juls.savba.sk/~garabik/software/grc/grc_1.11.3.orig.tar.gz
    $ tar xzf grc_1.11.3.orig.tar.gz
    $ cd grc-1.11.3
    $ sudo ./install.sh

※ただし CentOs6 の場合、python3 はインストールできないので以下の手順でインストールする

    $ curl -s https://www.python.org/downloads/source/ | grep -i latest
    $ wget https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
    $ tar Jxf Python-3.8.0.tar.xz
    $ cd Python-3.8.0
    $ ./configure  --prefix=/usr/local
    $ make
    $ make altinstall
    $ ln -s /usr/local/bin/python3.8 /usr/bin/python3
    $ ln -s /usr/local/bin/pip3.8 /usr/bin/pip3


## install pandoc

    $ yum install pandoc


## add LESSOPEN, LESSCLOSE

    <~/.config/fish/config.fish>
    set LESSOPEN "~/dotfiles/lessopen.sh %s"
    set LESSCLOSE "~/dotfiles/lessclose.sh %s %s"

