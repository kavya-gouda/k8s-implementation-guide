# Pods Exceeding Resource Quota 
Cause:
The namespace has a resource quota, and the requested resources exceed it.
Solution:

1. Check the resource quota for the namespace. Example:

kubectl get resourcequota -n <namespace>

3. Adjust the resource requests and limits in the pod's configuration.

5. Increase the resource quota if necessary. Example:

kubectl edit resourcequota <quota-name> -n <namespace>
