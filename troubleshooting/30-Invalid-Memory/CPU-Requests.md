# Invalid Memory/CPU Requests 
Cause:
The resource requests or limits specified in the deployment are invalid or exceed node capacity.
Solution:
1. Check the pod description to find the invalid resource specification. Example:
kubectl describe pod <pod-name>
2. Verify the current node capacity. Example:
kubectl describe node <node-name>
3. Update the deployment to set valid resource requests and limits. Example:
Edit the deployment:
kubectl edit deployment <deployment-name>
Ensure resources.requests and resources.limits are set appropriately.