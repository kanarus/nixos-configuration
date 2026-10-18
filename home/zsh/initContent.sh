setopt INTERACTIVE_COMMENTS

export WORDCHARS='!#$^-'

# bind Ctrl-Backspace to `backward-kill-word` (same as Ctrl-w)
bindkey "^H" backward-kill-word

# enable Ctrl-{left, right} to move by words
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Ctrl-{A, E} for move to {head, tail} of line
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

# enable {up, down} to complete only with history matching current input & move cursor to end
bindkey "^[OA" history-beginning-search-backward
bindkey "^[OB" history-beginning-search-forward

# prompt style
function git_status_color() {
  git_status_output=$(git status --short)
  if [ -z "$git_status_output" ]; then
    echo '112'
  else
    echo '204'
  fi
}
function maybe_git_branch() {
  git_output=$(git symbolic-ref --short HEAD 2>&1)
  if [[ $git_output =~ '^fatal: ' ]]; then
    echo ''
  else
    echo '(%F{'"$(git_status_color)"'}'"$git_output"'%F{69})'
  fi
}
setopt PROMPT_SUBST
export PS1='%F{69}[%n%F{63}@%m%F{69}:%~]$(maybe_git_branch)%f '

# aliases
alias la='ls -alh --group-directories-first'
function merged () {
  to="${1:-main}"
  from=$(git branch --show-current)
  git switch "$to" && git pull origin "$to"
  git branch -D "$from"
}

# abbreviations
typeset -Ag abbreviations
abbreviations=(
  "ns"   "sudo nixos-rebuild switch --flake ~/nixos-configuration"
  "com"  "git add . && git commit -m"
  "po"   "git push origin"
  "push" "git push"
  "ed"   "echo 'use flake' > .envrc && direnv allow"
  "edp"  "echo 'use flake path:.' > .envrc && direnv allow"
  "n"    "nvim ."
)
function expand_abbreviation() {
  local MATCH
  setopt EXTENDED_GLOB
  LBUFFER="${LBUFFER%%(#m)[_a-zA-Z0-9]#}"
  unsetopt EXTENDED_GLOB
  LBUFFER+="${abbreviations[$MATCH]:-$MATCH}"
  zle self-insert
}
zle -N expand_abbreviation
bindkey " " expand_abbreviation
bindkey -M isearch " " self-insert
