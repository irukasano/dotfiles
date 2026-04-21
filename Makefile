YUM ?= dnf

NVM_DIR             := $(HOME)/.nvm
NVM_SH              := $(NVM_DIR)/nvm.sh
NVM_URL             := https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh

SRC_DIR             := $(HOME)/src

.PHONY: help
help: ## タスク一覧を表示
	@grep -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "%-20s %s\n", $$1, $$2}'

.PHONY: all
all: base codex-all tmux yazi ## 全インストール(base+codex+tmux+yazi)

.PHONY: base
base: init osc52 tools-all fish-all gnupg-link nvim-all ## 共通インストール(osc52+tools+fish+gnupg+nvim)


.PHONY: init
init:
	sudo $(YUM) update
	sudo $(YUM) install -y tar sysstat kitty-terminfo
	sudo $(YUM) install -y gnupg pinentry pinentry-tty
	sudo $(YUM) install -y --setopt=install_weak_deps=False pass

.PHONY: gnupg-link
gnupg-link:
	@mkdir -p "$$HOME/.gnupg"
	@chmod 700 "$$HOME/.gnupg"
	ln -snf "$$HOME/dotfiles/config/gnupg/gpg-agent.conf" "$$HOME/.gnupg/gpg-agent.conf"

#---------------------------------------------------------------------------------#
# scripting runtimes
#---------------------------------------------------------------------------------#
ifeq ($(YUM),apt)
PYTHON3_PKGS := python3
else
PYTHON3_PKGS := python3 python3.11 python3.11-pip
endif

.PHONY: python3
python3:
	sudo $(YUM) install -y $(PYTHON3_PKGS)

.PHONY: perl
perl:
	sudo $(YUM) install -y perl

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

#---------------------------------------------------------------------------------#
# Compiled language toolchains
#---------------------------------------------------------------------------------#
.PHONY: rustup
rustup:
	curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y

.PHONY: cargo
cargo:
	test -x "$$HOME/.cargo/bin/cargo" || $(MAKE) rustup

#---------------------------------------------------------------------------------#
# tools-all
#---------------------------------------------------------------------------------#
.PHONY: tools-all
tools-all: init python3 grcat pandoc source-highlight dotfiles-repo ## 初期 dotfiles
#---------------------------------------------------------------------------------#
# grcat
#---------------------------------------------------------------------------------#
.PHONY: grcat
grcat:
	sudo wget http://kassiopeia.juls.savba.sk/~garabik/software/grc/grc_1.12.orig.tar.gz -O /usr/local/src/grc_1.12.orig.tar.gz
	cd /usr/local/src; sudo tar xzf grc_1.12.orig.tar.gz
	cd /usr/local/src/grc-1.12; sudo ./install.sh

#---------------------------------------------------------------------------------#
# pandoc
#---------------------------------------------------------------------------------#
.PHONY: pandoc
pandoc:
	sudo $(YUM) install -y pandoc

#---------------------------------------------------------------------------------#
# source-highlight
#---------------------------------------------------------------------------------#
.PHONY: source-highlight
source-highlight:
	sudo $(YUM) install -y source-highlight

#---------------------------------------------------------------------------------#
# searcher
#---------------------------------------------------------------------------------#
.PHONY: ag
ag:
	#sudo $(YUM) install -y silversearcher-ag, ripgrep
	sudo $(YUM) install -y ag ripgrep fd-find

#---------------------------------------------------------------------------------#
# my dotfiles settings
#---------------------------------------------------------------------------------#
.PHONY: dotfiles-repo
dotfiles-repo:
	lesskey ~/dotfiles/.lesskey
	ls -1 ~/dotfiles/.gitconfig ~/dotfiles/.grcat.mysql ~/dotfiles/.lessfilter ~/dotfiles/.agignore | xargs -I@ sh -c 'ln -sf @ ~/`basename @`'
	cp -p ~/dotfiles/.my.cnf ~/

