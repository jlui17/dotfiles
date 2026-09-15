# 1Password secret cache

`op-secret-cache` resolves one immutable 1Password reference through a service
account and caches it in protected runtime storage. Callers own the service
account selection and the meaning of the secret; this helper owns the shared
locking, quota check, file permissions, and atomic refresh mechanics.

Set `OP_SERVICE_ACCOUNT_TOKEN` directly, or point
`OP_SECRET_CACHE_TOKEN_FILE` at a caller-specific token file. The helper reads
that file only on a cache miss, and the resolved service-account token remains
inside the helper process.

Pass a stable uppercase cache key and an immutable `op://` reference. Add
`--refresh` after the backing vault item changes. The secret is written to
stdout so callers can capture and export it without placing it in arguments.
