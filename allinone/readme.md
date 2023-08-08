# Commands

- terraform init -upgrade
- terraform plan -out main.tfplan
- terraform apply main.tfplan

- az postgres flexible-server db show --resource-group kai --server-name kai-postgresqlfs-server --database-name kai-postgresqlfs-db

- azurerm_key_vault_name=$(terraform output -raw azurerm_key_vault_name)
- az keyvault key list --vault-name $azurerm_key_vault_name


- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan
