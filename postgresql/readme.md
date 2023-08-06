# Commands
ref: https://learn.microsoft.com/en-us/azure/developer/terraform/deploy-postgresql-flexible-server-database    
ref: https://github.com/Azure/terraform/tree/master/quickstart/201-postgresql-fs-db

- terraform init -upgrade
- terraform plan -out main.tfplan
- terraform apply main.tfplan
- terraform state show azurerm_resource_group.rg
- az postgres flexible-server db show --resource-group kai-postgresqlfs --server-name kai-postgresqlfs-server --database-name kai-postgresqlfs-db
- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan
