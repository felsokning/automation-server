resource "azurerm_resource_group" "octo_resource_group" {
  location = var.resource_group_location
  name     = "${var.geographic_region}-${var.region}-OCTO-RG"
}

locals{
  rotationId = 1
}

resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when the rotation id changes.
    rotationId = local.rotationId
  }

  byte_length = 8

  depends_on = [azurerm_resource_group.octo_resource_group]
}

resource "null_resource" "master_key" {
  triggers  =  { 
    rotationId = local.rotationId 
  }

  provisioner "local-exec" {
    command = "openssl rand 16 | base64 >> ${path.module}/outputs/master_key.txt"
  }

  depends_on = [azurerm_resource_group.octo_resource_group]
}

data "local_file" "master_key" {
  filename = "${path.module}/outputs/master_key.txt"
  
  depends_on = [ null_resource.master_key ]
}

resource "random_password" "octopassword" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true

  keepers = {
    rotationId = local.rotationId
  }
}

resource "random_password" "sqlpassword" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true

  keepers = {
    rotationId = local.rotationId
  }
}

resource "azurerm_storage_account" "octo_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.octo_resource_group.location
  resource_group_name      = azurerm_resource_group.octo_resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [azurerm_resource_group.octo_resource_group]
}


resource "azurerm_storage_share" "tasklog-share" {
  name                 = "tasklog-share"
  storage_account_id    = azurerm_storage_account.octo_storage_account.id
  quota = 50

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account
    ]
}

resource "azurerm_storage_share" "artifact-share" {
  name                 = "artifact-share"
  storage_account_id    = azurerm_storage_account.octo_storage_account.id
  quota = 50

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account
    ]
}

resource "azurerm_storage_share" "repository-share" {
  name                 = "repository-share"
  storage_account_id    = azurerm_storage_account.octo_storage_account.id
  quota = 50

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account
    ]
}

resource "azurerm_storage_share" "nginx_share" {
  name                 = "nginx-share"
  storage_account_id    = azurerm_storage_account.octo_storage_account.id
  quota = 50

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account
    ]
}

resource "null_resource" "cert_request_generation" {
  triggers  =  { 
    rotationId = local.rotationId 
  }

  provisioner "local-exec" {
    command = "openssl req -new -newkey rsa:${var.certKeySize} -subj '/CN=${var.dnsNameLabel}.${var.resource_group_location}.azurecontainer.io/O=${var.organisation}/C=${var.countryCode}' -addext 'subjectAltName=DNS:${var.subjectAlternativeName}' -nodes -keyout ssl.key -out ssl.csr"
    working_dir = "${path.module}/cert-data"
  }

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account,
    azurerm_storage_share.nginx_share
    ]
}

resource "null_resource" "self_signed_cert" {
  triggers = {
    rotationId = local.rotationId
  }
  
  provisioner "local-exec" {
    command = "openssl x509 -req -days 365 -in ssl.csr -signkey ssl.key -out ssl.crt"
    working_dir = "${path.module}/cert-data"
  }

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account,
    azurerm_storage_share.nginx_share,
    null_resource.cert_request_generation
    ]
}

resource "null_resource" "nignx_config" {
  triggers  =  { 
    rotationId = local.rotationId 
  }

  provisioner "local-exec" {
    command = "az storage file upload --account-name ${azurerm_storage_account.octo_storage_account.name} --share-name ${azurerm_storage_share.nginx_share.name} --source ${path.module}/configs/nginx.conf"
  }

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account,
    azurerm_storage_share.nginx_share,
    null_resource.cert_request_generation,
    null_resource.self_signed_cert
    ]
}

resource "null_resource" "ssl_crt" {
  triggers  =  { 
    rotationId = local.rotationId 
  }

  provisioner "local-exec" {
    command = "az storage file upload --account-name ${azurerm_storage_account.octo_storage_account.name} --share-name ${azurerm_storage_share.nginx_share.name} --source ${path.module}/cert-data/ssl.crt"
  }

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account,
    azurerm_storage_share.nginx_share,
    null_resource.cert_request_generation,
    null_resource.self_signed_cert
    ]
}

resource "null_resource" "ssl_key" {
  triggers  =  { 
    rotationId = local.rotationId 
  }

  provisioner "local-exec" {
    command = "az storage file upload --account-name ${azurerm_storage_account.octo_storage_account.name} --share-name ${azurerm_storage_share.nginx_share.name} --source ${path.module}/cert-data/ssl.key"
  }

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account,
    azurerm_storage_share.nginx_share,
    null_resource.cert_request_generation,
    null_resource.self_signed_cert
    ]
}

resource "azurerm_mssql_server" "octopussqlserver" {
  name                         = "octopussqlprod"
  resource_group_name          = azurerm_resource_group.octo_resource_group.name
  location                     = azurerm_resource_group.octo_resource_group.location
  version                      = "12.0"
  administrator_login          = var.sqlAdmin
  administrator_login_password = random_password.sqlpassword.result
  minimum_tls_version          = "1.2"

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    random_password.sqlpassword
    ]
}

