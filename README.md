# Práctica · Sitio web estático en Azure con Terraform

Infraestructura como código (IaC) que despliega en Microsoft Azure un **sitio web estático** alojado en una cuenta de almacenamiento. Terraform crea la infraestructura y también publica el contenido: la página principal se genera desde una plantilla con los datos reales del despliegue.

> Universidad Tecnológica del Valle de Toluca · Ingeniería en Desarrollo y Gestión de Software

## Recursos que se crean

| # | Recurso | Tipo de Terraform | Nombre generado (valores por defecto) |
|---|---|---|---|
| 1 | Grupo de recursos | `azurerm_resource_group` | `rg-utvt-portal-qa-mxc-001` |
| 2 | Cuenta de almacenamiento | `azurerm_storage_account` | `stutvtportalqamxc001` |
| 3 | Sitio web estático | `azurerm_storage_account_static_website` | contenedor `$web` |
| 4 | Página principal | `azurerm_storage_blob` | `index.html` |
| 5 | Página de error | `azurerm_storage_blob` | `404.html` |

```
rg-utvt-portal-qa-mxc-001
└── st…  Cuenta de almacenamiento · StorageV2 · Standard LRS · HTTPS · TLS 1.2
      └── Sitio estático ──────────► https://<cuenta>.z##.web.core.windows.net
            └── $web  (contenedor que crea Azure al habilitar el sitio)
                  ├── index.html  ◄── site/index.html.tftpl + datos del despliegue
                  └── 404.html    ◄── site/404.html
```

Cada recurso depende del anterior, y Terraform deduce el orden a partir de las referencias entre ellos: no hay ningún `depends_on` entre recursos.

## Estructura del proyecto

```
.
├── terraform.tf              # Versión mínima de Terraform y proveedor azurerm ~> 5.0
├── providers.tf              # Configuración del proveedor y registro de Microsoft.Storage
├── variables.tf              # Variables de entrada con validaciones
├── locals.tf                 # Convención de nombres y etiquetas comunes
├── main.tf                   # Definición de los 5 recursos
├── output.tf                 # Salidas: nombres de recursos y URL del sitio
├── terraform.tfvars.example  # Plantilla de valores (copiar a terraform.tfvars)
├── .terraform.lock.hcl       # Versión exacta del proveedor (azurerm 5.9.0)
├── site/
│   ├── index.html.tftpl      # Plantilla de la página principal
│   └── 404.html              # Página de error
└── tests/
    └── static_site.tftest.hcl  # Pruebas nativas de Terraform (sin credenciales)
```

## Convención de nombres

Los nombres usan los prefijos de tipo de recurso del Cloud Adoption Framework de Microsoft:

```
<prefijo>-<organización>-<proyecto>-<ambiente>-<región>-<instancia>
   rg    -    utvt     -   portal  -   qa     -  mxc   -   001
```

La cuenta de almacenamiento es la excepción, porque Azure solo admite en su nombre letras minúsculas y números (de 3 a 24 caracteres) y exige que sea único en todo Azure. Por eso se escribe sin guiones y termina con `unique_suffix`:

```
st + utvt + portal + qa + mxc + <unique_suffix>   →   stutvtportalqamxcangel
```

Si la combinación supera los 24 caracteres, el plan se detiene con un mensaje que indica qué acortar.

## Requisitos

- Terraform `>= 1.13.0`
- Azure CLI con sesión iniciada (`az login`)
- Una suscripción de Azure (por ejemplo, Azure for Students)

Azure for Students solo permite desplegar en algunas regiones. Para consultar las de tu suscripción:

```bash
az policy assignment list --query "[].parameters.listOfAllowedLocations.value | []" -o tsv
```

## Uso

1. Entra a la carpeta del proyecto, inicia sesión en Azure y obtén el ID de tu suscripción:
   ```bash
   az login
   az account show --query id -o tsv
   ```
2. Crea tu archivo de variables a partir de la plantilla y edítalo:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Coloca tu `subscription_id` y cambia `unique_suffix` por tu nombre o matrícula.
3. Inicializa, da formato y valida:
   ```bash
   terraform init
   terraform fmt -recursive
   terraform validate
   ```
4. Ejecuta las pruebas (no requieren credenciales ni crean recursos):
   ```bash
   terraform test
   ```
5. Revisa el plan, que debe terminar con `Plan: 5 to add, 0 to change, 0 to destroy.`:
   ```bash
   terraform plan -out=qa.tfplan
   ```
   La primera vez, Terraform registra el proveedor de recursos `Microsoft.Storage` en la suscripción; puede tardar un par de minutos.
6. Aplica los cambios:
   ```bash
   terraform apply qa.tfplan
   ```
7. Consulta las salidas y abre el sitio en el navegador:
   ```bash
   terraform output
   terraform output -raw static_website_url
   ```
   Para comprobar la página de error, agrega cualquier ruta inexistente a la URL.
8. Al terminar la práctica, elimina los recursos:
   ```bash
   terraform destroy
   ```

Para cambiar el contenido del sitio, edita los archivos de `site/` y vuelve a ejecutar `terraform apply`: Terraform detecta el cambio y reemplaza únicamente el blob afectado.

## Pruebas

`tests/static_site.tftest.hcl` usa un proveedor simulado (`mock_provider`), por lo que se ejecuta sin iniciar sesión en Azure. Comprueba:

- Que los nombres y las etiquetas siguen la convención.
- Que la cuenta solo acepta HTTPS, exige TLS 1.2 y no permite acceso anónimo.
- Que se publican `index.html` y `404.html` en el contenedor `$web`, y que la plantilla muestra los datos del despliegue.
- Que las validaciones rechazan un ambiente inexistente, un sufijo con caracteres inválidos, un ID de suscripción mal formado y un nombre de cuenta de más de 24 caracteres.

## Salidas

| Output | Descripción |
|---|---|
| `resource_group_name` | Nombre del grupo de recursos |
| `storage_account_name` | Nombre de la cuenta de almacenamiento |
| `site_documents` | Documentos publicados en el contenedor `$web` |
| `static_website_url` | URL pública del sitio estático |

## Seguridad y costos

- `subscription_id` está marcado como `sensitive` y `terraform.tfvars` está excluido por `.gitignore`.
- Los archivos `*.tfstate` nunca se suben al repositorio: además de los ID de la infraestructura, guardan las claves de acceso de la cuenta de almacenamiento.
- La cuenta solo acepta HTTPS, exige TLS 1.2 y no permite acceso anónimo a sus contenedores. El sitio es público únicamente a través de su punto de conexión web, que es el propósito de la práctica.
- El costo es mínimo: unos cuantos KB en almacenamiento Standard LRS. Aun así, ejecuta `terraform destroy` al terminar.

## Notas sobre azurerm 5.x

Dos diferencias respecto a versiones anteriores del proveedor que afectan a esta práctica:

- **Registro de proveedores de recursos.** azurerm 5.x ya no registra proveedores de recursos automáticamente. `providers.tf` declara `Microsoft.Storage` en `resource_providers_to_register` para no tener que registrarlo a mano.
- **Referencia al contenedor.** `azurerm_storage_blob` ya no recibe el nombre de la cuenta y del contenedor, sino `storage_container_id`. Como el contenedor `$web` lo crea Azure y no Terraform, su ID se construye en `locals.tf` a partir del recurso que habilita el sitio; así los blobs se suben siempre después de que el contenedor existe.

## Referencias

- [Alojamiento de sitios web estáticos en Azure Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
- [Abreviaturas de recursos de Azure (CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [Documentación del proveedor azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Pruebas en Terraform](https://developer.hashicorp.com/terraform/language/tests)
