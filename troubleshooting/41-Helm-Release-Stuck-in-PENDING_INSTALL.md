Helm Release Stuck in PENDING_INSTALL 
Cause:
The Helm release is stuck due to errors during the installation process.
Solution:
1. Check the Helm release status. Example:
helm status <release-name>
2. Check the logs of the failing pods.
3. Roll back the release. Example:
helm rollback <release-name>
4. Fix the issue in the chart values or templates and try reinstalling. Example:
helm upgrade --install <release-name> <chart-name>