# Best practices
1.  While running HPA with Cluster autoscaler, make sure Max limits is setup otherwise, cost will be more
2.  Make resource friendly stage environment (it doesn't need to be scale as prod, and resources can be shutdown after work hours), but put it same configuration with prod.Otherwise they will face some situations that it reproducable on prod bu not in stage, or vice-versa.Most important is time, this first rule that need to make sure.
3.  Setting up monitoring early in K8s clusters can prevent a lot of headaches and streamline management processes.
4.  Choosing a free tier aks control plane for lower environments, affected all dev applications. Api server was not able to handle the amount of pods.
5.  Proper and detailed planning w.r.t resources required for running workloads on your cluster. Believe me it's not only about the pod resources but application -> conatiner -> pods -> storages -> VM -> Esxi Host etc.
6.  We ran a multi-tenant Kubernetes setup and one hard lesson we learned was about RBAC misconfigurations.
7.  Early on, we gave overly broad permissions to some service accounts which led to security risks and unexpected access issues. Debugging these permission problems was a nightmare

# When not to use the kubernetes
  for smaller apps, getting hype and load is increasing daily- if it's containerized, use something as-PaaSy-as possible that ideally can scale down to zero (think GCP Cloud Run). If it's not containerized but suitable for serverless and comes with a supported runtime, use a cloud-native FaaS offering like Azure functions or AWS Lambda.
