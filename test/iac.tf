# Created these resources within the Aqua Customer Success Account

# Canada-Central/Quebec is geographically closest to Boston, Burlington MA.
#Placing Registry in the US nearest Boston -
# https://www.google.com/search?q=distance+burlington+ma+to+quebec+city+canada&client=firefox-b-d&sxsrf=AOaemvJlgmRHow7PH2ZE0DU2OeHkJzJRRA%3A1634647259473&ei=27xuYcyzHJPAgweqv5CYCw&oq=distance+burlington+ma+to+quebec+city+canada&gs_lcp=Cgdnd3Mtd2l6EAMYATIICCEQFhAdEB4yCAghEBYQHRAeOgQIIRAKSgQIQRgBUOMsWJg0YMk8aAJwAHgAgAFkiAHAA5IBAzUuMZgBAKABAcABAQ&sclient=gws-wiz
# https://build5nines.com/map-azure-regions/


resource "azurerm_resource_group" "tap-rg" {
  location = "canadaeast"
  name     = "TapCleanProdRegistry"
  # name = "aquapartnersrepo"  # you can use this code to create a new clean repo for aquapartnersrepo instead.
}

# Standard SKU - reg storage is 100gb - not enough for everyone if we have 10 different users ( 94 images ) 16 and
# This totals to 150gb * n users  - using Premium is a more flexible option
# cost is .49p per day
#
# Premium Registry gives us 500gb p/month -
# Cost is approximately £8.60 per 7 days / £1.23 p/day

resource "azurerm_container_registry" "tap-reg" {
  name                = "prodtapreg"
  resource_group_name = azurerm_resource_group.tap-rg.name
  location            = "canadaeast"

  # Prem SKU required for Extra storage and AZ replication so that it exists in the US and UK - saves latency
  sku = "Premium"
  admin_enabled = "true"

  georeplications = [
    {
#      virginia
      location                = "East US"
      zone_redundancy_enabled = true
      tags                    = {}
    },
    {
#       UK- London
      location                = "UK South"
      zone_redundancy_enabled = true
      tags                    = {}
    }]
}

# used token for account and to allow docker access via that token, which we can revoke without needing to give users
# the admin passwords.
#ref https://docs.microsoft.com/en-gb/azure/container-registry/container-registry-repository-scoped-permissions

#resource "azurerm_container_registry_scope_map" "team1-scope" {
#name                    = "example-scope-map"
#container_registry_name = azurerm_container_registry.tap-reg.name
#resource_group_name     = azurerm_resource_group.tap-rg.name
#  actions = [
#    "repositories/repo1/content/read",
#    "repositories/repo1/content/write",
#    "repositories/team1/content/read",
#    "repositories/team1/content/write"
#    ]
#}

#resource "azurerm_container_registry_token" "team1-token" {
#name                    = "team1-token"
#container_registry_name = azurerm_container_registry.tap-reg.name
#resource_group_name     = azurerm_resource_group.tap-rg.name
#scope_map_id            = azurerm_container_registry_scope_map.team1-scope.id
#}


resource "azurerm_user_assigned_identity" "team1" {
  location            = azurerm_resource_group.tap-rg.location
  name                = "team1"
  resource_group_name = azurerm_resource_group.tap-rg.name

}

resource "azurerm_role_assignment" "team1-role" {
  principal_id = azurerm_user_assigned_identity.team1.id
  role_definition_name = "test"
  scope        = azurerm_container_registry.tap-reg.id
}

data "azurerm_subscription" "primary" {

}

resource "azurerm_role_definition" "test" {
  name        = "test"
#  scope       = data.azurerm_subscription.primary.id
  scope       =     azurerm_container_registry.tap-reg.id

  description = "This is a custom role created via Terraform"

  permissions {
    actions     = ["*"]
    not_actions = []
  }

  assignable_scopes = [
#    data.azurerm_subscription.primary.id, # /subscriptions/00000000-0000-0000-0000-000000000000
    azurerm_container_registry.tap-reg.id
  ]
}
