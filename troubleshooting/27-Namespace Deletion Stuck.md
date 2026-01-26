# Namespace Deletion Stuck 
Cause:
The namespace is stuck in a terminating state due to resources that are not deleted.
Solution:
1. Check the resources remaining in the namespace. Example:
kubectl get all -n <namespace-name>
2. Force delete the remaining resources. Example:
kubectl delete <resource-type> <resource-name> -n <namespace-name>--grace-period=0 --force
3. If the namespace still doesn't delete, edit the namespace and remove the finalizers.
Example:
kubectl edit namespace <namespace-name