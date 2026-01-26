# Pending Pods Cause
The pod remains in a Pending state because Kubernetes cannot schedule it.
Solution:
1. Check the pod's events for scheduling 
details. Example:
kubectl describe pod <pod-name>
2. If insufficient resources are the issue, verify node capacity and 
usage. Example:
kubectl get nodes
kubectl describe node <node-name>
3. Adjust the resource requests and limits in your 
deployment. Example:
Edit the deployment:
kubectl edit deployment <deployment-name> 
Modify the resources section under containers.
4. If there are no matching nodes for affinity/anti-affinity rules, update 
or remove the rules.