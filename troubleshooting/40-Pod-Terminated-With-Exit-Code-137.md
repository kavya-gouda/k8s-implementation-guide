# Pod Terminated With Exit Code 137 
Cause:
The pod was terminated due to an out-of-memory (OOM) error.
Solution:
1. Check the pod logs to confirm the OOM error. Example:
kubectl logs <pod-name>
2. Update the deployment to increase the memory requests and limits. Example:
kubectl edit deployment <deployment-name>
Add or update resources.limits.memory and resources.requests.memory.
3. Monitor resource usage using: Example:
kubectl top pod
----
Symptoms:

OOMKilled means the Linux out-of-memory killer terminated the container because it exceeded its allowed memory.

In Kubernetes, if a container’s memory usage goes above its spec.container.resources.limits.memory, the kernel will kill it (assuming the node is also low on memory).

The pod will restart if restartPolicy is Always (which is default for Deployments), often leading to a CrashLoopBackOff if it happens repeatedly. The termination message or events show “OOMKilled” and the container exit code will be 137 (128 + 9, indicating killed by SIGKILL).

Common Causes:

Memory Limit Too Low: The container’s memory limit is set lower than what the application actually needs, causing frequent OOM kills when usage spikes. For instance, a Java application might need 512Mi but limit was set to 256Mi.

Memory Leak in Application: The app might have a leak or uncontrolled memory growth. Even if the limit seemed sufficient at start, over time it consumes more and hits the limit.

Sudden Load Spikes: A spike in usage (e.g., lots of requests causing high memory usage) can cause a one-time overshoot beyond the limit.

Multiple Containers on Node: If the node itself runs out of memory due to many pods (even if each within its limit, the sum can exceed node capacity if limits were not enforced or requests allowed overallocation), the kernel might OOMKill something. Kubernetes tries to prevent this by evicting pods when node memory is exhausted, but in some scenarios an individual container gets killed.

No Limit Set (Best-Effort Pod on Memory Constrained Node): If no memory limit is set, the container can use up to node memory. The kernel OOM will choose a process to kill when truly out of memory. It might still kill a container (K8s will just report it as OOMKilled even if no explicit limit). So, not setting limits doesn’t avoid OOMKills if the node runs out of memory.

How to Identify:

OOMKills are identified via:

Pod events and status: kubectl describe pod will show an event like “Container X in pod Y was OOMKilled (Exceeded memory limit)”. The pod’s container status (from kubectl get pod -o yaml or describe) will show lastState.terminated.reason: OOMKilled and exitCode: 137.

The kubectl logs might not always show a clear OOM message (the process is just killed). But sometimes the application or a runtime (like Java’s GC logs) might have hints just before death.

If you have metrics, you’d see the memory usage hitting the limit at the time of crash.

on the node, dmesg or /var/log/kern.log would have kernel messages about OOM killer invoking (but this requires node access).

FIX: OOMKilled (Out Of Memory Killed, Exit Code 137)

1. Increase Memory Allocation or Optimize Usage: Depending on whether the OOM was expected or not:

Raise the Memory Limit: If the limit was set too low and the application legitimately needs more memory, update the Kubernetes resource limit to a higher value and redeploy the pod. For example, if a pod was limited to 200Mi and consistently OOMs at 200Mi, consider raising to 300Mi or more based on observed needs. Ensure the node has enough capacity for this increase, or scale up the node specs

Give More Memory to the Node / Scale Out: If each pod needs a lot of memory and the node can’t handle many of them, you might scale out (more nodes) so fewer pods per node, or use bigger instance types. In EKS, this might mean using an EC2 type with more RAM. This avoids nodelevel OOM contention.

Optimize the Application: Investigate why the app is using so much memory. If it’s a memory leak or inefficient process, a code fix might be needed. In the interim, restarting (which Kubernetes is already doing) is a mitigation but not a solution. Profiling the app’s memory usage could identify if certain inputs cause spikes (e.g., image processing might need more memory, or a misconfigured cache grows unbounded).

Set Requests Appropriately: Ensure the memory request is also set (not just limit). If every pod requests what it realistically needs, Kubernetes won’t schedule too many on one node to overcommit memory beyond what the node has (provided your scheduler isn’t overcommitting by design). This can prevent a scenario where each pod is below its limit but collectively they exceed node memory.

2. Implement Memory Management Strategies: Apart from just raising limits, consider:

Use Liveness/Readiness Probes Carefully: If a pod is OOMKilled, Kubernetes will restart it automatically (due to the default restartPolicy). A liveness probe isn’t needed to detect OOM (that’s more for hung processes). In fact, if an app is occasionally slow and triggers liveness failures causing restarts, that can compound memory issues (restarting might spike memory on start). Ensure probes are tuned to not unnecessarily kill containers under heavy but survivable load.

Horizontal Scaling: Sometimes OOM happens because one instance gets too much load. Scaling the deployment horizontally (more replicas) can distribute the load/memory usage. This is a solution if load per pod is the issue

Swap (not recommended in production Kubernetes): Kubernetes generally assumes swap is disabled. It’s best practice to leave it off, since enabling swap can lead to other performance issues and Kubernetes doesn’t manage it well. It’s mentioned here only because someone might think “add swap to avoid OOM” – don’t do that in Kubernetes unless you deeply know what you’re doing.

LimitRange or Quota Enforcement: Ensure there is a LimitRange setting default limits if some pods are created without limits – to avoid any runaway memory usage by new pods that could OOM others

Temporary Mitigation – Increase Limit and Monitor: As a quick mitigation, one might double the memory limit to stop the immediate OOMKills, then watch the pod. If it stabilizes, it was just underprovisioned. If it continues to grow until new OOM at a higher limit, a deeper issue (like a leak) is likely. In an emergency, scaling up limit can buy time.
