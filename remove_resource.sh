export resourceGroup=aks-rg
export adName=ad-aks
export adDevName=appdev
az group delete --name $resourceGroup
az ad group delete --group $adName
az ad group delete --group $adDevName