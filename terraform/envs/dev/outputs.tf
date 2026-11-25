output "lab_ssh" {
  value = module.lab_server.ssh_command
}

output "lab_instance_id" {
  value = module.lab_server.instance_id
}
