# Issue: CreateContainerConfigError / CreateContainerError
(Pod cannot be created properly)

Symptoms:

These statuses occur when Kubernetes fails to create a container in a pod due to configuration issues before the container actually runs. A pod in CreateContainerConfigError means something is wrong in the container’s configuration (often related to dependencies like ConfigMaps, Secrets, volumes) and CreateContainerError generally means an error occurred during container creation (perhaps a slightly later step, such as setting up volumes or other parameters). You’ll see pods stuck in Pending (or not Ready) with these statuses. kubectl describe pod will show events such as “CreateContainerConfigError: configmap not found” or similar.

Common Causes: The most frequent cause of CreateContainerConfigError is missing or inaccessible ConfigMaps or Secrets that the pod spec references

Missing ConfigMap: If the pod’s spec includes a reference to a ConfigMap (for env variables or mounted volumes) that doesn’t exist in that namespace, Kubernetes cannot populate the data and will block container startup

Missing Secret: Similarly, referencing a Secret that isn’t present (or perhaps was misnamed) will cause this error

Inaccessible ConfigMap/Secret: If RBAC policies prevent access to the ConfigMap/Secret (unusual, since typically pods can access ConfigMaps/Secrets in their namespace by default, but restrictive policies or runtime might block it), or if the Secret is of type that the pod can’t use, it could cause issues.

Invalid Environment Variable references: For example, a container environment variable defined as valueFrom: secretKeyRef: ... where either the Secret or the specific key doesn’t exist will prevent container creation.

Volume Configuration Issues: If a pod spec mounts a volume (emptyDir, hostPath, PVC, etc.) and something is wrong (like the PVC is not bound, or a hostPath directory is not accessible), you might see a CreateContainerError (especially if the volume cannot be mounted in time)

Image Pull Secrets Misconfigured: Less common, but if a pod references an imagePullSecret that doesn’t exist or is not in the right namespace, it might result in errors pulling the image (which show as ImagePullBackOff typically, not CreateContainerConfigError).

Security Context Issues: If you request something impossible, like an invalid user ID or a privileged escalation that’s not allowed by policy, it might cause container creation to error out. These often show up as events explaining the denial.

How to Identify:

Describe the pod (kubectl describe pod ...). Under Events you’re likely to see a clear message. For example:

“Error: configmap app-config not found” – this directly indicates the ConfigMap is missing.

“Error: secret db-creds not found” – indicates missing Secret.

Or if it’s CreateContainerError, you might see something like “Failed to create container with error: invalid mount path” or a complaint from Docker/Containerd about a volume

FIX: CreateContainerConfigError / CreateContainerError (Pod cannot be created properly)

Fixes:

1. Provide or Fix the Referenced Resources: The straightforward fix is to create or correct the missing resources:

Create the ConfigMap/Secret: If you forgot to create a ConfigMap or Secret that a pod needs, create it in the correct namespace (or correct the name in the pod spec to match an existing resource). For example, if your Deployment references a ConfigMap app-config for configuration, ensure kubectl get configmap app-config shows it exists. If not, create it (e.g., via kubectl create configmap). Once the ConfigMap is in place, Kubernetes will unblock the container creation (you might need to delete the pod or it may automatically detect the resource is now there and proceed).

Correct Names/Keys: If the resource exists but the pod spec references a wrong name or key (like looking for SECRET_KEY in a secret but the key is actually secretKey), update the pod spec (and redeploy) with the correct reference. This often happens when copying config – a slight mismatch in naming breaks things. After fixing, new pods will start successfully.

Adjust Deployment Order: In scenarios where you deploy a Secret/ConfigMap and a Deployment concurrently, occasionally the pod might start before the Secret is created (especially if applied in wrong order without explicit dependencies). Ensuring that config resources are applied first (or using tools like Helm hooks or init containers to wait) can prevent transient CreateContainerConfigError at startup.

Namespace Issues: Remember that ConfigMaps/Secrets are namespace-scoped. If you accidentally created the Secret in the wrong namespace (say default but the pod is in production ns), the pod can’t see it. Solution: create it in the correct namespace or make sure you deploy resources to matching namespaces.

2. Remove Unnecessary References / Workaround: If for some reason you cannot immediately create the missing resource or want to bring up the pod without it (perhaps for debugging):

Modify the Pod Spec to Omit the Config: This might be acceptable as a quick workaround – for instance, remove a volume mount that references a missing ConfigMap just to get the pod running (maybe with defaults). For example, if a non-critical ConfigMap is missing, you could remove that env var/volume from the spec and redeploy. The pod will start (but with perhaps reduced functionality). This buys time to then inject the config through another method.

Use Defaults in Code: Some applications can use a default if config isn’t provided. Ensure your app can handle missing config gracefully. In Kubernetes, however, once a ConfigMap/Secret volume or env is declared, it must exist for the container to start. So to test, you’d have to remove those from the spec as mentioned

Replace with Temporary Value: If a Secret is missing and you urgently need the pod, you could create a dummy Secret with placeholder values. The pod will start, then you can later update the secret with real values or update the application. This is risky if the app actually needs the secret’s content to operate correctly (it might malfunction), but it gets past the startup error. For example, a database password secret missing – create one with some value just to satisfy Kubernetes, then fix the pipeline that should provide the real secret.

