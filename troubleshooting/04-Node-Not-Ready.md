# Node Not Ready
Cause:
A node is in a NotReady state due to issues like disk pressure, memory 
pressure, or network problems.
Solution:
1. Check the status of the 
nodes. Example:
kubectl get nodes
2. Describe the problematic node to find the 
cause. Example:
kubectl describe node <node-name>
3. Address the specific issue:
o If disk pressure is mentioned, free up disk space.
o If memory pressure is mentioned, reduce resource 
consumption or increase node capacity.
4. Restart the kubelet service on the affected node if necessary.