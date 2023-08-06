ref: https://learn.microsoft.com/en-us/azure/key-vault/keys/quick-create-terraform?tabs=azure-cli  
ref: https://github.com/Azure/terraform/tree/master/quickstart/101-key-vault-key  

# Commands
- terraform init -upgrade
- terraform plan -out main.tfplan
- terraform apply main.tfplan
- azurerm_key_vault_name=$(terraform output -raw azurerm_key_vault_name)
- az keyvault key list --vault-name $azurerm_key_vault_name
- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan