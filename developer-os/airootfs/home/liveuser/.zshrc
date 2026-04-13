# Developer OS — minimal zsh for live / installed systems

# Java (OpenJDK default on Arch)
[[ -L /usr/lib/jvm/default ]] && export JAVA_HOME="$(readlink -f /usr/lib/jvm/default)"

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

alias ll='ls -lh'
alias la='ls -lha'
