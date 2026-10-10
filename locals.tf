locals {
  # Abreviaturas de región usadas en los nombres. Las cinco primeras son las
  # regiones que permite la política de la suscripción Azure for Students.
  region_short = {
    mexicocentral  = "mxc"
    westus         = "wus"
    brazilsouth    = "brs"
    canadacentral  = "cac"
    norwayeast     = "noe"
    eastus         = "eus"
    eastus2        = "eus2"
    southcentralus = "scus"
  }

  region = lookup(local.region_short, var.location, var.location)

  # Ej: utvt-portal-qa-mxc-001  ->  rg-utvt-portal-qa-mxc-001
  suffix = "${var.organization}-${var.project_name}-${var.environment}-${local.region}-001"

  # Las cuentas de almacenamiento solo admiten minúsculas y números (3 a 24
  # caracteres) y su nombre es único en todo Azure.
  # Ej: stutvtportalqamxc001
  storage_account_name = "st${var.organization}${var.project_name}${var.environment}${local.region}${var.unique_suffix}"

  index_document = "index.html"
  error_document = "404.html"

  # Azure crea el contenedor $web al habilitar el sitio estático. Su ID se
  # deriva del recurso que lo habilita para que los blobs se suban después.
  web_container_id = "${azurerm_storage_account_static_website.site.storage_account_id}/blobServices/default/containers/$web"

  tags = merge(
    var.tags,
    {
      project     = var.project_name
      environment = var.environment
      location    = var.location
    }
  )
}
