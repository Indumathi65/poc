output "aurora_endpoint" { value = aws_rds_cluster.aurora.endpoint }
output "dms_replication_instance_arn" { value = aws_dms_replication_instance.rep.replication_instance_arn }
output "dms_task_id" { value = aws_dms_replication_task.task.replication_task_id }