# Ingress Shows 404 
Cause:
The ingress is not properly routing traffic to the backend service.
Solution:
1. Check the ingress configuration for routing rules. Example:
kubectl describe ingress <ingress-name>
2. Verify that the backend service and pods are running and accessible.
3. Ensure the DNS is correctly pointing to the ingress IP.
4. Restart the ingress controller if required. Example:
kubectl rollout restart deployment <ingress-controller-name>