#---------------------------------------------------------------------------------#
# gh
#---------------------------------------------------------------------------------#
.PHONY: gh
gh:
	sudo $(YUM) install -y gh
	@mkdir -p $$HOME/bin
	ln -sf $(PWD)/bin/gh $(HOME)/bin/gh
	ln -sf $(PWD)/bin/rg-gh-pr.sh $(HOME)/bin/rg-gh-pr.sh
	ln -sf $(PWD)/bin/gh-pr-create.sh $(HOME)/bin/gh-pr-create.sh
	@git config --file "$$HOME/.gitconfig.local" --unset-all credential.https://github.com.helper >/dev/null 2>&1 || true
	@git config --file "$$HOME/.gitconfig.local" --add credential.https://github.com.helper ""
	@git config --file "$$HOME/.gitconfig.local" --add credential.https://github.com.helper "!$$HOME/bin/gh auth git-credential"
	@git config --file "$$HOME/.gitconfig.local" --unset-all credential.https://gist.github.com.helper >/dev/null 2>&1 || true
	@git config --file "$$HOME/.gitconfig.local" --add credential.https://gist.github.com.helper ""
	@git config --file "$$HOME/.gitconfig.local" --add credential.https://gist.github.com.helper "!$$HOME/bin/gh auth git-credential"

#---------------------------------------------------------------------------------#
# fzf
#---------------------------------------------------------------------------------#
.PHONY: fzf
fzf:
	@if [ ! -d "$$HOME/.fzf" ]; then \
		git clone --depth 1 https://github.com/junegunn/fzf.git $$HOME/.fzf; \
	fi
	@if [ ! -x "$$HOME/.fzf/bin/fzf" ]; then \
		$$HOME/.fzf/install --bin; \
	fi
	@command -v fzf >/dev/null 2>&1 || sudo ln -sf $$HOME/.fzf/bin/fzf /usr/local/bin/fzf

#---------------------------------------------------------------------------------#
# fish-all
#---------------------------------------------------------------------------------#
.PHONY: fish-all
fish-all: fzf starship fish fish-link fish-plugins

.PHONY: starship
starship:
	@if [ -x /usr/local/bin/starship ]; then \
		echo "starship already installed at /usr/local/bin/starship; skipping install."; \
	else \
		curl -sS https://starship.rs/install.sh | sh; \
	fi
	@mkdir -p $$HOME/.config
	ln -sf $(PWD)/config/starship.toml $(HOME)/.config/starship.toml

.PHONY: fish
fish:
	sudo $(YUM) install -y fish

.PHONY: fish-link
fish-link:
	@mkdir -p $$HOME/.config/fish
	@ln -sf "$$HOME/dotfiles/config/fish/config.fish"  "$$HOME/.config/fish/config.fish"
	@host="$$(hostname -s)"; \
	ln -sf "$(HOME)/dotfiles/config/fish/config-$$host.fish" "$(HOME)/.config/fish/config-$$host.fish"
	@ln -sf "$$HOME/dotfiles/config/fish/fish_plugins" "$$HOME/.config/fish/fish_plugins"
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

#---------------------------------------------------------------------------------#
# nvim-all
#---------------------------------------------------------------------------------#
.PHONY: nvim
nvim:
	sudo $(YUM) install -y neovim

.PHONY: nvim-all
nvim-all: nvim nvim-settings-repo

.PHONY: nvim-settings-repo
nvim-settings-repo:
	@mkdir -p "$$HOME/.config" "$$HOME/.vim"
	@if [ -d "$$HOME/.config/nvim/.git" ]; then \
		git -C "$$HOME/.config/nvim" pull --ff-only; \
	elif [ -e "$$HOME/.config/nvim" ]; then \
		echo "$$HOME/.config/nvim exists but is not a git repository; refusing to modify it." >&2; \
		exit 1; \
	else \
		git clone https://github.com/irukasano/init.vim "$$HOME/.config/nvim"; \
	fi
	ln -snf "$$HOME/.config/nvim/init.vim" "$$HOME/.vimrc"
	ln -snf "$$HOME/.config/nvim/coc-settings.json" "$$HOME/.vim/coc-settings.json"

