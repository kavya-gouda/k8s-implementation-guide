#   Pod Fails Liveness Probe 
Cause:
The liveness probe is failing, causing the pod to restart.
Solution:
1. Check the pod events for liveness probe failures. Example:
kubectl describe pod <pod-name>
2. Test the liveness probe endpoint manually to confirm its response.
3. Update the liveness probe configuration to match the correct path or timeout.
Example:
kubectl edit deployment <deployment-name> 
Update the livenessProbe section.