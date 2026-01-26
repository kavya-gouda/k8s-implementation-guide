# Cluster Autoscaler Not Adding Nodes 
Cause:
The cluster autoscaler is not adding nodes despite high resource demand.
Solution:
1. Verify the cluster autoscaler configuration. Example:
kubectl get configmap -n kube-system cluster-autoscaler-config
2. Ensure the autoscaler has the required permissions to scale the cluster.
3. Check the instance group or node pool limits and increase them if necessary.
4. Review the autoscaler logs for errors.