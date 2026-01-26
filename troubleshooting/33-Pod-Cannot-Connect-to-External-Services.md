# Pod Cannot Connect to External Services 
Cause:
The pod is unable to reach external services due to network configuration issues.
Solution:
1. Check the pod's network configuration. Example:
kubectl exec <pod-name> -- ifconfig
2. Verify the cluster's DNS configuration. Example:
kubectl get svc -n kube-system | grep coredns
3. Test external connectivity from within the pod. Example:
kubectl exec <pod-name> -- curl <external-service-url>
4. Update the network policies to allow egress traffic.