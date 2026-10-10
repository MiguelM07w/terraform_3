# Grupo de recursos que agrupa los componentes del sitio estático.
resource "azurerm_resource_group" "site" {
  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

# Cuenta de almacenamiento de uso general v2 que aloja el sitio; solo acepta
# HTTPS con TLS 1.2 como mínimo y no permite acceso anónimo a sus contenedores.
resource "azurerm_storage_account" "site" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.site.name
  location                        = azurerm_resource_group.site.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  access_tier                     = "Hot"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  lifecycle {
    precondition {
      condition     = length(local.storage_account_name) <= 24
      error_message = "El nombre \"${local.storage_account_name}\" tiene ${length(local.storage_account_name)} caracteres y el máximo es 24. Acorta project_name o unique_suffix."
    }
  }
}

# Habilita el alojamiento de sitios estáticos: Azure crea el contenedor $web
# y sirve su contenido desde el punto de conexión web de la cuenta.
resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.site.id
  index_document     = local.index_document
  error_404_document = local.error_document
}

# Página principal del sitio, generada a partir de una plantilla con los
# datos reales del despliegue.
resource "azurerm_storage_blob" "index" {
  name                 = azurerm_storage_account_static_website.site.index_document
  storage_container_id = local.web_container_id
  type                 = "Block"
  content_type         = "text/html; charset=utf-8"

  source_content = templatefile("${path.module}/site/index.html.tftpl", {
    organization    = var.organization
    project         = var.project_name
    environment     = var.environment
    location        = var.location
    resource_group  = azurerm_resource_group.site.name
    storage_account = azurerm_storage_account.site.name
    index_document  = local.index_document
    error_document  = local.error_document
  })
}

# Página que el sitio devuelve cuando se solicita una ruta inexistente.
resource "azurerm_storage_blob" "error" {
  name                 = azurerm_storage_account_static_website.site.error_404_document
  storage_container_id = local.web_container_id
  type                 = "Block"
  content_type         = "text/html; charset=utf-8"
  source_content       = file("${path.module}/site/404.html")
}
