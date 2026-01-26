# Secrets Not Accessible 
Cause:
The secret is not accessible to the pod.
Solution:
1. Verify the secret is created and 
accessible. Example:
kubectl get secrets
2. Check if the secret is mounted in the 
pod. Example:
kubectl describe pod <pod-name>
3. Update the deployment to mount the 
secret. Example:
Edit the deployment:
kubectl edit deployment <deployment-name> 
Add the secret under envFrom or 
volumeMounts