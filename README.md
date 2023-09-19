# Airflow deployment on AKS
This practice is to deploy a customized image of airflow on AKS. The deployment has following features.
1) The airflow image can be updated in a github repo and deployed in Azure Pipelines (update later). 
2) The deployment uses Azure AD and Kubernetes RBAC for clusters and AD workload identity for application to access the key vault.
3) The airflow database and celery backend use Azure Database for PostgreSQL - Flexible Server and Azure Cache for Redis.
4) Secrets are saved in Azure Key Vault with RBAC.
5) Airflow dags and logs are saved on Azure files.

## Steps
### 1) Create an AKS cluster with managed identity.
The cluster identity is mainly for keyvault role assignment. A managed identity can be set before creating an AKS cluster and asign to the cluster. 
The managed identity makes the keyvault assignment easier.
If using auto-generated identity, the identity will be get only after the creation of the cluster.
The script is in [this file](https://github.com/686290ED/azure_airflow/blob/main/aks/aks_rbac_aad.sh).
This script will first create an active directory group which is used as the administer id to create an AKS cluster.
The cluster will also be enabled the keyvault addon. Another dev group is created and assignd the role and rolebinding to the cluster using [yaml files for role definition]
(https://github.com/686290ED/azure_airflow/blob/main/aks/role_dev_namespace.yaml)
and [yaml file for rolebinding](https://github.com/686290ED/azure_airflow/blob/main/aks/rolebinding_dev_namespace.yaml).

### 2) Create an ACR to manage container.
The script is in [this file](https://github.com/686290ED/azure_airflow/blob/main/acr/acr_import_image.sh).
The script creates an ACR, and attaches it to the cluster created in the last step.

### 3) Create Azure Database for PostgreSQL - Flexible Server and Azure Cache for Redis as airflow backend.
The script is in [this file](https://github.com/686290ED/azure_airflow/blob/main/backend/airflow_backend_postgres_redis.sh).
The script creates an Azure Database for PostgreSQL - Flexible Server, which allows public access from any resources deployed within Azure to access your server.
Then creates database and account for airflow, and Azure Cache for Redis as Celery backend. 

### 4) Create Azure Key Vault to save secrets.
The script is in [this file](https://github.com/686290ED/azure_airflow/blob/main/aks_key_vault/aks_key_vault.sh).
The script creates a Key Vault to save secrets for airflow configuration. Creates the key vault and first grant the access to the current user,
add the keys and then grant the access to the cluster.
Use [this yaml file](https://github.com/686290ED/azure_airflow/blob/main/aks_key_vault/aks_key_sync.yaml) to provide driver configurations and provider-specific parameters to the CSI driver.

### 5) Configure Azure Active Directory (Azure AD) workload identity to access the key vault.
The script is in [this file](https://github.com/686290ED/azure_airflow/blob/main/csi_secrets_store_identity_access/workload_identity_configuration.sh).
The script creates a managed identity using, which have access to the key vault, retrieves the OIDC Issuer URL of the cluster and creates a service account using 
[this yaml file](https://github.com/686290ED/azure_airflow/blob/main/csi_secrets_store_identity_access/kv_service_account.yaml);
creates the federated identity credential between the managed identity, the service account issuer, and the service account.
deploys a SecretProviderClass using [this yaml file](https://github.com/686290ED/azure_airflow/blob/main/csi_secrets_store_identity_access/kv_service_class.yaml).

### 6) Deploy volumes and other stuff on AKS.
Use the script [this file](https://github.com/686290ED/azure_airflow/blob/main/volume/aks_volume.sh) to deploy volume for airflow dags and logs in the cluster.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/volume/aks_volume.yaml) is to describe the storage class.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/volume/aks_volume_claims.yaml) is to request storage for airflow logs and dags.

### 7) Deploy airflow
Use [this yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/aks_airflow_rbac.yaml#L9) to add rolebinding of cluster admin to the service account.
Use [this yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_configmap.yaml) to define configuration of airflow.
[This yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_scheduler.yaml) is for airflow scheduler deployment.
[This yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_webserver.yaml) is for airflow webserver deployment.
[The script](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_deployment.sh) runs above steps and airflow deployment.

## Some commands for debugging
[This file](https://github.com/686290ED/azure_airflow/blob/main/troubleshooting.sh) contains some webpages and commands which can used for AKS debugging.


