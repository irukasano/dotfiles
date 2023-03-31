YUM = dnf

all: init dotfiles-all fish-all nvim-all

dotfiles-all: python3 grcat pandoc source-highlight dotfiles-repo

init:
    sudo $(YUM) install -y tar

python3:
    sudo $(YUM) install -y python3

grcat:
    sudo wget http://kassiopeia.juls.savba.sk/~garabik/software/grc/grc_1.12.orig.tar.gz -O /usr/local/src/grc_1.12.orig.tar.gz
    cd /usr/local/src; sudo tar xzf grc_1.12.orig.tar.gz
    cd /usr/local/src/grc-1.12; sudo ./install.sh

pandoc:
    sudo $(YUM) install -y pandoc

source-highlight:
    sudo $(YUM) install -y source-highlight

dotfiles-repo:
    lesskey ~/dotfiles/.lesskey
    ls -1 ~/dotfiles/.gitconfig ~/dotfiles/.grcat.mysql ~/dotfiles/.lessfilter ~/dotfiles/.agignore | xargs -I@ sh -c 'ln -s @ ~/`basename @`'
    cp -p ~/dotfiles/.my.cnf ~/

fish-all: fish fisherman fzf fish-repo

fish:
    sudo $(YUM) install -y fish

fisherman:
    fish -c "curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher"

fzf:
    fish -c "fisher install jethrokuan/fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install

fish-repo:
    cd ~/.config; mv fish fish.bak
    git clone https://github.com/irukasano/config.fish.git ~/.config/fish
    cd ~/.config/fish; git submodule update --init

nvim-all: nodejs nvim-repo

nodejs:
    sudo $(YUM) install -y nodejs npm

nvim-repo:
    mkdir -p ~/.vim
    git clone https://github.com/irukasano/init.vim ~/.config/nvim
    ln -s ~/.config/nvim/init.vim ~/.vimrc
    ln -s ~/.config/nvim/coc-settings.json ~/.vim/coc-settings.json


