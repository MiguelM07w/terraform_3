provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # azurerm 5.x ya no registra proveedores de recursos por su cuenta; se
  # declara el único que esta práctica necesita en la suscripción.
  resource_providers_to_register = ["Microsoft.Storage"]
}
