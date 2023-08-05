# Commands
ref: https://learn.microsoft.com/en-us/azure/developer/terraform/deploy-application-gateway-v2  
ref: https://github.com/Azure/terraform/tree/master/quickstart/101-application-gateway

- terraform init -upgrade
- terraform plan -out main.tfplan
- terraform apply main.tfplan
- terraform state show azurerm_resource_group.rg
- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan
