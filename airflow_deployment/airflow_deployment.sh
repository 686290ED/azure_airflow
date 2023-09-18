# 1) Create an AKS cluster with managed identity.
sh /home/guo/azure_airflow/aks/aks_rbac_aad.sh
# 2) Create an ACR to manage container.
sh /home/guo/azure_airflow/acr/acr_import_image.sh
# 3) Create Azure Database for PostgreSQL - Flexible Server and Azure Cache for Redis as airflow backend.
sh /home/guo/azure_airflow/backend/airflow_backend_postgres_redis.sh 
# 4) Create Azure Key Vault to save secrets.
sh /home/guo/azure_airflow/aks_key_vault/aks_key_vault.sh
# 5) Configure Azure Active Directory (Azure AD) workload identity to access the key vault.
sh /home/guo/azure_airflow/csi_secrets_store_identity_access/workload_identity_configuration.sh
# 6) Deploy volumes and other stuff on AKS.
sh /home/guo/azure_airflow/volume/aks_volume.sh
# 7) Deploy airflow.
kubectl apply -f /home/guo/azure_airflow/airflow_deployment/aks_airflow_rbac.yaml
kubectl apply -f /home/guo/azure_airflow/airflow_deployment/airflow_configmap.yaml
kubectl apply -f /home/guo/azure_airflow/airflow_deployment/airflow_scheduler.yaml
kubectl apply -f /home/guo/azure_airflow/airflow_deployment/airflow_webserver.yaml

# az group delete --name $resourceGroup 

