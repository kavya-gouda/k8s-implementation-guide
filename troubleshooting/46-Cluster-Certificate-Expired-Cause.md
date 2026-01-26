#  Cluster Certificate Expired Cause:
The cluster certificates have expired, causing authentication failures.
Solution:
1. Verify the expiration date of the certificates. Example:
kubeadm certs check-expiration
2. Renew the certificates. Example:
kubeadm certs renew all
3. Restart the control plane components to apply the updated certificates.
4. Update the kubeconfig file if necessary.