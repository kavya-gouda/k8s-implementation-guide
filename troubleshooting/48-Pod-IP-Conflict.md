# Pod IP Conflict 
Cause:
Two pods are assigned the same IP due to CNI plugin misconfiguration.
Solution:
1. Check the CNI plugin logs.
Example:
kubectl logs <cni-plugin-pod-name> -n kube-system
2. Restart the CNI plugin pods to resolve transient issues. Example:
kubectl rollout restart daemonset <cni-plugin-name> -n kube-system
3. Verify the pod CIDR configuration and ensure it doesn’t overlap.
4. If necessary, reconfigure the CNI plugin with a new CIDR range