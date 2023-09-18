# reference: https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access#next-steps
# set subscription using az account set command.
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export podIdentity=airflow-identity
export resourceGroup=aks-rg
export clusterName=aks-airflow
export location=westus2
export keyvaultName=aks-airflow-key-0024

az account set --subscription $SUBSCRIPTION_ID

# 2) Create a managed identity.
az identity create --name $podIdentity --resource-group $resourceGroup

export userAssignedClientID="$(az identity show -g $resourceGroup --name $podIdentity --query 'clientId' -o tsv)"
export identityTenant=$(az aks show --name $clusterName --resource-group $resourceGroup --query identity.tenantId -o tsv)

# 3) Create a role assignment that grants the workload identity permission to access the key vault secrets, access keys, and certificates
export keyvaultScope=$(az keyvault show --name $keyvaultName --query id -o tsv)

az role assignment create --role "Key Vault Administrator" --assignee $userAssignedClientID --scope $keyvaultScope

# 4) Get the AKS cluster OIDC Issuer URL
export aksOidcIssuer="$(az aks show --resource-group $resourceGroup --name $clusterName --query "oidcIssuerProfile.issuerUrl" -o tsv)"
echo $aksOidcIssuer

# 5) Establish a federated identity credential between the Azure AD application and the service account issuer and subject.
export serviceAccountName="airflow-keyvault"  # sample name; can be changed
export serviceAccountNameSpace="airflow" # can be changed to namespace of your workload

sed -i "s/.*azure\.workload\.identity.*/\ \ \ \ azure.workload.identity\/client-id: ${userAssignedClientID}/" /home/guo/azure_airflow/csi_secrets_store_identity_access/kv_service_account.yaml
kubectl apply -f /home/guo/azure_airflow/csi_secrets_store_identity_access/kv_service_account.yaml

# 6) Create the federated identity credential between the managed identity, service account issuer, and subject.
export federatedIdentityName="airflowfederatedidentity" # can be changed as needed

az identity federated-credential create --name $federatedIdentityName --identity-name $podIdentity --resource-group $resourceGroup --issuer ${aksOidcIssuer} --subject system:serviceaccount:${serviceAccountNameSpace}:${serviceAccountName}

# 7) Deploy a SecretProviderClass using the kubectl apply command and the following YAML script.
sed -i "s/.*clientID.*/\ \ \ \ clientID: \"${userAssignedClientID}\"/" /home/guo/azure_airflow/csi_secrets_store_identity_access/kv_service_class.yaml
kubectl apply -f /home/guo/azure_airflow/csi_secrets_store_identity_access/kv_service_class.yaml

# 8) Deploy a sample pod
# kubectl apply -f /home/guo/azure_airflow/csi_secrets_store_identity_access/pod_airflow_scheduler.yaml
# kubectl apply -f /home/guo/azure_airflow/csi_secrets_store_identity_access/pod_airflow_webserver.yaml


