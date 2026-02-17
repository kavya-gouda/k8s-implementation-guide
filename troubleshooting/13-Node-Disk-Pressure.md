# Node Disk Pressure 
Cause:
The node's disk usage exceeds the defined threshold, causing pod evictions.
Solution:
1. Check the node status.

Example:
kubectl get nodes
kubectl describe node <node-name>

2. Identify and clean up unused Docker images and containers on the 
node. Example:
docker system prune -f

3. Increase disk space or attach additional storage to the node.

4. If using a cloud provider, scale the cluster to add more nodes.
