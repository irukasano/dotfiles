YUM ?= dnf

NVM_DIR             := $(HOME)/.nvm
NVM_SH              := $(NVM_DIR)/nvm.sh
NVM_URL             := https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh

.PHONY: all
all: init dotfiles-all fish-all nvim-all ag fd gh osc52

.PHONY: dotfiles-all
dotfiles-all: python3 grcat pandoc source-highlight dotfiles-repo

.PHONY: init
init:
	sudo $(YUM) update
	sudo $(YUM) install -y tar sysstat
	sudo $(YUM) install -y kitty-terminfo

.PHONY: python3
python3:
	sudo $(YUM) install -y python3

.PHONY: grcat
grcat:
	sudo wget http://kassiopeia.juls.savba.sk/~garabik/software/grc/grc_1.12.orig.tar.gz -O /usr/local/src/grc_1.12.orig.tar.gz
	cd /usr/local/src; sudo tar xzf grc_1.12.orig.tar.gz
	cd /usr/local/src/grc-1.12; sudo ./install.sh

.PHONY: pandoc
pandoc:
	sudo $(YUM) install -y pandoc

.PHONY: source-highlight
source-highlight:
	sudo $(YUM) install -y source-highlight

.PHONY: dotfiles-repo
dotfiles-repo:
	lesskey ~/dotfiles/.lesskey
	ls -1 ~/dotfiles/.gitconfig ~/dotfiles/.grcat.mysql ~/dotfiles/.lessfilter ~/dotfiles/.agignore ~/dotfiles/.tmux.conf | xargs -I@ sh -c 'ln -sf @ ~/`basename @`'
	cp -p ~/dotfiles/.my.cnf ~/

.PHONY: ag
ag:
	#sudo $(YUM) install -y silversearcher-ag
	sudo $(YUM) install -y ag

.PHONY: fd
fd:
	sudo $(YUM) install -y fd-find

.PHONY: gh
gh:
	sudo $(YUM) install -y gh

.PHONY: fzf
fzf:
	@if [ ! -d "$$HOME/.fzf" ]; then \
		git clone --depth 1 https://github.com/junegunn/fzf.git $$HOME/.fzf; \
	fi
	@if [ ! -x "$$HOME/.fzf/bin/fzf" ]; then \
		$$HOME/.fzf/install --bin; \
	fi
	@command -v fzf >/dev/null 2>&1 || sudo ln -sf $$HOME/.fzf/bin/fzf /usr/local/bin/fzf

.PHONY: starship
starship:
	@if [ -x /usr/local/bin/starship ]; then \
		echo "starship already installed at /usr/local/bin/starship; skipping install."; \
	else \
		curl -sS https://starship.rs/install.sh | sh; \
	fi
	ln -sf $(PWD)/config/starship.toml $(HOME)/.config/starship.toml

.PHONY: fish-all
fish-all: fzf starship fish fish-link fish-plugins

.PHONY: fish
fish:
	sudo $(YUM) install -y fish

