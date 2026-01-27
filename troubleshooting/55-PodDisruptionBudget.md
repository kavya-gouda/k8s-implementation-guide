📘 Scenario #15: Node Drain Fails Due to PodDisruptionBudget Deadlock
Category: Cluster Management
Environment: K8s v1.21, production cluster with HPA and PDB
Scenario Summary: kubectl drain never completed because PDBs blocked eviction.
What Happened: A deployment had minAvailable: 2 in PDB, but only 2 pods were running. Node drain couldn’t evict either pod without violating PDB.
Diagnosis Steps:
	• Ran kubectl describe pdb <name> – saw AllowedDisruptions: 0.
	• Checked deployment and replica count.
	• Tried drain – stuck on pod eviction for 10+ minutes.
Root Cause: PDB guarantees clashed with under-scaled deployment.
Fix/Workaround:
	• Temporarily edited PDB to reduce minAvailable.
	• Scaled up replicas before drain.
Lessons Learned: PDBs require careful coordination with replica count.
How to Avoid:
	• Validate PDBs during deployment scale-downs.
	• Create alerts for PDB blocking evictions.
