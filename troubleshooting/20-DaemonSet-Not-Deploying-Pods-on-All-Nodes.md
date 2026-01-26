# DaemonSet Not Deploying Pods on All Nodes 
Cause:
The DaemonSet is not deploying pods on all nodes due to affinity rules or insufficient resources.
Solution:
1. Describe the DaemonSet to review its configuration. Example:
kubectl describe daemonset <daemonset-name>
2. Verify the node selector or affinity rules.
3. Check the node capacity and ensure there are sufficient resources for the DaemonSet pods.
4. Restart the DaemonSet to reapply its configuration. Example:
kubectl rollout restart daemonset <daemonset-name>