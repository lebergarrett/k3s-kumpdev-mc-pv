# Persistent Volume Claim Creation

This is used to create the persistent volume claims used by my personal minecraft server network.

It uses ansible in a local-exec command, so ansible will need to be installed on the host running Terraform. You will also need to set up ssh keys to the k8s host, and modify the local-exec command accordingly.

The k8s host will either need to have aws cli installed and configured, or comment out the S3 backup line in the backup script located in `ansible/pvc_backup.sh` (Not recommended).