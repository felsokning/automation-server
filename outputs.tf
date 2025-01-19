output "resource_group_name" {
  value = azurerm_resource_group.octo_resource_group.name
}

output "public_ip_address" {
  value = azurerm_container_group.octopusdeploy.ip_address
}

output "acr_admin_username" {
  value = azurerm_container_registry.octo_registry.admin_username
}

output "acr_admin_password" {
  sensitive = true
  value = azurerm_container_registry.octo_registry.admin_password
}

output "octo_password" {
  sensitive = true
  value     = random_password.octopassword.result
}

output "sql_password" {
  sensitive = true
  value     = azurerm_mssql_server.octopussqlserver.administrator_login_password
}

output "sql_user" {
  value = azurerm_mssql_server.octopussqlserver.administrator_login
}