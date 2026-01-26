# HPA (Horizontal Pod Autoscaler) Not Scaling 
Cause:
The HPA is not scaling pods as expected.
Solution:
1. Check the HPA details.
Example:
kubectl describe hpa <hpa-name>
2. Verify the CPU or memory metrics are available. Example:
kubectl top pod
3. Ensure that resource requests and limits are set in the deployment. Example:
Edit the deployment:
kubectl edit deployment <deployment-name> 
Add resource requests and limits under resources.
4. If metrics are missing, verify that the metrics server is running. Example:
kubectl get pods -n kube-system | grep metrics-server