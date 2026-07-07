#!/bin/zsh
budgeting() {
  cd ~/src/personal/budgeting && claude --model claude-sonnet-5 --settings '{"advisorModel":"opus"}'
}
