# ClusterRoleBinding Missing Permissions 
Cause:
The ClusterRoleBinding does not have the necessary permissions for the intended action.
Solution:
1. Describe the ClusterRoleBinding to review its configuration. Example:
kubectl describe clusterrolebinding <binding-name>
2. Edit the ClusterRoleBinding to add the required permissions. Example:
Edit the binding:
kubectl edit clusterrolebinding <binding-name> 
Update the rules section.
3. Test the permissions using:
Example:
kubectl auth can-i <action> <resource>