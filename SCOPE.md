# SCOPE — terraform-azuread-invitation

## In scope
- `azuread_invitation.this`

## Out of scope (consumed/handled elsewhere)
- Group membership for the invited guest → `terraform-azuread-group` (consumes `object_id`)
- Role assignment for the invited guest → `terraform-azuread-directory-role` (consumes `object_id`)
- Access package assignment → `terraform-azuread-access-package`
- Tenant External Collaboration settings (allow/block domains, who-can-invite) → tenant configuration, **not** managed by this module

## Graph API permissions required
The Terraform service principal needs **one** of the following application roles
(least-privilege first):

- `User.Invite.All` — **recommended**; grants exactly the B2B invite capability
- `User.ReadWrite.All` — broader user management alternative
- `Directory.ReadWrite.All` — broad directory write alternative

> All three are admin-consent-only — a Global Administrator must consent in the tenant.
> When authenticating as a user principal instead of an SP, the equivalent directory
> roles are `Guest Inviter`, `User Administrator`, or `Global Administrator`.

## Emits
| Output | Description | Typically consumed by |
|---|---|---|
| `object_id` | Invited user's directory object ID (alias of `user_id`) | `terraform-azuread-group` (member `object_id`), `terraform-azuread-directory-role` (principal), `terraform-azuread-access-package`, role assignments |
| `user_id` | Raw `azuread_invitation.user_id` attribute | Same as `object_id` |
| `id` | Resource ID of the invitation object | State/audit references |
| `user_email_address` | Email the invitation was sent to | Audit logs, notification pipelines |
| `user_display_name` | Display name of the invited user (may be `null`) | Logging, audit |
| `user_type` | `Guest` or `Member` | Governance/audit checks |
| `redirect_url` | Post-redemption landing URL | Audit, verification |
| `redeem_url` | **One-time invitation redemption URL — `sensitive = true`** | Delivered to invitee over a secure channel (Key Vault, secure email); never logged. Spent after acceptance. |

## Provider notes / gotchas
- **Create-only.** `azuread_invitation` has no Graph update operation and **cannot be imported**.
  Every argument is effectively immutable — changing `user_email_address`, `redirect_url`,
  `user_display_name`, `user_type`, or `message` forces destroy/recreate, which re-sends a
  new invitation email and mints a fresh `redeem_url`. To deliberately re-invite, use
  `terraform apply -replace=...`.
- **`redeem_url` is write-only-grade.** Graph returns it only at creation; it cannot be
  re-read after the guest accepts. Marked `sensitive = true` — reference only inside other
  sensitive outputs or write straight to Key Vault. Never emit as a plain string.
- **No credentials, no owners.** Invitations create no password/certificate and have no
  owner collection — there are no credential outputs to rotate (the earlier
  `<generated_credential>` placeholder did not apply and was removed).
- **`message` omitted → no email sent.** Pass `message = {}` to send the default email.
  `message.body` and `message.language` are mutually exclusive (enforced by validation);
  `additional_recipients` is capped at 1 (Azure limit, enforced by validation).
- **`user_type = "Member"` requires Global Administrator** — defaults to least-privilege `Guest`.
- **Tenant prerequisite:** External Collaboration settings (allow/block domain lists,
  who-can-invite restrictions) can reject an invitation even when SP permissions are correct.
- **`redirect_url` is https-only** by module validation (secure default).
- **Graph replication delay:** allow ~30–60s after creation before consuming `object_id`
  in a dependent resource within the same apply (eventual consistency).
- **Tenant-scoped** — no `resource_group_name`.

## Design decisions
- Standalone single-resource module, four-file layout, single resource named `this`.
- Primary output is `object_id` (aliased to the real `user_id` attribute) for house-style
  consistency with the rest of the azuread suite — the invitation has no `object_id`
  attribute of its own.
- `message` modeled as `optional(object(...), null)` so the empty/omitted call produces the
  safest behavior (no email), and `validation` blocks encode the provider's real constraints.
