#!/usr/bin/env bash
# One snapshot of a PR's automated-feedback state, read against the head SHA.
#
#   gh-pr-status.sh OWNER/REPO PR_NUMBER [SINCE_ISO8601]
#
# SINCE filters issue comments (bot summaries, triage, size suggestions) to
# those posted at or after that time; omit it to see the last ten.
set -euo pipefail

[[ $# -ge 2 ]] || { sed -n '2,7p' "$0" >&2; exit 2; }
repo="$1" number="$2" since="${3:-}"

gh pr view "$number" --repo "$repo" \
  --json state,headRefOid,mergeStateStatus,reviewDecision,autoMergeRequest,statusCheckRollup \
  --jq '"head:        \(.headRefOid)  (\(.state))",
        "merge state: \(.mergeStateStatus)  review: \(.reviewDecision // "none")  auto-merge: \(.autoMergeRequest.mergeMethod // "off")",
        "checks not green:",
        ([.statusCheckRollup[]
          | select(.name != null)
          | select((.conclusion // .status) as $c | $c != "SUCCESS" and $c != "SKIPPED" and $c != "NEUTRAL")
          | "  \(.name): \(.conclusion // .status)"] | if length == 0 then "  (none)" else .[] end)'

echo "unresolved threads:"
gh api graphql -F owner="${repo%%/*}" -F repo="${repo##*/}" -F number="$number" \
  -f query='query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) { pullRequest(number: $number) {
      reviewThreads(first: 100) { nodes {
        id isResolved path line comments(first: 1) { nodes { author { login } body } } } } } } }' \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)]
        | if length == 0 then "  (none)" else
          .[] | "  \(.id)\t\(.path):\(.line // "-")\t\(.comments.nodes[0].author.login)\t\(.comments.nodes[0].body | split("\n")[0])" end'

echo "issue comments${since:+ since $since}:"
gh api "repos/$repo/issues/$number/comments?per_page=100" \
  | jq -r --arg since "$since" '[.[] | select($since == "" or .created_at >= $since)]
    | (if $since == "" then .[-10:] else . end)
    | if length == 0 then "  (none)" else
      .[] | "  \(.created_at)  \(.user.login)\n    \(.body | split("\n") | map(select(length > 0)) | .[0:2] | join(" | ") | .[0:220])" end'
