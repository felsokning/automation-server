variable "countryCode" {
  description = "The Country Code for the Self-Signed Certificate"  
}

variable "dnsNameLabel" {
  description = "The externally routable name for the Azure Container Group to be reachable at"  
}

variable "geographic_region" {
  description = "The geographic region (e.g.: US, EU, CAN, etc.) for resource naming" 
}

variable "certKeySize" {
  default = "2048"
  description = "The key size for the certificate request" 
}

variable "octopusAdmin" {
  description = "The name of the Octopus Server Admin Account" 
}

variable "organisation" {
  description = "The name of the organisation that the Self-Signed Certificate should be 'owned' by." 
}

variable "region" {
  description = "The geographic sub-region (e.g.: NORTH, EAST, SOUTH, WEST, etc.) for resource naming" 
}

variable "resource_group_location" {
  description = "Location of the resource group."
}

variable "skuName" {
  description = "The SKU to use for the SQL Server"  
}

variable "sqlAdmin" {
  description = "The name of the SQL Admin Account"
}

variable "subjectAlternativeName" {
  description = "The Subject Alternative Name (SAN) for the Self-Signed Certificate"
}

variable "subscriptionId" {
  description = "The Subscription ID in Azure (e.g.: 00000000-0000-0000-0000-000000000000) in which these resources will be created"
}