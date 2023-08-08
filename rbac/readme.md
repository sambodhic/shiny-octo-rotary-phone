ref: https://developer.hashicorp.com/terraform/tutorials/it-saas/azure-ad  

# Commands
- terraform init -upgrade
- terraform plan -out main.tfplan
- terraform apply main.tfplan

- az ad group list --query "[?contains(displayName,'Education')].{ name: displayName }" --output tsv
- az ad group member list --group "Education Department" --query "[].{ name: displayName }" --output tsv
- az ad group member list --group "Education - Managers" --query "[].{ name: displayName }" --output tsv
- az ad group member list --group "Education - Engineers" --query "[].{ name: displayName }" --output tsv

- terraform apply -target azuread_user.users
- terraform apply

- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan
