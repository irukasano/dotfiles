YUM = apt

NVM_DIR             := $(HOME)/.nvm
NVM_SH              := $(NVM_DIR)/nvm.sh
NVM_URL             := https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh

.PHONY: init python3 grcat pandoc source-highlight dotfiles-repo \
	ag fd gh fish fisherman fzf fish-repo fish-nvm \
	nodejs-init nodejs nvim-repo codex tmux osc52

all: init dotfiles-all fish-all nvim-all ag fd gh tmux osc52

dotfiles-all: python3 grcat pandoc source-highlight dotfiles-repo

init:
	sudo $(YUM) update
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
	ls -1 ~/dotfiles/.gitconfig ~/dotfiles/.grcat.mysql ~/dotfiles/.lessfilter ~/dotfiles/.agignore ~/dotfiles/.tmux.conf | xargs -I@ sh -c 'ln -sf @ ~/`basename @`'
	cp -p ~/dotfiles/.my.cnf ~/

ag:
	sudo $(YUM) install -y silversearcher-ag

fd:
	sudo $(YUM) install -y fd-find

gh:
	sudo apt-get install -y gh

fish-all: fish fisherman fzf fish-repo

fish:
	sudo $(YUM) install -y fish

fisherman:
	fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

fzf:
	fish -c "fisher install jethrokuan/fzf"
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install
	sudo ln -sf ~/.fzf/bin/fzf /usr/local/bin/fzf

fish-repo:
	cd ~/.config; mv fish fish.bak
	git clone https://github.com/irukasano/config.fish.git ~/.config/fish
	cd ~/.config/fish; git submodule update --init

fish-nvm: nodejs
	fish -c "fisher install jorgebucaran/nvm.fish"
	fish -c "nvm install lts"
	fish -c "nvm use lts"

nvim-all: nodejs nvim-repo

nodejs-init:
	@if [ ! -d "$(NVM_DIR)" ]; then \
			curl -o- $(NVM_URL) | bash; \
	fi

nodejs: nodejs-init
	@echo "Installing latest LTS version."
	@export NVM_DIR="$(NVM_DIR)"; \
	[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
	nvm install --lts; \
	nvm alias default lts

nvim-repo:
	mkdir -p ~/.vim
	git clone https://github.com/irukasano/init.vim ~/.config/nvim
	ln -s ~/.config/nvim/init.vim ~/.vimrc
	ln -s ~/.config/nvim/coc-settings.json ~/.vim/coc-settings.json

codex:nodejs
	@sudo npm install -g @openai/codex
	@mkdir -p ~/.codex
	@sh -c '\
	CONFIG_FILE="$$HOME/.codex/config.toml"; \
	NOTIFY_LINE="notify = [\"$$HOME/dotfiles/bin/notify-backhaul.sh\"]"; \
	touch "$$CONFIG_FILE"; \
	if ! grep -qxF "$$NOTIFY_LINE" "$$CONFIG_FILE"; then \
		TMP_FILE=$$(mktemp); \
		echo "$$NOTIFY_LINE" > "$$TMP_FILE"; \
		cat "$$CONFIG_FILE" >> "$$TMP_FILE"; \
		mv "$$TMP_FILE" "$$CONFIG_FILE"; \
	fi'

uv:
	curl -LsSf https://astral.sh/uv/install.sh | sh

tmux:
	sudo $(YUM) install -y tmux
	mkdir -p ~/.tmux
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	tmux source ~/.tmux.conf

osc52:
	sudo mkdir -p /usr/local/src
	sudo curl -L https://raw.githubusercontent.com/libapps/libapps-mirror/main/hterm/etc/osc52.sh -o /usr/local/src/osc52.sh
	sudo chmod +x /usr/local/src/osc52.sh
	sudo ln -sf /usr/local/src/osc52.sh /usr/local/bin/osc52.sh