resource "azurerm_mssql_firewall_rule" "acifirewallrule" {
  name                = "azurecontainerinstanceconnection"
  server_id           = azurerm_mssql_server.octopussqlserver.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"

  depends_on = [
    azurerm_resource_group.octo_resource_group, 
    azurerm_mssql_server.octopussqlserver
    ]
}

resource "azurerm_mssql_database" "octopussqldb" {
  name           = "octopusdb"
  server_id      = azurerm_mssql_server.octopussqlserver.id
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "BC_Gen5_2"
  zone_redundant = false

  depends_on = [
    azurerm_resource_group.octo_resource_group, 
    azurerm_mssql_server.octopussqlserver
    ]
}

resource "azurerm_container_registry" "octo_registry" {
  name                = "octoregistry"
  resource_group_name = azurerm_resource_group.octo_resource_group.name
  location            = azurerm_resource_group.octo_resource_group.location
  sku                 = "Standard"
  admin_enabled       = true
  depends_on = [ azurerm_resource_group.octo_resource_group ]
}

resource "null_resource" "docker_image" {
    triggers = {
        registry_uri = azurerm_container_registry.octo_registry.login_server
    }
    provisioner "local-exec" {
        command = "./scripts/docker_push_to_acr.sh ${self.triggers.registry_uri}" 
        interpreter = ["bash", "-c"]
    }

    depends_on = [
      azurerm_resource_group.octo_resource_group,
      azurerm_storage_account.octo_storage_account,
      azurerm_mssql_server.octopussqlserver,
      azurerm_mssql_database.octopussqldb,
      random_password.octopassword,
      random_password.sqlpassword,
      null_resource.master_key,
      azurerm_container_registry.octo_registry
    ]
}

resource "azurerm_container_group" "octopusdeploy" {
  name                = "octopusdeploy"
  location            = azurerm_resource_group.octo_resource_group.location
  resource_group_name = azurerm_resource_group.octo_resource_group.name
  ip_address_type     = "Public"
  dns_name_label      = var.dnsNameLabel
  os_type             = "Linux"

  image_registry_credential {
    server   = "${azurerm_container_registry.octo_registry.login_server}"
    username = "${azurerm_container_registry.octo_registry.admin_username}"
    password = "${azurerm_container_registry.octo_registry.admin_password}"
  }

  container {
    name = "nginx"
    image  = "${azurerm_container_registry.octo_registry.login_server}/nginx/nginx:1.27.3"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    volume {
      name       = "nginx"
      mount_path = "/etc/nginx"
      read_only  = true
      share_name = azurerm_storage_share.nginx_share.name

      storage_account_name = azurerm_storage_account.octo_storage_account.name
      storage_account_key  = azurerm_storage_account.octo_storage_account.primary_access_key
    }
  }

  container {
    name   = "octopus"
    image  = "${azurerm_container_registry.octo_registry.login_server}/octopusdeploy/octopusdeploy:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 8080
      protocol = "TCP"
    }

    ports {
      port     = 10943
      protocol = "TCP"
    }

    volume {
      name       = "tasklogs"
      mount_path = "/taskLogs"
      read_only  = false
      share_name = azurerm_storage_share.tasklog-share.name

      storage_account_name = azurerm_storage_account.octo_storage_account.name
      storage_account_key  = azurerm_storage_account.octo_storage_account.primary_access_key
    }

    volume {
      name       = "artifacts"
      mount_path = "/artifacts"
      read_only  = false
      share_name = azurerm_storage_share.artifact-share.name

      storage_account_name = azurerm_storage_account.octo_storage_account.name
      storage_account_key  = azurerm_storage_account.octo_storage_account.primary_access_key
    }

    volume {
      name       = "repository"
      mount_path = "/repository"
      read_only  = false
      share_name = azurerm_storage_share.repository-share.name

      storage_account_name = azurerm_storage_account.octo_storage_account.name
      storage_account_key  = azurerm_storage_account.octo_storage_account.primary_access_key
    }

    environment_variables = {
      "ACCEPT_EULA"          = "Y",
      "ADMIN_USERNAME"       = var.octopusAdmin,
      "ADMIN_PASSWORD"       = random_password.octopassword.result,
      "DB_CONNECTION_STRING" = "Server=tcp:${azurerm_mssql_server.octopussqlserver.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.octopussqldb.name};Persist Security Info=False;User ID=${var.sqlAdmin};Password=${random_password.sqlpassword.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;",
      "MASTER_KEY"           = data.local_file.master_key.content
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
    read = "10m"
  }

  depends_on = [
    azurerm_resource_group.octo_resource_group,
    azurerm_storage_account.octo_storage_account,
    azurerm_storage_share.nginx_share,
    azurerm_mssql_server.octopussqlserver,
    azurerm_mssql_database.octopussqldb,
    random_password.octopassword,
    random_password.sqlpassword,
    null_resource.master_key,
    null_resource.cert_request_generation,
    null_resource.self_signed_cert,
    null_resource.ssl_crt,
    null_resource.ssl_key,
    null_resource.nignx_config,
    data.local_file.master_key,
    azurerm_container_registry.octo_registry,
    null_resource.docker_image
    ]
}