#---------------------------------------------------------------------------------#
# codex-all
#---------------------------------------------------------------------------------#
.PHONY: codex-all
codex-all: codex codex-config codex-gh-mcp codex-settings ## codex-cli

.PHONY: codex
codex: nodejs
	@export NVM_DIR="$(NVM_DIR)"; \
	[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
	nvm use --lts >/dev/null; \
	cd "$$HOME"; \
	npm install -g @openai/codex; \
	mkdir -p "$$HOME/bin"; \
	ln -sf "$$HOME/dotfiles/bin/codex-with-gh" "$$HOME/bin/codex-with-gh"

.PHONY: codex-config
codex-config:
	@mkdir -p "$$HOME/.codex"
	@CONFIG_FILE="$$HOME/.codex/config.toml"; \
	OLD_MARKER="# auto config by irukasano/dotfiles"; \
	BEGIN_MARKER="# BEGIN auto config by irukasano/dotfiles"; \
	END_MARKER="# END auto config by irukasano/dotfiles"; \
	if [ -f "$$CONFIG_FILE" ] && { grep -qxF "$$OLD_MARKER" "$$CONFIG_FILE" || grep -qxF "$$BEGIN_MARKER" "$$CONFIG_FILE"; }; then \
		echo "$$CONFIG_FILE already managed by irukasano/dotfiles; skipping."; \
	else \
		printf '%s\n' \
			"$$BEGIN_MARKER" \
			'sandbox_mode = "workspace-write"' \
			'approval_policy = "on-request"' \
			'approvals_reviewer = "guardian_subagent"' \
			'model = "gpt-5.4"' \
			'notify = ["'"$$HOME"'/dotfiles/bin/notify-backhaul.sh"]' \
			'personality = "pragmatic"' \
			'' \
			'[tui]' \
			'notification_method = "bel"' \
			'notifications = ["agent-turn-complete", "approval-requested"]' \
			'' \
			'[features]' \
			'guardian_approval = true' \
			"$$END_MARKER" \
			> "$$CONFIG_FILE"; \
	fi

.PHONY: codex-gh-mcp
codex-gh-mcp: python3 codex-config gh
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

.PHONY: codex-settings
codex-settings:
	mkdir -p ~/.codex
	ln -sf "$$HOME/dotfiles/config/codex/AGENTS.md" $$HOME/.codex

#---------------------------------------------------------------------------------#
# tmux
#---------------------------------------------------------------------------------#
.PHONY: tmux
tmux: fish-all codex-all osc52 gh git-gtr
	sudo $(YUM) install -y tmux
	mkdir -p "$$HOME/.config/tmux"
	mkdir -p "$$HOME/.tmux/plugins"
	ln -snf "$$HOME/dotfiles/config/.tmux.conf" "$$HOME/.config/.tmux.conf"
	ln -snf "$$HOME/dotfiles/config/tmux/tmux.conf" "$$HOME/.config/tmux/tmux.conf"
	ln -sf "$$HOME/dotfiles/bin/tmux-gh.sh" "$$HOME/bin/tmux-gh.sh"
	if [ ! -d "$$HOME/.tmux/plugins/tpm/.git" ]; then \
		git clone https://github.com/tmux-plugins/tpm "$$HOME/.tmux/plugins/tpm"; \
	else \
		git -C "$$HOME/.tmux/plugins/tpm" pull --ff-only; \
	fi
	@echo "tmux を起動して prefix + I で plugin を導入してください"

#---------------------------------------------------------------------------------#
# osc52
#---------------------------------------------------------------------------------#
.PHONY: osc52
osc52:
	#sudo mkdir -p /usr/local/src
	#sudo curl -L https://raw.githubusercontent.com/libapps/libapps-mirror/main/hterm/etc/osc52.sh -o /usr/local/src/osc52.sh
	#sudo chmod +x /usr/local/src/osc52.sh
	sudo ln -sf "$$HOME/dotfiles/bin/osc52.sh" /usr/local/bin/osc52.sh

#---------------------------------------------------------------------------------#
# zellij
#---------------------------------------------------------------------------------#
.PHONY: zellij
zellij: gh git-gtr cargo perl ## zellij multiplexer
	mkdir -p "$$HOME/bin"
	mkdir -p "$$HOME/.config/zellij/layouts"

	"$$HOME/.cargo/bin/cargo" install --locked zellij

	test ! -e /usr/local/bin/zellij || sudo mv /usr/local/bin/zellij /usr/local/bin/zellij.musl.bak
	sudo install -m 0755 "$$HOME/.cargo/bin/zellij" /usr/local/bin/zellij

	ln -sf "$$HOME/dotfiles/bin/zellij-worktree.sh" "$$HOME/bin/zellij-worktree.sh"
	ln -sf "$$HOME/dotfiles/bin/zellij-gh.sh" "$$HOME/bin/zellij-gh.sh"
	ln -sf "$$HOME/dotfiles/config/zellij/config.kdl" "$$HOME/.config/zellij/config.kdl"
	ln -sf "$$HOME/dotfiles/config/zellij/layouts/default.kdl" "$$HOME/.config/zellij/layouts/default.kdl"

	hash -r || true
	/usr/local/bin/zellij --version
	ldd /usr/local/bin/zellij

.PHONY: git-gtr
git-gtr:
	mkdir -p "$(SRC_DIR)"
	rm -rf "$(SRC_DIR)/git-worktree-runner"
	cd "$(SRC_DIR)/"; git clone https://github.com/coderabbitai/git-worktree-runner.git
	cd "$(SRC_DIR)/git-worktree-runner" && ./install.sh

#---------------------------------------------------------------------------------#
# tig
#---------------------------------------------------------------------------------#
.PHONY: tig-all
tig-all: tig tig-setting

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

.PHONY: tig-setting
tig-setting:
	@mkdir -p "$$HOME/.config/tig"
	ln -sf "$$HOME/dotfiles/config/tig/config" "$$HOME/.config/tig/config"

#---------------------------------------------------------------------------------#
# yazi
#---------------------------------------------------------------------------------#
ifeq ($(YUM),apt)
YAZI_DEPS := poppler-utils ffmpegthumbnailer p7zip-full file chafa unzip librsvg2-bin
else
YAZI_DEPS := poppler-utils ffmpegthumbnailer p7zip p7zip-plugins file chafa unzip librsvg2-tools
endif

.PHONY: yazi
yazi: fzf ag ## yazi filer
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

yazi-settings:
	rm -rf ~/.config/yazi/flavors
	git clone https://github.com/yazi-rs/flavors.git ~/.config/yazi/flavors
	git clone https://github.com/BennyOe/tokyo-night.yazi ~/.config/yazi/flavors/tokyo-night.yazi
	git clone https://github.com/gosxrgxx/flexoki-light.yazi ~/.config/yazi/flavors/flexoki-light.yazi
	ln -sf $(PWD)/config/yazi/yazi.toml $(HOME)/.config/yazi/yazi.toml
	ln -sf $(PWD)/config/yazi/theme.toml $(HOME)/.config/yazi/theme.toml
	ln -sf $(PWD)/config/yazi/keymap.toml $(HOME)/.config/yazi/keymap.toml
	ln -sf $(PWD)/config/yazi/vfs.toml $(HOME)/.config/yazi/vfs.toml
	ln -sf $(PWD)/config/yazi/init.lua $(HOME)/.config/yazi/init.lua

yazi-plugins: yazi
	ln -sf $(PWD)/config/yazi/plugins/smart-tab.yazi $(HOME)/.config/yazi/plugins/smart-tab.yazi
	ln -sf $(PWD)/config/yazi/plugins/svn.yazi $(HOME)/.config/yazi/plugins/svn.yazi
	ln -sf $(PWD)/config/yazi/plugins/dirsort.yazi $(HOME)/.config/yazi/plugins/dirsort.yazi
	ya pkg add imsi32/yatline
	ya pkg add yazi-rs/plugins:full-border
	ya pkg add yazi-rs/plugins:chmod
	ya pkg add dedukun/bookmarks
