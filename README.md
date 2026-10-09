# dotfiles

Personal shell and tmux configuration for macOS.

## Layout

```
commands.sh        shell aliases and functions, sourced by ~/.zshrc
tmux/
  tmux.conf        tmux config, sourced by ~/.tmux.conf
```

## Install

```sh
git clone https://github.com/rnarayan7/dotfiles.git ~/Documents/personal/dotfiles
cd ~/Documents/personal/dotfiles

# shell
echo 'source "$HOME/Documents/personal/dotfiles/commands.sh"' >> ~/.zshrc

# tmux
echo 'source-file ~/Documents/personal/dotfiles/tmux/tmux.conf' > ~/.tmux.conf
brew install tpm
```

Both lines point at the repo, so edits take effect directly with no copy step.

The `.zshrc` and `.tmux.conf` lines hardcode `~/Documents/personal/dotfiles`, so
clone to that path or adjust both.

## commands.sh

### Git aliases

| Alias | Command |
|---|---|
| `gm` | `git` |
| `gms` | `git status` |
| `gmb` | `git branch` |
| `gmc` | `git checkout` |
| `gma` | `git add` |
| `gmcm` | `git commit -m` |
| `gmcma` | `git commit --amend` |
| `gmp` | `git push -f` |
| `gmpull` | `git pull` |
| `delbr` | `git branch -D` |

`gmp` force-pushes. Fine for personal branches, not for anything shared.

### claude-window

```sh
claude-window <path-under-Documents> [window-name]
```

Opens a tmux window at `~/Documents/<path>`, starts `claude` in the left pane, and
splits a plain shell on the right. Creates the directory if it doesn't exist.
Window name defaults to the directory's basename.

```sh
claude-window personal/dotfiles      # window named "dotfiles"
claude-window work/api-server api    # window named "api"
```

## tmux

`~/.tmux.conf` is a stub that sources `tmux/tmux.conf` from this repo. The shared
config stays version controlled, and anything machine-specific goes in the stub below
the `source-file` line.

tmux reads `~/.tmux.conf` first, then `$XDG_CONFIG_HOME/tmux/tmux.conf`, then
`~/.config/tmux/tmux.conf`. The stub takes the first slot.

What the config does:

- prefix rebound to `C-a`
- splits and new windows open in the current pane's directory, via
  `-c "#{pane_current_path}"` on the `"`, `%`, and `c` bindings
- `prefix : cl` opens a split running `claude`
- darker background on the active pane
- windows with a bell turn red in the status bar and in the window tree (`prefix + w`)
- tmux-resurrect and tmux-continuum, saving every 15 min and restoring on start

The `-c` bindings matter because tmux has no option for this. `default-path` was removed
in 1.9 and nothing replaced it, so without `-c` a new pane inherits the *session's*
working directory, which is fixed at session creation and never follows your `cd`s.

TPM itself comes from Homebrew, and the config loads it from
`/opt/homebrew/opt/tpm/share/tpm/tpm`. That's the Apple Silicon prefix; on an Intel Mac,
change the `run` line to `/usr/local/opt/tpm/share/tpm/tpm`.

Plugins aren't vendored here. TPM clones them into `~/.tmux/plugins/`, so a new machine
needs `brew install tpm` from the install step above, then `prefix + I` to fetch them.

Reload after editing:

```sh
tmux source-file ~/.tmux.conf
```

## Branches

This repo began as a fork of [awdeorio/dotfiles](https://github.com/awdeorio/dotfiles).
`master` still holds that upstream history, which shares no commits with `main` and is
being removed. `main` is the default branch and the only one in use.
