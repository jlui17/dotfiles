#!/usr/bin/env bash
# List a GitHub PR's unresolved review threads, or resolve one by thread ID.
# gh has no subcommand for review threads, so both go through the GraphQL API.
#
#   gh-resolve-review-thread.sh list OWNER/REPO PR_NUMBER
#   gh-resolve-review-thread.sh resolve THREAD_ID
set -euo pipefail

usage() {
  sed -n '2,6p' "$0" >&2
  exit 2
}

list() {
  local owner="${1%%/*}" repo="${1##*/}" number="$2"
  gh api graphql \
    -F owner="$owner" -F repo="$repo" -F number="$number" \
    -f query='query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes { id isResolved path line comments(first: 1) { nodes { author { login } body } } }
          }
        }
      }
    }' \
    --jq '.data.repository.pullRequest.reviewThreads.nodes[]
      | select(.isResolved == false)
      | "\(.id)\t\(.path):\(.line // "-")\t\(.comments.nodes[0].author.login)\t\(.comments.nodes[0].body | split("\n")[0])"'
}

resolve() {
  gh api graphql \
    -F threadId="$1" \
    -f query='mutation($threadId: ID!) {
      resolveReviewThread(input: {threadId: $threadId}) { thread { id isResolved } }
    }' \
    --jq '.data.resolveReviewThread.thread | "\(.id)\tresolved=\(.isResolved)"'
}

case "${1:-}" in
  list)    [ $# -eq 3 ] || usage; list "$2" "$3" ;;
  resolve) [ $# -eq 2 ] || usage; resolve "$2" ;;
  *)       usage ;;
esac
