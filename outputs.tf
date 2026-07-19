###############################################################################
# tf_mod_azuread_invitation — outputs
#
# Primary output is object_id (the invited user's directory object ID), the
# universal key downstream azuread modules compose on. redeem_url is the
# one-time invitation link and is write-only-grade sensitive — it must never
# appear in logs or plan output.
###############################################################################

output "object_id" {
 description = "Object ID of the invited guest/member user in Azure AD — the universal key for role assignments, group membership, and access package associations. Alias of user_id."
 value = azuread_invitation.this.user_id
}

output "user_id" {
 description = "Object ID of the invited user (azuread_invitation.user_id)."
 value = azuread_invitation.this.user_id
}

output "id" {
 description = "The resource ID of the invitation object."
 value = azuread_invitation.this.id
}

output "user_email_address" {
 description = "The email address the invitation was sent to."
 value = azuread_invitation.this.user_email_address
}

output "user_display_name" {
 description = "The display name of the invited user, if one was set or derived."
 value = try(azuread_invitation.this.user_display_name, null)
}

output "user_type" {
 description = "The user type the invitee was created as (Guest or Member)."
 value = azuread_invitation.this.user_type
}

output "redirect_url" {
 description = "The URL the invited user is redirected to after redeeming the invitation."
 value = azuread_invitation.this.redirect_url
}

output "redeem_url" {
 description = "One-time invitation redemption URL. SENSITIVE and write-only — Graph returns this only at creation; deliver it to the invitee over a secure channel and never log it. Re-read after acceptance is not possible."
 value = azuread_invitation.this.redeem_url
 sensitive = true
}
