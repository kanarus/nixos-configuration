setopt INTERACTIVE_COMMENTS

# handle `/` as a word segment
WORDCHARS=${WORDCHARS//\//}

# enable Ctrl-{left, right} to move by words
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Ctrl-{A, E} for move to {head, tail} of line
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

# enable {up, down} to complete only with history matching current input & move cursor to end
bindkey "^[OA" history-beginning-search-backward
bindkey "^[OB" history-beginning-search-forward

function self_insert_with_log() {
  echo "KEYS='$KEYS'" >> ~/debug2.log
  zle .self-insert
}
zle -N self-insert self_insert_with_log

# prompt style
function git_status_color() {
  git_status_output=$(git status --short)
  if [ -z "$git_status_output" ]; then
    echo '157'
  else
    echo '197'
  fi
}
function maybe_git_branch() {
  git_output=$(git symbolic-ref --short HEAD 2>&1)
  if [[ $git_output =~ '^fatal: ' ]]; then
    echo ''
  else
    echo '(%F{'"$(git_status_color)"'}'"$git_output"'%F{153})'
  fi
}
setopt PROMPT_SUBST
export PS1='%F{153}[%n%F{111}@%m%F{153}:%~]$(maybe_git_branch)%f '

# aliases
alias helix='hx'
alias la='ls -al'
function merged () {
  to="${1:-main}"
  from=$(git branch --show-current)
  git switch $to && git pull origin $to
  git branch -D $from
}

# abbreviations
typeset -Ag abbreviations
abbreviations=(
  "ns"   "sudo nixos-rebuild switch --flake ~/nixos-configuration"
  "com"  "git add . && git commit -m"
  "po"   "git push origin"
  "push" "git push"
  "ed"   "echo 'use flake path:.' > .envrc && direnv allow"
  "x"    "helix"
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
