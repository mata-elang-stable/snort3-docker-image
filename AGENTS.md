# AGENTS.md

## Build Commands

```bash
# Local build (debian)
make build

# Local build (alpine)
make build-alpine

# Multi-arch push to registry (uses docker-bake.hcl)
make build-push
```

## CI Notes

- Workflows trigger on `v2.0` branch, not `main`
- CI uses a custom runner `image-builder` — not `ubuntu-latest`
- Cleanup workflow only runs on PR close, uses custom token env vars

## Linting

- `.hadolint.yaml` ignores: `DL3003`, `DL3008`, `DL3018`, `SC2046`