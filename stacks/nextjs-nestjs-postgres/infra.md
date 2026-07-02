# Infra appendix — not applicable

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

This pack is **deployment-platform-agnostic**: it binds frameworks (Next.js, NestJS, Prisma on Postgres), not a cloud. The base `infra/CLAUDE.md` — including its default cloud binding — applies unchanged.

The pack's deploy-seam obligations — `prisma migrate deploy` and the Next build shipping through the cloud pipeline — live in `db.md` §CI checks and the pack `README.md` §Deploy seam.

## Conflict register

_No conflicts — this appendix only adds bindings; the base contract is unchanged._
