# Pods Not Being Scheduled 
Cause:
The scheduler cannot find a suitable node for the pod due to resource constraints or taints.
Solution:
1. Describe the pod to see why it is not being scheduled. Example:
kubectl describe pod <pod-name>
2. Check for node taints that might prevent scheduling. Example:
kubectl describe node <node-name>
3. Update the pod's tolerations or affinity rules if necessary.
4. Ensure sufficient resources are available on the nodes.