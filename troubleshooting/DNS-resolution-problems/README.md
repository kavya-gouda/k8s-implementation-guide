# Issue: DNS Resolution Problems
pods are unable to resolve DNS names, such as service names (my-service.mynamespace.svc.cluster.local) or external domain names (example.com). This typically points to a problem with the cluster DNS (CoreDNS). Symptoms include errors like could not resolve host or SERVFAIL when apps try to lookup names.
<img width="817" height="697" alt="image" src="https://github.com/user-attachments/assets/0c85dada-0c57-4954-8e12-997fa51aa633" />

How to Identify:

Check CoreDNS pods: kubectl get pods -n kube-system -l k8s-app=kube-dns. If they’re not Running, that’s a big clue. If Running, check logs: kubectl logs -n kube-system -l k8s-app=kube-dns. Look for errors (like plugin load errors, etc.)

Try a manual DNS lookup from a pod: kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default. If this fails, DNS is definitely broken. If it succeeds for service names but nslookup google.com fails, then internal DNS (for cluster names) works but external resolution fails – likely CoreDNS can’t reach upstream or not configured to.

Ensure the CoreDNS service is correct: kubectl get svc -n kube-system kube-dns. It should have a ClusterIP (the DNS IP given to pods in their resolv.conf). If someone deleted the service or changed it, pods might be pointing to an IP with no server.



----
Common Causes:

CoreDNS Pods CrashLooping or Not Running: If the DNS server pods themselves are down or in CrashLoopBackOff, then obviously DNS queries will fail cluster-wide. This could happen due to misconfiguration (bad CoreDNS ConfigMap), insufficient resources (OOM), or a change (like upgraded CoreDNS plugin with bug).

Network Issues Preventing DNS Queries: Pods send DNS queries to CoreDNS service IP (usually something like 10.96.0.10 for default). If network policies block pods from reaching CoreDNS or if CoreDNS can’t reach upstream servers (for external domains), resolution will fail.

CoreDNS Config Errors: For instance, if the CoreDNS ConfigMap was edited incorrectly (syntax error in Corefile), CoreDNS might not be functioning fully. Or if someone turned off the autopath or kubernetes plugin incorrectly

High Load on DNS or Slow Responses: If DNS is overloaded (many requests) or memory starved, it might respond slowly or intermittently (leading to timeouts). High latency can cause apps to think resolution failed if they have short timeouts.

Node DNS or Local DNS Issues: Kubernetes DNS typically forwards to upstream nameservers for external names. If the node’s resolv.conf or upstream DNS (e.g., cloud provider DNS or corporate DNS) is not reachable or not responding, external lookups fail. For example, in a private EKS cluster, if the VPC DNS (AmazonProvidedDNS) is not reachable due to network ACLs, external resolution fails

Search Path Issues: By default, pods have a DNS search path that includes the pod’s namespace and cluster domain. If someone tweaked DNS config in pod’s spec (dnsPolicy) weirdly, resolution could behave unexpectedly. Usually not an issue unless changed.

IPv6 vs IPv4 issues: If cluster uses IPv6 or dual-stack and something is misconfigured, DNS might return an address that pods can’t route to, seeming like failure. E.g., returning an IPv6 address when pods can only do IPv4.

Fixes :

1. Fix CoreDNS Deployment:

Restart CoreDNS pods:

Revert ConfigMap changes: If someone modified the CoreDNS config recently and DNS broke, revert to known good configuration (you might find the default in Kubernetes docs if needed). After editing the ConfigMap, remember to trigger the pods to reload (CoreDNS has a reload plugin that checks every so often, or you can just kill pods to pick up new config)

Allocate More Resources: If CoreDNS was OOMing, consider giving it more memory in its deployment. If high CPU, more replicas can help share load (scale the CoreDNS deployment to 3 or 4).

Upgrade CoreDNS: If you run a very old version, upgrading to the version that matches your cluster version (check Kubernetes release notes for recommended CoreDNS version) might fix known bugs. EKS allows updating CoreDNS through their CLI or console (it’s an add-on).

Correct Image: Ensure the CoreDNS image is the correct one. Sometimes after upgrading Kubernetes, if CoreDNS image wasn’t updated, compatibility issues might appear (rare, but e.g., an older CoreDNS might not support some new plugin config).
