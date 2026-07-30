#!/bin/zsh
cdotfiles() {
  cd ~/src/personal/dotfiles && claude --model claude-opus-5 --settings '{"advisorModel":"opus"}'
}
