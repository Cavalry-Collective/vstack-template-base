# Add-on: multi-tenancy

Multi-tenancy lets several organisations share one deployment while keeping their data, members, settings, files, jobs, and billing isolated.

Adopt it before creating the first tenant-owned table. Choose one tenant noun and use it throughout the schema, code, routes, and UI. This document uses **organisation**.

## Implementation areas

### Organisation model

- Give each organisation a globally unique, URL-safe slug and a status of active, suspended, or archived.
- Let any authenticated user create an organisation. Create its owner membership and settings in the same transaction.
- Restrict slug changes to administrators and audit them.
- Add an indexed organisation foreign key to every tenant-owned table. Justify any instance-global table in its spec or migration.
- Scope tenant-specific uniqueness with the organisation ID.

### Membership and roles

- Keep user identity global and store membership and role per organisation.
- Start with `owner`, `admin`, and `member`. Let `enterprise-compliance` replace this model when adopted.
- Do not let a member grant a role above their own. Allow only owners to grant or revoke owner.
- Prevent the last active owner from leaving, being removed, or being downgraded. Lock the relevant memberships before checking.
- Remove access on the member's next request after departure or removal.
- If membership is cached, key it by user and organisation. Invalidate it synchronously and use a fallback TTL of no more than five minutes.

### Organisation resolution

Use an organisation identifier in the URL path by default. Add subdomain or custom-domain resolution only for a product requirement.

Run one guard before the handler:

1. authenticate the user;
2. confirm membership;
3. confirm the organisation is active;
4. confirm the role permits the action;
5. confirm the resource belongs to the same organisation.

- Treat client-supplied IDs and slugs as claims to verify.
- Pass the validated organisation ID inward as request context.
- Return `404` for unknown, archived, or cross-tenant resources.
- Return `403` when a member lacks permission or the organisation is suspended.
- Show an archived organisation only in the owner's membership list and unarchive flow.

### Data isolation

- Require the server-resolved organisation ID in every tenant-owned repository or query helper.
- Scope backend reads, writes, lists, aggregates, imports, and exports. Frontend filtering is not isolation.
- Add database row-level security as defence in depth when the chosen database supports it.
- Prefix file paths with the organisation ID and authorise reads through signed URLs or a backend proxy.
- Put the organisation ID in job payloads and revalidate the organisation when the job starts.
- Include the organisation ID in cache keys, audit events, analytics, and search indexes.

### Invitations and switching

- Invite by canonical email and limit the offered role to the inviter's role or below.
- Store invitation tokens hashed. Make them expiring, single-use, timing-safe to compare, and safe to log only by identifier.
- Allow one pending invitation per organisation and email. Reject an invitation for an existing member.
- Build the switcher from the caller's memberships and revalidate membership on every request.
- Show the active organisation in the UI.
- Clear tenant-scoped stores, caches, and drafts before rendering another organisation.

### Settings and operator access

- Store branding, policy, and plan settings on the organisation rather than in environment configuration.
- Implement platform-operator access as a separate surface with separate credentials and routes.
- Require an explicit reason for operator access or impersonation.
- Audit the operator, organisation, reason, actions, and outcome.

### Product screens

Provide organisation creation, switching, members, invitations, and settings. Follow the frontend requirements for page states and approved `design/` references.

## Verify

Test that:

- organisation A cannot read, change, delete, list, import, export, or fetch files from organisation B;
- cross-tenant access returns `404` and a role in one organisation grants nothing in another;
- tenant-scoped unique values can repeat across organisations;
- concurrent requests cannot remove the last owner;
- jobs refuse to run for a missing, suspended, or archived organisation;
- switching organisations clears tenant-scoped client state.

## Binds to a stack

The active stack pack identifies:

- the organisation guard and request-context mechanism;
- scoped data access and any database-level enforcement;
- tenant-scoped files and authorised reads;
- job context and revalidation;
- frontend organisation context and reset behaviour.

## Interactions

- **enterprise-compliance:** use its RBAC catalog, audit envelope, and operator rules.
- **saas-billing:** attach billing state to the organisation and resolve access through billing entitlements.
- **Base security, audit, and configuration:** treat tenant checks as authorisation, audit lifecycle changes, and keep tenant policy in organisation data.
- **Database rules:** use reversible migrations, indexed foreign keys, and composite tenant constraints.
- **test-mode:** seed at least two organisations and members for cross-tenant tests.
- **llm-calls:** attach tenant-level AI cost and usage to the organisation ID.
