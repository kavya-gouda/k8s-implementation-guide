# Pods Stuck in Init State 
Cause:
The init container in the pod is unable to complete.
Solution:
1. Check the status of the init container. Example:
kubectl describe pod <pod-name>
2. Verify the init container's command and ensure it is completing successfully.
3. Test the init container command manually.
4. Adjust the init container's configuration if necessary and redeploy the pod