# CI/CD Release Pipeline

An end-to-end release automation project: **GitHub Actions CI/CD, Bash deployment scripts, multi-environment releases, health checks and automatic rollback** for a small FastAPI service.

## What it does

| Stage | Tooling | What happens |
|---|---|---|
| Continuous Integration | GitHub Actions | flake8 lint, unittest on a Python 3.10/3.11/3.12 matrix, ShellCheck, Docker image build, release-flow smoke test |
| Release management | `scripts/release.sh` | Semantic version bump from git tags, auto-generated `CHANGELOG.md`, annotated tag |
| Continuous Deployment | GitHub Actions + `scripts/deploy.sh` | Tag push builds and publishes an image to GHCR, deploys to **staging** automatically, then **production** behind a manual approval gate |
| Safe deploys | `scripts/deploy.sh` | Versioned release directories, atomic `current` symlink switch, `/health` verification with retries |
| Recovery | `deploy.sh` / `rollback.sh` | A failed health check restores the previous release automatically; manual rollback is one command |

## Layout

```
app/                FastAPI service (/health, /version)
tests/              unittest suite
scripts/            deploy.sh, rollback.sh, release.sh, healthcheck.sh, service.sh, smoke_test.sh
.github/workflows/  ci.yml (every push/PR), cd.yml (on v* tags)
Dockerfile          container image used by CI/CD
Makefile            make lint | test | smoke | ci
```

## Run it locally

```bash
pip install -r requirements.txt
make ci                                   # lint + unit tests + full release-flow smoke test

./scripts/deploy.sh staging v1.0.0        # deploy
./scripts/deploy.sh staging v1.1.0        # upgrade
./scripts/deploy.sh staging v1.2.0 --simulate-bad-release   # health check fails -> auto-rollback to v1.1.0
./scripts/rollback.sh staging             # manual rollback to previous release
curl localhost:8101/version
```

Staging runs on port 8101 and production on 8102 (override with `STAGING_PORT` / `PRODUCTION_PORT`).

## Releasing

```bash
./scripts/release.sh patch                # tags e.g. v0.0.1 and updates CHANGELOG.md
git push origin main --follow-tags        # triggers cd.yml
```

Set required reviewers on the `production` environment in **Settings > Environments** to enable the approval gate.

## Design notes

- **Atomic switch:** a temp symlink is renamed over `current`, so there is never a half-deployed state.
- **Rollback safety:** the previous release directory is kept (newest 3 retained) so recovery needs no rebuild.
- **Proven behaviour:** `scripts/smoke_test.sh` runs deploy, upgrade, bad release with auto-rollback, and manual rollback on every CI run.
- **Simulated targets:** environments are local release directories so the whole pipeline runs for free on a GitHub runner; swapping `service.sh` for `ssh`/`docker compose`/cloud CLI commands targets a real server.
