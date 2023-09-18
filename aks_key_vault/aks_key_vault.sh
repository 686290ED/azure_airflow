# Create Azure key vault, set keys and grant access to the cluster.
export resourceGroup=aks-rg
export clusterName=aks-airflow
export aksIdentity=aks-identity-key
export location=westus2
export postgresName=postgres-airflow-0024
export cache=redis-airflow-0024
export keyvaultName=aks-airflow-key-0024

echo "Create a resource group"
az group create --name $resourceGroup --location westus2

# Create an Azure key valut
export vaultID=$(az keyvault create --resource-group $resourceGroup \
                   --enable-rbac-authorization true \
                   --location $location \
                   --name $keyvaultName --query id --output tsv)

# get the subscription id
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
 
# get your user object id
export USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# grant yourself access to key vault
az role assignment create --assignee-object-id $USER_OBJECT_ID \
                          --assignee-principal-type User \
                          --role "Key Vault Administrator" \
                          --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyvaultName

az keyvault secret set --name airflow-fernet-key \
                       --vault-name $keyvaultName\
                       --content-type connection\
                       --value "1SKnYbflM2I6Y0Q3ngF1lYpBY7TuTANrfzHxpW19meY="	   
az keyvault secret set --name airflow-sql-database\
                       --vault-name $keyvaultName\
                       --content-type connection \
                       --value postgresql+psycopg2://airflow_user:airflow_pass@$postgresName.postgres.database.azure.com/airflow_db
# generate flask secret key
# https://stackoverflow.com/questions/34902378/where-do-i-get-secret-key-for-flask
az keyvault secret set --name airflow-webserver-secret-key\
                       --vault-name $keyvaultName\
                       --content-type connection\
                       --value 'd763a3879024c9c7d6309af8993b7010'
az keyvault secret set --name airflow-broker-url\
                       --vault-name $keyvaultName\
                       --content-type connection \
                       --value redis://$cache.cache.windows.net:6379/0			   
az keyvault secret set --name airflow-celery-result-backend\
                       --vault-name $keyvaultName\
                       --content-type connection\
                       --value postgresql+psycopg2://airflow_user:airflow_pass@$postgresName.postgres.database.azure.com/airflow_db
					   
# az aks enable-addons --addons azure-keyvault-secrets-provider --name $clusterName --resource-group $resourceGroup
# verify the addon installation
# kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'	

# Grand access to the AKS cluster
export aksPrincipalId=$(az identity show --name $aksIdentity --resource-group $resourceGroup --query principalId --output tsv)
export aksId=$(az identity show --name $aksIdentity --resource-group $resourceGroup --query id --output tsv)

export subscriptionId=$(az account subscription list --query '[0]|id' --output tsv)

# Outdated: give access to the cluster
# az role assignment create \
# --assignee-object-id $aksPrincipalId \
# --assignee-principal-type User \
# --role "Key Vault Secrets Officer" \
# --scope "$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyvaultName"

# Provide driver configurations and provider-specific parameters to the CSI driver
# kubectl apply -f /home/guo/azure_airflow/aks_key_vault/aks_key_sync.yaml
