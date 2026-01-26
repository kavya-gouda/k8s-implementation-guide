# Kubernetes Exit Codes (0-14x)

1.  Exit Code 0 – Success ✅ (No issues! 🎉)
2.  Exit Code 1 – General App Error ❌ (Check logs: kubectl logs <pod>)
3.  Exit Code 126 – Permission Denied 🔒 (Run chmod +x <​script> & verify permissions)
4.  Exit Code 127 – Command Not Found 🔍 (Ensure correct entrypoint in Dockerfile)
5.  Exit Code 128 – Invalid Exit Command ⚠️ (Check how the app exits)
6.  Exit Code 129 (SIGHUP) – Hangup detected 🔄 (Handle termination signals properly)
7.  Exit Code 130 (SIGINT) – Interrupted by Ctrl+C 🛑 (Manual termination—no fix needed)
8.  Exit Code 137 (SIGKILL) – OOMKilled 🔥 (Increase memory limits or optimize usage)
9.  Exit Code 139 (SIGSEGV) – Segmentation Fault 🧩 (Debug memory leaks in the app)
10.  Exit Code 143 (SIGTERM) – Graceful Shutdown ⚡ (Expected behavior when stopping pods)

# Cloud & Kubernetes Networking Errors

1.  HTTP 502 – Bad Gateway ⚠️ (Restart backend pods & check logs)
2.  HTTP 503 – Service Unavailable 🚨 (Scale up backend & verify health checks)
3.  HTTP 504 – Gateway Timeout ⏳ (Optimize backend response & increase timeout)
4.  Connection Refused 🚫 (Verify service is running & listening on the right port)
5.  DNS Resolution Failure 🌎 (Check DNS service & validate domain settings)
6.  Request Timeout (ETIMEDOUT) ⏱️ (Check firewall, security groups & routing rules)
7.  TLS Handshake Failure 🔐 (Verify SSL certificates & encryption settings)
