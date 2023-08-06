ref: https://github.com/Azure/terraform/tree/master/quickstart/101-batch-account-with-storage   
ref: https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-cli#code-try-3  

# Commands
- terraform init -upgrade
- terraform plan -out main.tfplan
- terraform apply main.tfplan

- az provider list --query "[?namespace=='Microsoft.Batch']" --output table
- az provider register --namespace Microsoft.Batch

Namespace        RegistrationState    RegistrationPolicy
---------------  -------------------  --------------------
Microsoft.Batch  Registered           RegistrationRequired


- terraform plan -destroy -out main.destroy.tfplan
- terraform apply main.destroy.tfplan