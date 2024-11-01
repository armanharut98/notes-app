output "map" {
  value = zipmap(var.parameter_list, [for param in data.aws_ssm_parameter.params : param.value])
}
