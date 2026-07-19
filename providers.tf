terraform {
 required_version = ">= 1.12.0"

 required_providers {
 azuread = {
 source = "hashicorp/azuread"
 version = ">= 2.0, < 4.0"
 }
 }
}
