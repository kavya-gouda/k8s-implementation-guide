# Deployment Not Scaling Properly
Cause:
The deployment is not scaling the number of replicas as expected.
Solution:
1. Verify the current number of replicas. Example:
kubectl get deployment <deployment-name>
2. Check for resource constraints on the nodes.
3. Scale the deployment manually to test scaling functionality. Example:
kubectl scale deployment <deployment-name> --replicas=<number>
4. If using HPA, ensure the metrics server is functioning correctly.