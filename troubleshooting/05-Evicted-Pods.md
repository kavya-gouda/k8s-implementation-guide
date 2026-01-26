# Evicted Pods 
Cause:
Pods are evicted due to insufficient resources on the node.
Solution:
1. Identify the evicted pod and 
reason. Example:
kubectl get pods
kubectl describe pod <pod-name>
2. Free up resources on the node by terminating unused pods or 
increasing node capacity.
3. Add more nodes to the cluster if resource requirements 
consistently exceed availability.
4. Adjust resource requests and limits in 
deployments. Example:
Edit the deployment:
kubectl edit deployment <deployment-name> 
Modify the resources section under containers.