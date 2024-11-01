data "aws_ssm_parameter" "params" {
  count = length(var.parameter_list)
  name  = var.parameter_list[count.index]
}
