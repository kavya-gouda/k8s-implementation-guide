# PVC in Lost State
Cause:
The PersistentVolumeClaim (PVC) is in a Lost state because the underlying storage is unavailable.
Solution:
1. Check the PV and PVC status. Example:
kubectl get pv 
kubectl get pvc
2. Describe the PV to find the reason for the Lost state. Example:
kubectl describe pv <pv-name>
3. Verify that the storage backend (e.g., NFS, EBS, etc.) is accessible and functioning.
4. If the storage backend is no longer available, recreate the PV and PVC with a new backend