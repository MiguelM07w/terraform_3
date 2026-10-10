output "resource_group_name" {
  description = "Nombre del grupo de recursos."
  value       = azurerm_resource_group.site.name
}

output "storage_account_name" {
  description = "Nombre de la cuenta de almacenamiento que aloja el sitio."
  value       = azurerm_storage_account.site.name
}

output "site_documents" {
  description = "Documentos publicados en el contenedor $web."
  value       = [azurerm_storage_blob.index.name, azurerm_storage_blob.error.name]
}

output "static_website_url" {
  description = "URL pública del sitio estático."
  value       = azurerm_storage_account.site.primary_web_endpoint

  # La URL existe desde que se crea la cuenta; se publica hasta que el sitio
  # tiene contenido para no entregar un enlace que responda 404.
  depends_on = [azurerm_storage_blob.index, azurerm_storage_blob.error]
}
