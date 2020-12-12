# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

PATH=$PATH:$HOME/.local/bin:$HOME/bin

if [ -d "${HOME}/.bashrc.d" ]; then
  for file in ${HOME}/.bashrc.d/*.sh; do
    source "${file}"
  done
fi