.PHONY: fish-link
fish-link:
	@mkdir -p $$HOME/.config/fish
	@ln -snf "$$HOME/dotfiles/config/fish/config.fish"  "$$HOME/.config/fish/config.fish"
	@ln -snf "$$HOME/dotfiles/config/fish/fish_plugins" "$$HOME/.config/fish/fish_plugins"
	@# 自作 functions がある場合のみ、ファイル単位でリンク（生成物混入を避ける）
	@if [ -d "$$HOME/dotfiles/config/fish/functions" ]; then \
	  mkdir -p "$$HOME/.config/fish/functions"; \
	  for f in "$$HOME"/dotfiles/config/fish/functions/*.fish; do \
	    [ -e "$$f" ] || continue; \
	    bn=$$(basename "$$f"); \
	    ln -snf "$$f" "$$HOME/.config/fish/functions/$$bn"; \
	  done; \
	fi

.PHONY: fish-plugins
fish-plugins: fish-link
	@fish -lc 'type -q fisher; or curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
	@fish -lc 'fisher update'

.PHONY: nvim-all
nvim-all: nodejs nvim-repo

.PHONY: nodejs-init
nodejs-init:
	@if [ ! -d "$(NVM_DIR)" ]; then \
			curl -o- $(NVM_URL) | bash; \
	fi

.PHONY: nodejs
nodejs: nodejs-init
	@echo "Installing latest LTS version."
	@export NVM_DIR="$(NVM_DIR)"; \
	[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
	nvm install --lts; \
	nvm use --lts >/dev/null; \
	LTS_VERSION="$$(nvm version 'lts/*')"; \
	echo "Detected LTS version: $$LTS_VERSION"; \
	grep -q 'nvm_default_version' $$HOME/.bashrc || { \
		echo '' >> $$HOME/.bashrc; \
		echo 'export nvm_default_version="'"$$LTS_VERSION"'"' >> $$HOME/.bashrc; \
		echo 'nvm use "$$nvm_default_version" >/dev/null 2>&1 || true' >> $$HOME/.bashrc; \
	}

.PHONY: nvim-repo
nvim-repo:
	mkdir -p ~/.vim
	git clone https://github.com/irukasano/init.vim ~/.config/nvim
	ln -s ~/.config/nvim/init.vim ~/.vimrc
	ln -s ~/.config/nvim/coc-settings.json ~/.vim/coc-settings.json

.PHONY: codex
codex: nodejs
	@export NVM_DIR="$(NVM_DIR)"; \
	[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
	nvm use --lts >/dev/null; \
	cd "$$HOME"; \
	npm install -g @openai/codex; \
	mkdir -p "$$HOME/.codex"; \
	sh -c '\
	CONFIG_FILE="$$HOME/.codex/config.toml"; \
	NOTIFY_LINE="notify = [\"$$HOME/dotfiles/bin/notify-backhaul.sh\"]"; \
	touch "$$CONFIG_FILE"; \
	if ! grep -qxF "$$NOTIFY_LINE" "$$CONFIG_FILE"; then \
		TMP_FILE=$$(mktemp); \
		echo "$$NOTIFY_LINE" > "$$TMP_FILE"; \
		cat "$$CONFIG_FILE" >> "$$TMP_FILE"; \
		mv "$$TMP_FILE" "$$CONFIG_FILE"; \
	fi'

.PHONY: codex-gh-mcp
codex-gh-mcp:
	sudo $(YUM) install -y python3.11 python3.11-pip
	mkdir -p $(HOME)/mcp
	if [ ! -d "$(HOME)/mcp/gh-mcp" ]; then \
		git clone https://github.com/munch-group/gh-mcp.git $(HOME)/mcp/gh-mcp; \
	else \
		cd $(HOME)/mcp/gh-mcp && git pull; \
	fi
	python3.11 -m pip install --user mcp
	@mkdir -p ~/.codex
	@sh -c '\
	CONFIG_FILE="$$HOME/.codex/config.toml"; \
	GH_SECTION="[mcp_servers.gh]"; \
	GH_COMMAND="command = \"python3.11\""; \
	GH_ARGS="args = [\"$$HOME/mcp/gh-mcp/server.py\"]"; \
	touch "$$CONFIG_FILE"; \
	if ! grep -q "^\[mcp_servers\.gh\]" "$$CONFIG_FILE"; then \
		printf "\n%s\n%s\n%s\n" "$$GH_SECTION" "$$GH_COMMAND" "$$GH_ARGS" >> "$$CONFIG_FILE"; \
	else \
		echo "mcp_servers.gh already exists in $$CONFIG_FILE; skipping config append."; \
	fi'

.PHONY: uv
uv:
	curl -LsSf https://astral.sh/uv/install.sh | sh

.PHONY: tmux
tmux:
	sudo $(YUM) install -y tmux
	mkdir -p ~/.tmux
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	tmux source ~/.tmux.conf

.PHONY: osc52
osc52:
	sudo mkdir -p /usr/local/src
	sudo curl -L https://raw.githubusercontent.com/libapps/libapps-mirror/main/hterm/etc/osc52.sh -o /usr/local/src/osc52.sh
	sudo chmod +x /usr/local/src/osc52.sh
	sudo ln -sf /usr/local/src/osc52.sh /usr/local/bin/osc52.sh

.PHONY: develop
develop: zellij git-gtr tig codex codex-gh-mcp

.PHONY: zellij
zellij:
	sudo mkdir -p /usr/local/src
	mkdir -p $$HOME/bin
	cd /usr/local/src; sudo wget https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-no-web-x86_64-unknown-linux-musl.tar.gz
	cd /usr/local/src; sudo tar xvzf zellij-no-web-x86_64-unknown-linux-musl.tar.gz
	cd /usr/local/src; sudo mv zellij /usr/local/bin
	ln -sf "$$HOME/dotfiles/bin/zellij-worktree.sh" $$HOME/bin
	mkdir -p $$HOME/.config/zellij/layouts
	zellij setup --dump-config > $$HOME/.config/zellij/config.kdl
	@grep -q '^theme ' $$HOME/.config/zellij/config.kdl || printf '\ntheme "pencil-light"\n' >> $$HOME/.config/zellij/config.kdl
	@sed -i 's/^[[:space:]]*keybinds {[[:space:]]*$$/keybinds clear-defaults=true {/' $$HOME/.config/zellij/config.kdl
	@sed -i 's/bind "Ctrl /bind "Alt /g' $$HOME/.config/zellij/config.kdl
	ln -sf "$$HOME/dotfiles/config/zellij/layouts/default.kdl" "$$HOME/.config/zellij/layouts"

.PHONY: git-gtr
git-gtr:
	sudo mkdir -p /usr/local/src
	sudo rm -rf /usr/local/src/git-worktree-runner
	cd /usr/local/src; sudo git clone https://github.com/coderabbitai/git-worktree-runner.git
	cd /usr/local/src/git-worktree-runner; sudo ln -sf "$$(pwd)/bin/git-gtr" /usr/local/bin/git-gtr

.PHONY: tig
tig:
	sudo $(YUM) -y install xmlto
	sudo mkdir -p /usr/local/src
	sudo rm -rf /usr/local/src/tig
	cd /usr/local/src; sudo git clone https://github.com/jonas/tig.git
	cd /usr/local/src; sudo chown -R user tig
	cd /usr/local/src/tig; make
	cd /usr/local/src/tig; make install
	cd /usr/local/src/tig; make install-doc

# --- yazi ------------------------------------------------------------
ifeq ($(YUM),apt)
YAZI_DEPS := fd-find ripgrep poppler-utils ffmpegthumbnailer p7zip-full file chafa unzip
else
YAZI_DEPS := fd-find ripgrep poppler-utils ffmpegthumbnailer p7zip p7zip-plugins file chafa unzip
endif

.PHONY: yazi
yazi: fzf
	# deps (fzf は既存タスクで入る前提)
	sudo $(YUM) install -y $(YAZI_DEPS)

	# Ubuntu の fd-find は fdfind なので fd に寄せる（存在しない場合のみ）
	@if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then \
		sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
	fi

	# yazi (musl) を GitHub Releases から取得
	sudo mkdir -p /usr/local/src
	@tmpdir="$$(mktemp -d)"; \
	zipfile="$$tmpdir/yazi.zip"; \
	echo "Downloading yazi (musl) ..."; \
	curl -L -o "$$zipfile" https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip; \
	unzip -q "$$zipfile" -d "$$tmpdir"; \
	sudo install -m 0755 "$$tmpdir"/*/yazi /usr/local/bin/yazi; \
	sudo install -m 0755 "$$tmpdir"/*/ya   /usr/local/bin/ya; \
	rm -rf "$$tmpdir"; \
	yazi --version
