# Create an ACR.
# az account list-locations
export resourceGroup=aks-rg
export clusterName=aks-airflow
export rgExists=$(az group exists --name $resourceGroup)
if [ $rgExists ]
then
  az group create --name $resourceGroup --location westus2
fi
# az group delete --resource-group $resourceGroup
export acrName=acr0023
echo "Create an ACR"
az acr create -n $acrName -g $resourceGroup --sku basic  --admin-enabled true

az acr import \
  --name $acrName \
  --source docker.io/apache/airflow:latest \
  --image apache/airflow:latest

az aks update -n $clusterName -g $resourceGroup --attach-acr $acrName

# az group delete --name $resourceGroup
# Delete the image
# az acr repository list --name $acrName --output table
# az acr repository delete -n $acrName --image apache/airflow:latest
