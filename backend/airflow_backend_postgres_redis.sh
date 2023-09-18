# Create Azure postgres flexible-server and Azure Cache for Redis service as AKS airflow backend
export location=westus2
export resourceGroup=aks-rg
export postgresName=postgres-airflow-0024
export cache=redis-airflow-0024

# 1.Azure postgres flexible-server as database backend and create database and account for airflow in postgres
az postgres flexible-server create --public-access 0.0.0.0 \
								   --active-directory-auth Enabled \
								   --password-auth Enabled \
								   --admin-user postgres \
                                   --admin-password "7degwe#u0" \
                                   --location $location \
                                   --name $postgresName \
                                   --resource-group $resourceGroup \
                                   --sku-name Standard_B1ms \
                                   --storage-size 32 \
								   --tier Burstable \
                                   --version 14 

az postgres flexible-server connect -n $postgresName -u postgres -p "7degwe#u0" -d postgres
az postgres flexible-server execute -n $postgresName -u postgres -p "7degwe#u0" -d postgres --querytext "CREATE DATABASE airflow_db;"
az postgres flexible-server execute -n $postgresName -u postgres -p "7degwe#u0" -d postgres --querytext "CREATE USER airflow_user WITH PASSWORD 'airflow_pass'";
az postgres flexible-server execute -n $postgresName -u postgres -p "7degwe#u0" -d postgres --querytext "GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow_user;"

# az postgres flexible-server connect -n $postgresName -u postgres -p "q1w2e3#u0" -d postgres --interactive
# CREATE DATABASE airflow_db;
# CREATE USER airflow_user WITH PASSWORD 'airflow_pass';
# GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow_user;

# -- PostgreSQL 15 requires additional privileges:
# USE airflow_db;
# GRANT ALL ON SCHEMA public TO airflow_user;

# 2. Create and configure an Azure Cache for Redis service
az redis create --name $cache \
                --enable-non-ssl-port\
                --resource-group $resourceGroup \
				--location $location \
				--sku basic \
				--vm-size C0 

# Retrieve the hostname and ports for an Azure Redis Cache instance
# redis=($(az redis show --name "$cache" --resource-group $resourceGroup --query [hostName,enableNonSslPort,port,sslPort] --output tsv))
# Retrieve the keys for an Azure Redis Cache instance
# keys=($(az redis list-keys --name "$cache" --resource-group $resourceGroup --query [primaryKey,secondaryKey] --output tsv))

# Display the retrieved hostname, keys, and ports
# echo "Hostname:" ${redis[0]}
# echo "Non SSL Port:" ${redis[2]}
# echo "Non SSL Port Enabled:" ${redis[1]}
# echo "SSL Port:" ${redis[3]}
# echo "Primary Key:" ${keys[0]}
# echo "Secondary Key:" ${keys[1]}

# az group delete --name $resourceGroup