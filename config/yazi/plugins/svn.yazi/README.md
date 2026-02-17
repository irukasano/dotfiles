# svn.yazi

Local Yazi functional plugin to run basic Subversion operations.

## Purpose

This plugin provides minimal SVN integration:

- `update` selected file(s) or directory(ies)
- `commit` selected file(s) or directory(ies)

It calls the `svn` CLI directly.

## Installation

Place this directory under:

```
~/.config/yazi/plugins/svn.yazi/
```

Or symlink it from your dotfiles:

```
ln -s ~/dotfiles/config/yazi/plugins/svn.yazi \
      ~/.config/yazi/plugins/svn.yazi
```

## Keymap Example

Add to `~/.config/yazi/keymap.toml`:

```toml
[[manager.prepend_keymap]]
on = ["s", "u"]
run = "plugin svn -- action=update"
desc = "SVN Update"

[[manager.prepend_keymap]]
on = ["s", "c"]
run = "plugin svn -- action=commit"
desc = "SVN Commit"
```

## Behavior

- If files are selected, they are used as targets.
- Otherwise, the currently hovered file/directory is used.
- Each target is validated using `svn info`.
- `commit` prompts for a commit message.
- All operations are executed asynchronously.

## Requirements

- `svn` must be available in PATH.
- Yazi must support functional plugins (0.2+).

## Notes

- Recursive behavior follows SVN defaults.
- No automatic `add` or `resolve` handling is implemented.
- For advanced workflows, extend `main.lua`.

This is intentionally minimal and designed for personal dotfiles usage.

