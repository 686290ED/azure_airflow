# Troubleshooting
# Some official webpages:
# https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/connection-issues-application-hosted-aks-cluster
# https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
# https://kubernetes.io/docs/tasks/debug/debug-application/

# Check deployment
kubectl get deployment --namespace airflow 
kubectl describe deployment --namespace airflow

# Delete deployment
kubectl delete deployment airflow-scheduler --namespace airflow
kubectl delete deployment airflow-webserver --namespace airflow

# Check pods
kubectl get pods --namespace airflow
kubectl describe pods --namespace airflow

# Get into pods
kubectl exec [pod-name] --stdin --tty  --namespace=airflow -- /bin/bash

# Check logs 
kubectl logs [pod-name] --namespace=airflow 

# Check events
kubectl get events --namespace airflow |grep [pod-name]

# Check services
kubectl get services --namespace airflow
kubectl describe service [service-name] --namespace airflow
kubectl delete service [service-name] --namespace airflow

# airflow liveness probe/readiness probe
# Liveness probe failed: Get "http://10.244.0.17:8080/health": dial tcp 10.244.0.17:8080: connect: connection refused

# CONNECTION_CHECK_MAX_COUNT=0 AIRFLOW__LOGGING__LOGGING_LEVEL=ERROR exec /entrypoint \
                # airflow jobs check --job-type SchedulerJob --hostname $(hostname -f)
sh -c "CONNECTION_CHECK_MAX_COUNT=0 AIRFLOW__LOGGING__LOGGING_LEVEL=ERROR exec /entrypoint \
                airflow jobs check --job-type SchedulerJob --local"	
				
# scheduler liveness problem 
https://github.com/apache/airflow/issues/25667

## Use curl to check return 				
curl -L http://localhost:8080
curl http://localhost:8080/health

# nodepublishsecretref secret is not set
# https://www.linkedin.com/pulse/use-workload-identity-preview-secrets-store-csi-arana-escobedo/

