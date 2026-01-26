# Service External-IP Pending 
Cause:
A LoadBalancer service is stuck in the Pending state because the cloud provider's load balancer is not being provisioned.
Solution:
Example:
1. Verify the cloud provider integration with the cluster.
kubectl get nodes -o wide (Check if the nodes have the correct cloud provider labels)
2. Check the service description for details. Example:
kubectl describe svc <service-name>
3. Ensure that the cloud provider account has sufficient permissions to create load balancers.
4. If using a local cluster, use a NodePort service instead of a LoadBalancer.