# ConfigMap Not Found 
Cause:
The ConfigMap referenced in a pod or deployment does not exist.
Solution:
1. Verify the ConfigMap name in the 
deployment. Example:
kubectl describe pod <pod-name>
2. Check the existing 
ConfigMaps. Example:
kubectl get configmaps
3. Create the missing 
ConfigMap. Example:
kubectl create configmap <configmap-name> --from- 
literal=<key>=<value>
4. Restart the affected deployment to apply the 
changes. Example:
kubectl rollout restart deployment <deployment-name>