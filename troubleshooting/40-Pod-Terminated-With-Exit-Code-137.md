# Pod Terminated With Exit Code 137 
Cause:
The pod was terminated due to an out-of-memory (OOM) error.
Solution:
1. Check the pod logs to confirm the OOM error. Example:
kubectl logs <pod-name>
2. Update the deployment to increase the memory requests and limits. Example:
kubectl edit deployment <deployment-name>
Add or update resources.limits.memory and resources.requests.memory.
3. Monitor resource usage using: Example:
kubectl top pod