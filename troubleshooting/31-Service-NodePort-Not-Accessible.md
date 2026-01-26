# Service NodePort Not Accessible 
Cause:
A NodePort service is not reachable from outside the cluster.
Solution:
1. Verify the service configuration. Example:
kubectl get svc <service-name>
2. Check the firewall rules on the nodes to ensure the NodePort is open.
3. If the service is exposed through a specific interface, ensure the external IP is accessible.
4. Test connectivity to the NodePort using: Example:
curl <node-ip>:<node-port>