# ============================================================
# commands.sh — custom shell commands & aliases
# Sourced by ~/.zshrc
# ============================================================

# ------------------------------------------------------------
# Navigation
# ------------------------------------------------------------


# ------------------------------------------------------------
# Git
# ------------------------------------------------------------
alias gmb="git branch"
alias gma="git add"
alias gmcm="git commit -m"
alias gmp="git push -f"
alias gms="git status"
alias gm="git"
alias gmc="git checkout"
alias gmcma="git commit --amend"
alias gmpull="git pull"
alias delbr="git branch -D"

# ------------------------------------------------------------
# Dev tools
# ------------------------------------------------------------
claude-window() {
  local dir="$HOME/Documents/${1}"
  dir=$(cd "$dir" 2>/dev/null && pwd) || { echo "Directory not found: ~/Documents/$1"; return 1; }

  tmux new-window -c "$dir"
  tmux send-keys "claude" Enter
  tmux split-window -h -c "$dir"
}


# ------------------------------------------------------------
# Misc
# ------------------------------------------------------------

