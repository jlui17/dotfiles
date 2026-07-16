#!/bin/zsh
budgeting() {
  cd ~/src/personal/budgeting && bun claude --model claude-sonnet-5 --settings '{"advisorModel":"opus"}'
}
