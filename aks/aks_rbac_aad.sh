# reference: https://learn.microsoft.com/en-us/azure/aks/azure-ad-rbac?tabs=azure-cli
# Create an AKS cluster with Kubernetes RBAC based on Azure AD group.

# Create a new AKS cluster with Azure AD integration enabled. 
# Create two ad group, one as an administer group of the cluster, the other as a developer group.
export resourceGroup=aks-rg
export adName=ad-aks
export adMailName=ad-aks-mail
export adDevName=appdev
export aksIdentity=aks-identity-key
export clusterName=aks-airflow

rgExists=$(az group exists --name $resourceGroup)
if [ $rgExists ]
then
  az group create --name $resourceGroup --location westus2
fi

# 1. Create an ad groups as the administer of the cluster. 
echo "Create an Azure AD group"
az ad group create --display-name $adName --mail-nickname $adMailName
export adGroupId=$(az ad group show --group $adName --query "id" --output tsv)

# 2. Create an AKS cluster with an managed role identity. Enable the key vault addon.
export aksIDs=$(az identity create --name $aksIdentity --resource-group $resourceGroup --query "{id:id, principalId:principalId}")
export aksId=$(echo "$aksIDs" | jq -r '.id')
export aksPincipalId=$(echo "$aksIDs"| jq -r '.principalId')
# az identity delete --name $aksIdentity --resource-group $resourceGroup

echo "Create an AKS cluster with Azure AD integration enabled"
az aks create --name $clusterName \
              --resource-group $resourceGroup \
			  --enable-aad\
			  --aad-admin-group-object-ids $adGroupId \
			  --enable-managed-identity \
			  --enable-oidc-issuer \
			  --enable-workload-identity \
			  --assign-identity $aksId \
			  --enable-azure-rbac\
			  --generate-ssh-keys
# !!! Addon "azure-keyvault-secrets-provider" is not enabled in this cluster.
az aks enable-addons --addons azure-keyvault-secrets-provider --name $clusterName --resource-group $resourceGroup
az aks addon update -g $resourceGroup -n $clusterName -a azure-keyvault-secrets-provider 
az aks show --resource-group $resourceGroup --name $clusterName
# To verify the Secrets Store CSI Driver is installed, run this command:
# kubectl get pods -l app=secrets-store-csi-driver -n kube-system
# To verify the Azure Key Vault provider is installed, run this command:
# kubectl get pods -l app=csi-secrets-store-provider-azure -n kube-system

# 3.Create dev groups in Azure AD and assign role to the group to let any member of the group use kubectl to interact with an AKS cluster.
echo "Create dev groups"
export devGroupId=$(az ad group create \
                  --display-name $adDevName \
                  --mail-nickname $adDevName \
                  --query id -o tsv)
echo $devGroupId
export aksId=$(az aks show \
             --resource-group $resourceGroup \
             --name $clusterName \
             --query id -o tsv)
echo $aksId
sleep 5
# Use assignee-object-id and assignee-principal-type to avoid PrincipalNotFound error.
az role assignment create \
  --assignee-object-id $devGroupId \
  --assignee-principal-type Group \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope $aksId
# echo "Create dev user in Azure AD"
# echo "Please enter the UPN for application developers: " && read AAD_DEV_UPN
# echo "Please enter the secure password for application developers: " && read AAD_DEV_PW
# devUId=$(az ad user create \
  # --display-name "AKS Dev" \
  # --user-principal-name $AAD_DEV_UPN \
  # --password $AAD_DEV_PW \
  # --query objectId -o tsv)
# az ad group member add --group $adDevName --member-id $devUId

# 4.Create AKS cluster resources for app devs
# Allow dev group to AKS resources
echo "Rolebinding AD group to AKS RBAC"
az aks get-credentials --resource-group $resourceGroup --name $clusterName --admin --overwrite-existing

az ad group show --group $adDevName --query id -o tsv

kubectl create namespace airflow
# Create a role for the dev group
kubectl apply -f /home/guo/azure_airflow/aks/role_dev_namespace.yaml
# Bind the role to the dev group
### replace object id with aksId and adGroupId
##################################################
sed -i '$ d' /home/guo/azure_airflow/aks/rolebinding_dev_namespace.yaml 
sed -i "\$a\ \ name: ${devGroupId}" /home/guo/azure_airflow/aks/rolebinding_dev_namespace.yaml
kubectl apply -f /home/guo/azure_airflow/aks/rolebinding_dev_namespace.yaml

#az aks show -g $resourceGroup -n $clusterName --query identityProfile.kubeletidentity.objectId -o tsv
az aks show --resource-group $resourceGroup \
    --name $clusterName \
    --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId \
    --output tsv
