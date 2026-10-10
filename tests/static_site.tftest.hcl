# Pruebas nativas de Terraform. Se ejecutan con:  terraform test
# Usan un proveedor simulado: no requieren credenciales de Azure ni crean
# recursos, por lo que sirven para validar la práctica antes de desplegarla.

mock_provider "azurerm" {}

# terraform test también lee terraform.tfvars; se fijan aquí todos los valores
# para que el resultado no dependa de la configuración local de cada quien.
variables {
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  organization             = "utvt"
  project_name             = "portal"
  environment              = "qa"
  location                 = "mexicocentral"
  unique_suffix            = "001"
  storage_replication_type = "LRS"
  tags = {
    managed_by = "terraform"
  }
}

run "nombres_siguen_la_convencion" {
  command = plan

  assert {
    condition     = azurerm_resource_group.site.name == "rg-utvt-portal-qa-mxc-001"
    error_message = "El grupo de recursos no sigue la convención de nombres."
  }

  assert {
    condition     = azurerm_storage_account.site.name == "stutvtportalqamxc001"
    error_message = "La cuenta de almacenamiento no sigue la convención de nombres."
  }

  assert {
    condition     = azurerm_resource_group.site.location == "mexicocentral"
    error_message = "La región por defecto debe ser mexicocentral."
  }
}

run "etiquetas_comunes" {
  command = plan

  assert {
    condition = azurerm_storage_account.site.tags == tomap({
      managed_by  = "terraform"
      project     = "portal"
      environment = "qa"
      location    = "mexicocentral"
    })
    error_message = "La cuenta de almacenamiento no tiene las etiquetas comunes."
  }

  assert {
    condition     = azurerm_resource_group.site.tags == azurerm_storage_account.site.tags
    error_message = "Todos los recursos deben compartir las mismas etiquetas."
  }
}

run "cuenta_de_almacenamiento_segura" {
  command = plan

  assert {
    condition     = azurerm_storage_account.site.https_traffic_only_enabled
    error_message = "La cuenta debe aceptar únicamente HTTPS."
  }

  assert {
    condition     = azurerm_storage_account.site.min_tls_version == "TLS1_2"
    error_message = "La cuenta debe exigir TLS 1.2 como mínimo."
  }

  assert {
    condition     = !azurerm_storage_account.site.allow_nested_items_to_be_public
    error_message = "La cuenta no debe permitir acceso anónimo a sus contenedores."
  }
}

run "sitio_publica_inicio_y_error" {
  command = plan

  assert {
    condition     = azurerm_storage_blob.index.name == "index.html" && azurerm_storage_blob.error.name == "404.html"
    error_message = "Los blobs deben llamarse igual que los documentos configurados en el sitio."
  }

  assert {
    condition     = azurerm_storage_blob.index.content_type == "text/html; charset=utf-8"
    error_message = "La página principal debe servirse como HTML en UTF-8."
  }

  assert {
    condition = alltrue([
      for dato in ["rg-utvt-portal-qa-mxc-001", "stutvtportalqamxc001", "mexicocentral", "QA"] :
      strcontains(azurerm_storage_blob.index.source_content, dato)
    ])
    error_message = "La plantilla debe mostrar los datos reales del despliegue."
  }
}

run "blobs_se_suben_al_contenedor_web" {
  command = plan

  # El proveedor no valida este ID hasta el apply, así que aquí se comprueba
  # que el construido en locals.tf tenga la forma de un contenedor de ARM.
  override_resource {
    target          = azurerm_storage_account.site
    override_during = plan
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-utvt-portal-qa-mxc-001/providers/Microsoft.Storage/storageAccounts/stutvtportalqamxc001"
    }
  }

  assert {
    condition     = azurerm_storage_blob.index.storage_container_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-utvt-portal-qa-mxc-001/providers/Microsoft.Storage/storageAccounts/stutvtportalqamxc001/blobServices/default/containers/$web"
    error_message = "La página principal debe subirse al contenedor $web de la cuenta."
  }

  assert {
    condition     = azurerm_storage_blob.error.storage_container_id == azurerm_storage_blob.index.storage_container_id
    error_message = "Ambas páginas deben subirse al mismo contenedor."
  }
}

run "sufijo_unico_cambia_el_nombre" {
  command = plan

  variables {
    unique_suffix = "angel"
    environment   = "dev"
    location      = "canadacentral"
  }

  assert {
    condition     = azurerm_storage_account.site.name == "stutvtportaldevcacangel"
    error_message = "El nombre debe componerse con el ambiente, la región y el sufijo único."
  }
}

run "rechaza_ambiente_invalido" {
  command = plan

  variables {
    environment = "produccion"
  }

  expect_failures = [var.environment]
}

run "rechaza_sufijo_con_caracteres_invalidos" {
  command = plan

  variables {
    unique_suffix = "Mi_Nombre"
  }

  expect_failures = [var.unique_suffix]
}

run "rechaza_suscripcion_invalida" {
  command = plan

  variables {
    subscription_id = "mi-suscripcion"
  }

  expect_failures = [var.subscription_id]
}

run "rechaza_nombre_de_cuenta_demasiado_largo" {
  command = plan

  # Cada variable es válida por separado, pero juntas suman 31 caracteres.
  variables {
    project_name  = "portalalumno"
    unique_suffix = "angel123"
  }

  expect_failures = [azurerm_storage_account.site]
}
