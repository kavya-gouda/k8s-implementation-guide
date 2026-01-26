This occurs when the Kubernetes API server is not running or the kubeconfig is 
misconfigured.
Solution:
1. Verify that the API server is running on the master node. Example:
systemctl status kube-apiserver
2. Check if the kubeconfig file is correctly set up. Example:
Ensure KUBECONFIG points to the correct file:
export KUBECONFIG=/path/to/config
3. Restart the API server if it's not running. Example:
systemctl restart kube-apiserver
4. Test the connection to the cluster using: kubectl cluster-info