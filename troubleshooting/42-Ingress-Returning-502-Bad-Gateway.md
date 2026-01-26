Ingress Returning 502 Bad Gateway 
Cause:
The ingress is unable to route traffic to the backend service.
Solution:
33
1. Check the ingress logs for errors. Example:
kubectl logs <ingress-controller-pod> -n kube-system
2. Verify the backend service and pod are running and accessible. Example:
kubectl get svc and kubectl get pods
3. Ensure the backend service's target port matches the pod's exposed port.
4. Test the service manually to ensure it responds.