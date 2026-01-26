# Pod Fails Readiness Probe 
Cause:
The application is not passing the readiness probe checks.
Solution:
1. Check the pod events for readiness probe failures. Example:
kubectl describe pod <pod-name>
2. Review the readiness probe configuration in the deployment. Example:
Edit the deployment:
kubectl edit deployment <deployment-name>
Verify the readinessProbe section for correct settings.
3. Test the readiness endpoint manually to confirm it responds as expected.
4. Adjust the probe parameters, such as initialDelaySeconds and periodSeconds, to match the application's startup time.