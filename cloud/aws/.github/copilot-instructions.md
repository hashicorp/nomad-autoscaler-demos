# General Instruction:

DO NOT PUT ANY MATCHED PUBLIC CODE in your response!

# Nomad Autoscaler Demos - AI Coding Agent Instructions

This is a HashiCorp Nomad Autoscaler demonstration project that provisions AWS infrastructure for testing horizontal cluster autoscaling capabilities.

## Architecture Overview

**Core Components:**
- **Control Layer**: Terraform configurations in `terraform/control/` manage the overall infrastructure
- **Module Layer**: Reusable Terraform modules in `terraform/modules/aws-hashistack/` handle HashiStack provisioning  
- **Shared Layer**: Common Nomad job definitions in `shared/terraform/modules/shared-nomad-jobs/`
- **Packer**: Custom AMI builds with HashiStack (Nomad, Consul, Vault) pre-installed

**Infrastructure Pattern:**
- Nomad servers: Fixed count (typically 3) managed by `aws_instance` resources
- Nomad clients: Auto-scaling group managed by AWS ASG with min/max capacity
- Autoscaler: Deployed as Nomad job that monitors metrics and scales the client ASG

## Critical Variable Passing Pattern

**IMPORTANT**: The most common configuration issue is missing variable propagation from `terraform/control/main.tf` to the module:

```hcl
module "hashistack_cluster" {
  source = "../modules/aws-hashistack"
  
  # REQUIRED: All variables must be explicitly passed
  server_count = var.server_count  # Often forgotten
  client_count = var.client_count  # Often forgotten
  # ... other vars
}
```

If variables aren't passed to the module, it uses defaults (typically `1`) regardless of `terraform.tfvars` values.

## Key Workflows

**Infrastructure Deployment:**
1. `cd terraform/control/`
2. Set up AMI: `cd ../../packer && source env-pkr-var.sh && packer build .`
3. Update `terraform.tfvars` with new AMI ID
4. `terraform init && terraform plan && terraform apply`

**Variable Validation:**
- Use `terraform console` then `var.variable_name` to verify tfvars loading
- Check module variable passing in `main.tf` if console shows correct values but plan doesn't

**Autoscaler Configuration:**
- Template in `templates/aws_autoscaler.nomad.tpl` generates the autoscaler job
- Uses Prometheus metrics: `nomad_client_allocated_memory`, `nomad_client_allocated_cpu`
- Scales AWS ASG based on resource utilization thresholds (default: 70%)

## File Structure Patterns

```
terraform/control/           # Main deployment configs
├── main.tf                 # Module orchestration - CHECK VARIABLE PASSING
├── terraform.tfvars        # Environment-specific values
└── variables.tf            # Variable definitions

terraform/modules/aws-hashistack/  # Reusable infrastructure module
├── instances.tf            # Nomad servers (count-based)
├── asg.tf                 # Nomad clients (auto-scaling)
├── templates/             # Nomad job templates
└── variables.tf           # Module input definitions
```

## Configuration Conventions

**Naming**: All resources use `${var.stack_name}` prefix for identification
**Tags**: Consistent tagging with `OwnerName`, `OwnerEmail`, `ConsulAutoJoin=auto-join`
**Security Groups**: Single security group `aws_security_group.primary` for all instances
**Load Balancers**: Separate ELBs for server (4646) and client (configurable) access

## Common Issues & Solutions

1. **Only one server despite `server_count=3`**: Check `main.tf` module block has `server_count = var.server_count`
2. **Empty state file**: This is normal for fresh deployments - proceed with `terraform apply`
3. **Autoscaler not scaling**: Verify Prometheus service discovery and metric queries in the job template
4. **SSH access**: Use outputs `hosts_file` and `ssh_file` for connection details

## Integration Points

- **Prometheus**: Deployed via shared module, provides metrics for autoscaler decisions
- **Consul**: Service discovery for Prometheus endpoints in autoscaler config
- **AWS ASG**: Target for autoscaler scaling actions via `aws-asg` driver
- **Nomad API**: Autoscaler communicates via local agent on port 4646

## Development Notes

- AMI building requires env var setup via `env-pkr-var.sh` script
- Packer configs pull latest HashiStack versions from checkpoint API
- Terraform provider versions pinned for stability (AWS ~> 5.0)
- All jobs use Docker driver with official HashiCorp images