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
----
Symptoms: A pod stays in the Pending state and does not transition to Running. kubectl get pods shows it pending, and kubectl describe pod shows no container created yet, possibly with events indicating scheduling failures. This means Kubernetes cannot schedule the pod onto a node to start it.

Common Causes: Pods can remain Pending for several reasons:

Insufficient Resources on Nodes: The cluster doesn’t have enough free CPU or Memory to fulfill the pod’s resource requests. For example, the pod requests 4 CPU but all nodes have less than 4 CPU free Or there is enough total, but fragmenting across nodes (no single node meets the requirement).

No Node of Appropriate Size: If a pod requests a very large amount of resource (like 64Gi memory) and no node in the cluster has that capacity, it will never schedule

Node Selectors / Affinity Constraints: The pod might have a nodeSelector or node affinity that doesn’t match any node. E.g., if nodeSelector: disktype: ssd but none of the nodes have that label, scheduling will fail (“no node with matching labels”).

Taints and Tolerations: All nodes might be tainted (e.g., reserved for certain workloads) and the pod has no tolerations for those taints. For instance, in EKS, if all nodes have the node.kubernetes.io/lifecycle=spot:NoSchedule taint for Spot instances and your pod doesn’t tolerate it, it stays pending

Persistent Volume Claims (WaitForFirstConsumer): If the pod uses a PVC with storage class that uses WaitForFirstConsumer binding, the PVC will stay unbound until the pod is scheduled, and the pod won’t schedule until a volume exists in a matching zone. Usually, the scheduler and CSI work together: the pod can schedule to a node, then the volume provisions in that zone. But if something is off (like missing CSI driver), the pod can be stuck. More often, the PVC will be pending causing the pod to be pending (scheduling might actually wait for the PVC).

Too Many Pods per Node (IP exhaustion): Kubernetes (and specifically AWS’s CNI) limits how many pods can run on a node (often ~110 pods per node by default due to IP address limits). If all nodes are at max pods, new pods remain pending until a new node joins. On EKS with the VPC CNI, each node has a limited number of secondary IPs for pods – if exhausted, scheduler may not place pods (or if placed, they won’t start due to CNI failure).

Cluster Autoscaler (if used) delays: If using an autoscaler, a pending pod might be waiting for a new node to spin up. During that time it will remain Pending. If autoscaler is not functioning or has hit limits, the pod will just sit pending indefinitely.

How to Identify:

Describe the pod to see why it’s pending. Kubernetes scheduler usually adds events. Common event messages:

0/3 nodes are available: 3 Insufficient cpu. – Clearly indicates not enough CPU free on any node

0/3 nodes are available: 1 node(s) had taints that the pod didn't tolerate. – Indicates a taint issue.

0/3 nodes are available: 3 node(s) didn't match node selector. – Node selector/affinity issue

If no clear message, check if the pod has a PVC stuck in Pending; describe that PVC to see if it’s waiting on something .

Also check if cluster resource quotas (if any) are blocking the pod – if a ResourceQuota is set and the new pod would exceed it, the scheduler may not schedule it and an event would say exceeded quota.

FIX: Pod Stuck in Pending / not staring (Scheduling Issues)

1. Adjust Resources or Cluster Capacity: If it’s a resource shortage:

Scale the Cluster: Add more nodes (or bigger nodes) to provide the needed resources. In EKS, that might mean increasing your Auto Scaling Group size or enabling Cluster Autoscaler to automatically add nodes when pods pend. If a specific node type is needed (e.g., GPU, or memory-optimized), ensure such nodes exist in the cluster.

Lower the Pod’s Requests: If feasible, you can reduce the resource requests of the pod so that it can fit on existing nodes. Maybe the requests were overly conservative. However, be cautious – under-requesting might lead to the pod running on a node without enough actual headroom, causing performance issues.

Pod Overhead and PDBs: Ensure there are no PodDisruptionBudgets or other policies inadvertently keeping pods pending (PDB wouldn’t keep pending, more for eviction logic though).

In EKS with IP exhaustion: If you suspect IP exhaustion per node (each node’s ENI limit reached), scaling out nodes also solves this (spread pods across more nodes). Alternatively, AWS VPC CNI has a feature for prefix delegation (allowing more IPs per ENI) – enabling that can increase pods per node. Or attach additional ENIs if not auto-added. But scaling out is simpler mitigation

2. Adjust Scheduling Constraints: If the issue is due to scheduling rules

Fix Labels/Taints: If node selector or affinity is the culprit (e.g., looking for a label that no node has), you have choices: add that label to some nodes (if that’s what you intended, e.g., label a node as ssd=true if pods require it and that node indeed has SSD storage), or remove/modify the constraint on the pod so it can schedule elsewhere. For example, if you mistakenly set an affinity that every node fails, remove that section from the spec and redeploy

Add Tolerations or Remove Taints: If pods need to run on tainted nodes (e.g., taint for dedicated nodes), add a toleration to the pod spec for that taint. Conversely, if a taint was applied by mistake or no longer needed, removing it from nodes will allow pods to schedule. In EKS, managed node groups sometimes are tainted specially (e.g., spot instances), so make sure to configure tolerations if you want workloads there.

Storage Binding (PVC): If the pod is pending because its PVC is pending (and using WaitForFirstConsumer), ensure a storage provisioner is running. On EKS, this means the AWS EBS CSI driver should be installed for dynamic volume provisioning (as of newer K8s versions, in-tree AWS provisioning is deprecated). If CSI driver wasn’t installed, the PVC will stay pending (“waiting for a volume to be created by external provisioner”). Install the CSI driver (AWS provides an EBS CSI addon) and then the PVC should bind and pod can schedule. Or change the storage class to one that is available. In an on-prem cluster, if no default StorageClass exists, either create one or manually provision a PV to bind the PVC. Once the PVC is Bound, the pod can schedule (possibly to the specific node that matches the PV’s topology, if any).

Resource Quota: If a ResourceQuota is denying scheduling (you’d see an event like “exceeded quota”), either increase the quota or clean up resources to free some quota. Quota could block creation of new pods if the quota for pods or memory/CPU is exhausted in that namespace. Fix by updating the quota object (requires admin) or adjusting usage.

Wait and Retry: If using Cluster Autoscaler, sometimes you just need to wait a couple of minutes for the new node. Check autoscaler logs (if accessible) to see if it detected the unschedulable pod. If not, maybe the autoscaler isn’t installed or configured to watch that namespace. As a quick workaround, you might manually scale your node group.
