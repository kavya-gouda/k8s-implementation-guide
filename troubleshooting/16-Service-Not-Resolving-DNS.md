# Service Not Resolving DNS 
Cause:
The DNS resolution within the cluster is not working.
Solution:
1. Check the CoreDNS pod status. Example:
kubectl get pods -n kube-system | grep coredns
2. If CoreDNS pods are not running, describe the pods to identify the issue. Example:
kubectl describe pod <coredns-pod> -n kube-system
3. Verify the kube-dns service is running. Example:
kubectl get svc -n kube-system
4. Restart the CoreDNS pods if necessary. Example:
kubectl rollout restart deployment coredns -n kube-system