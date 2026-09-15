#!/bin/sh
set -eu

root=$(mktemp -d)
trap 'rm -rf "$root" "/tmp/openclaw-$fake_uid"' EXIT HUP INT TERM
fake_uid=987654321
mkdir -p "$root/bin"

cat > "$root/bin/id" <<EOF
#!/bin/sh
printf '%s\n' '$fake_uid'
EOF
cat > "$root/bin/op" <<'EOF'
#!/bin/sh
case "$1 $2" in
  'service-account ratelimit') printf '%s\n' 'account read_write daily 1000 999' ;;
  'read op://vault/item/field') printf '%s\n' 'fresh-secret' ;;
  *) exit 2 ;;
esac
EOF
chmod 755 "$root/bin/id" "$root/bin/op"
printf '%s\n' 'test-token' > "$root/token"
chmod 600 "$root/token"

PATH="$root/bin:$PATH" \
OP_SECRET_CACHE_TOKEN_FILE="$root/token" \
OP_SECRET_CACHE_OP_BIN="$root/bin/op" \
  ./op-secret-cache/op-secret-cache TEST_SECRET op://vault/item/field > "$root/first"

cache_dir="/tmp/openclaw-$fake_uid"
[ "$(cat "$root/first")" = 'fresh-secret' ]
[ "$(stat -c '%a' "$cache_dir")" = 700 ]
[ "$(stat -c '%a' "$cache_dir/TEST_SECRET")" = 600 ]
[ "$(stat -c '%a' "$cache_dir/.TEST_SECRET.lock")" = 600 ]

: > "$cache_dir/TEST_SECRET"
PATH="$root/bin:$PATH" \
OP_SECRET_CACHE_TOKEN_FILE="$root/token" \
OP_SECRET_CACHE_OP_BIN="$root/bin/op" \
  ./op-secret-cache/op-secret-cache TEST_SECRET op://vault/item/field > "$root/recovered"
[ "$(cat "$root/recovered")" = 'fresh-secret' ]
[ "$(cat "$cache_dir/TEST_SECRET")" = 'fresh-secret' ]

printf '%s\n' 'op-secret-cache tests passed.'
