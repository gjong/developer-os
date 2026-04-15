# Developer OS — minimal zsh for live / installed systems

HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

setopt hist_ignore_dups share_history extended_glob prompt_subst
autoload -Uz compinit && compinit -C

# Plugins (Arch packages)
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# vfox — version manager (installed from GitHub release in customize.sh; not in Arch [extra])
if command -v vfox >/dev/null 2>&1; then
  eval "$(vfox activate zsh)"
fi

plugins=(
  git
  gradle
  java
)

alias ll='ls -lh'
alias la='ls -lha'
alias vi='vim'
