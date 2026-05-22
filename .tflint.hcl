# TFLint configuration - TMF Coders Infrastructure
# Run: tflint --init && tflint --recursive --config=.tflint.hcl

config {
  call_module_type = "all"
  force            = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_deprecated_index" { enabled = true }
rule "terraform_unused_declarations" { enabled = true }
rule "terraform_comment_syntax" { enabled = true }
rule "terraform_required_version" { enabled = true }
rule "terraform_required_providers" { enabled = true }
rule "terraform_typed_variables" { enabled = true }
rule "terraform_unused_required_providers" { enabled = true }
rule "terraform_module_pinned_source" { enabled = true }

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"

  variable { format = "snake_case" }
  locals { format = "snake_case" }
  output { format = "snake_case" }
  resource { format = "snake_case" }
  module { format = "snake_case" }
  data { format = "snake_case" }
}

# Documentation lives in module READMEs, not HCL comments.
rule "terraform_documented_outputs" { enabled = false }
rule "terraform_documented_variables" { enabled = false }
