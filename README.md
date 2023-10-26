# Airflow deployment on AKS
This practice is to deploy a customized image of airflow on AKS. The deployment has following features.
1) The airflow image can be updated in a github repo and deployed in Azure Pipelines (to be updated). 
2) The deployment uses Azure AD and Kubernetes RBAC for clusters and AD workload identity for application to access the key vault.
3) The airflow database and celery backend use Azure Database for PostgreSQL - Flexible Server and Azure Cache for Redis.
4) Secrets are saved in Azure Key Vault with RBAC.
5) Airflow dags and logs are stored in Azure files.

## Steps
### 1) Create an AKS cluster with managed identity.
A cluster identity makes it easier to grant permissions for the cluster. 
A managed identity can be set before creating an AKS cluster and assigned to the cluster. 
If using auto-generated identity, the identity is available only after the creation of the cluster.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/aks/aks_rbac_aad.sh) first creates an active directory group. 
The AD group is used as the administer to create an AKS cluster, with azure-keyvault-secrets-provider add-on enabled. 
Another dev group is created and assigned the role and rolebinding to the cluster using 
[yaml file for role definition](https://github.com/686290ED/azure_airflow/blob/main/aks/role_dev_namespace.yaml)
and [yaml file for rolebinding](https://github.com/686290ED/azure_airflow/blob/main/aks/rolebinding_dev_namespace.yaml).

### 2) Create an ACR to manage container.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/acr/acr_import_image.sh) creates an ACR, 
and attaches it to the cluster created in the previous step.

### 3) Create Azure Database for PostgreSQL - Flexible Server and Azure Cache for Redis as airflow backend.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/backend/airflow_backend_postgres_redis.sh) creates an Azure Database for PostgreSQL - Flexible Server, 
which allows public access from any resources deployed within Azure to access the server,
then creates a database and account for airflow, and Azure Cache for Redis as Celery backend. 

### 4) Create Azure Key Vault to save secrets.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/aks_key_vault/aks_key_vault.sh) creates a Key Vault to save secrets for airflow configuration. 
It grants access to the current user, then adds keys and grants access to the cluster.
Use [yaml file](https://github.com/686290ED/azure_airflow/blob/main/aks_key_vault/aks_key_sync.yaml) to provide driver configurations and provider-specific parameters to the CSI driver.

### 5) Configure Azure Active Directory (Azure AD) workload identity to access the key vault.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/csi_secrets_store_identity_access/workload_identity_configuration.sh) creates a managed identity which have access to the key vault, 
retrieves the OIDC Issuer URL of the cluster and creates a service account using 
[yaml file](https://github.com/686290ED/azure_airflow/blob/main/csi_secrets_store_identity_access/kv_service_account.yaml);
creates the federated identity credential between the managed identity, the service account issuer, and the service account,
deploys a SecretProviderClass using [yaml file](https://github.com/686290ED/azure_airflow/blob/main/csi_secrets_store_identity_access/kv_service_class.yaml).

### 6) Deploy volumes and other stuff on AKS.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/volume/aks_volume.sh) deploys volume for airflow dags and logs in the cluster.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/volume/aks_volume.yaml) describes the storage class.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/volume/aks_volume_claims.yaml) requests storage for airflow logs and dags.

### 7) Deploy airflow
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/aks_airflow_rbac.yaml#L9) adds rolebinding of cluster admin to the service account.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_configmap.yaml) defines configuration of airflow.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_scheduler.yaml) defines airflow scheduler deployment.
[Yaml file](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_webserver.yaml) defines airflow webserver deployment.
[Bash script](https://github.com/686290ED/azure_airflow/blob/main/airflow_deployment/airflow_deployment.sh) runs above steps.

## Some commands for debugging
[Bash file](https://github.com/686290ED/azure_airflow/blob/main/troubleshooting.sh) contains some webpages and commands which can used for debugging.


