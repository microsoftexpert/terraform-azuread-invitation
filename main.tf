###############################################################################
# tf_mod_azuread_invitation — main
#
# A thin, total renderer over the typed inputs. The invitation is tenant-scoped
# and create-only; no data sources or owner wiring are required.
###############################################################################

resource "azuread_invitation" "this" {
 user_email_address = var.user_email_address
 redirect_url = var.redirect_url
 user_display_name = var.user_display_name
 user_type = var.user_type

 # Optional message block — present only when var.message is non-null.
 # Omitting it entirely suppresses the invitation email.
 dynamic "message" {
 for_each = var.message != null ? [var.message]: []
 content {
 additional_recipients = try(message.value.additional_recipients, [])
 body = try(message.value.body, null)
 language = try(message.value.language, null)
 }
 }

 # Rendered only when at least one timeout value is supplied.
 dynamic "timeouts" {
 for_each = length([for v in values(var.timeouts): v if v != null]) > 0 ? [1]: []
 content {
 create = try(var.timeouts.create, null)
 read = try(var.timeouts.read, null)
 delete = try(var.timeouts.delete, null)
 }
 }
}
