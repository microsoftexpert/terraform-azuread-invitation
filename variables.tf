###############################################################################
# tf_mod_azuread_invitation — variables
#
# Manages a single Azure AD B2B guest invitation (azuread_invitation).
#
# NOTE: azuread_invitation is a CREATE-ONLY resource. It cannot be imported and
# the Graph API exposes no update operation — every argument below is therefore
# effectively # IMMUTABLE. Changing any value forces Terraform to destroy and
# recreate the invitation, which re-sends a brand-new invitation email and
# mints a fresh one-time redeem_url. Tenant-scoped: no resource_group_name.
###############################################################################

variable "user_email_address" {
 description = <<EOT
The email address of the external user being invited into the tenant.

# IMMUTABLE — create-only. Changing this destroys the invitation and sends a new
one to the new address.
EOT
 type = string

 validation {
 condition = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.user_email_address))
 error_message = "user_email_address must be a valid email address (e.g. guest@partner.com)."
 }
}

variable "redirect_url" {
 description = <<EOT
The URL the invited user is redirected to once the invitation is redeemed
(e.g. "https://myapps.microsoft.com" or "https://portal.azure.com"). Must be an
https URL — plaintext http redirect targets are rejected by this module.

# IMMUTABLE — create-only. Changing this forces destroy/recreate of the invitation.
EOT
 type = string

 validation {
 condition = can(regex("^https://", var.redirect_url))
 error_message = "redirect_url must be a non-empty https:// URL."
 }
}

variable "user_display_name" {
 description = <<EOT
Optional display name shown for the invited guest user in the directory and in
the invitation email. When omitted, Entra ID derives a display name from the
email address.

# IMMUTABLE — create-only. Changing this forces destroy/recreate of the invitation.
EOT
 type = string
 default = null
}

variable "user_type" {
 description = <<EOT
The user type the invitee is created as. Defaults to "Guest" (the secure,
least-privilege default for external B2B collaboration). "Member" grants the
invitee the same directory access as an internal member and can only be set by
a Global Administrator — opt in explicitly.

Allowed values: "Guest", "Member".

# IMMUTABLE — create-only. Changing this forces destroy/recreate of the invitation.
EOT
 type = string
 default = "Guest"

 validation {
 condition = contains(["Guest", "Member"], var.user_type)
 error_message = "user_type must be one of: Guest, Member."
 }
}

variable "message" {
 description = <<EOT
Optional invitation message configuration. Omit (leave null) to suppress the
invitation email entirely — no message is sent and the caller is responsible for
delivering the redeem_url out of band.

{
 additional_recipients = optional(list(string), []) # extra recipients of the invite email; Azure supports AT MOST 1
 body = optional(string, null) # custom message body; MUTUALLY EXCLUSIVE with language
 language = optional(string, null) # ISO 639 locale for the default message (provider default "en-US"); MUTUALLY EXCLUSIVE with body
}

NOTE: body and language cannot both be set — body supplies your own text, while
language only selects the locale of the built-in default message.

# IMMUTABLE — create-only. Changing this forces destroy/recreate of the invitation.
EOT
 type = object({
 additional_recipients = optional(list(string), [])
 body = optional(string, null)
 language = optional(string, null)
 })
 default = null

 validation {
 condition = var.message == null ? true: !(try(var.message.body, null) != null && try(var.message.language, null) != null)
 error_message = "message.body and message.language are mutually exclusive — set at most one."
 }

 validation {
 condition = var.message == null ? true: length(try(var.message.additional_recipients, [])) <= 1
 error_message = "message.additional_recipients supports at most 1 address (Azure limitation)."
 }
}

variable "timeouts" {
 description = <<EOT
Optional Terraform operation timeouts for this resource. azuread_invitation is
create-only, so only create, read, and delete are supported (there is no update).
EOT
 type = object({
 create = optional(string)
 read = optional(string)
 delete = optional(string)
 })
 default = {}
}
