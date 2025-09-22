````instructions
# General Instruction:

DO NOT PUT ANY MATCHED PUBLIC CODE in your response!

# Nomad Autoscaler Demos - AI Coding Agent Instructions

This is a HashiCorp Nomad Autoscaler demonstration project with **dual architecture patterns** for testing horizontal cluster autoscaling capabilities across AWS, Azure, and GCP.

## Architecture Overview

**Two Parallel Implementation Approaches:**

1. **Legacy/Monolithic Pattern** (`aws/`, `azure/`, `gcp/` folders):
   - Single comprehensive modules (e.g., `aws-hashistack`, `azure-hashistack`)
   - **Image lifecycle issue**: Azure/GCP leave orphaned images after `terraform destroy`
   - Control layer in `terraform/control/` directories

2. **Advanced/Modular Pattern** (`infrastructure/` folder + `demos/on-demand-batch/`):
   - Decomposed modules: `aws-nomad-image`, `aws-nomad-servers`, `aws-nomad-clients`, `aws-nomad-network`
   - **Proper AMI cleanup**: Uses `local_file` with destroy-time provisioners to clean up images
   - Only consumed by `demos/on-demand-batch/aws/infrastructure.tf`

**Key Insight**: The `infrastructure/` modules are **underutilized** - they represent the better approach but are only used by one demo.

## Critical Issues & Patterns

**Variable Passing Trap**: The most common configuration issue in monolithic modules:

```hcl
module "hashistack_cluster" {
  source = "../modules/aws-hashistack"
  
  # REQUIRED: All variables must be explicitly passed
  server_count = var.server_count  # Often forgotten
  client_count = var.client_count  # Often forgotten
  # ... other vars
}
```

**Image Lifecycle Management**: 
- **AWS Enhanced**: Now uses dedicated `aws-nomad-image` module with proper AMI cleanup on destroy
- **Azure/GCP Problem**: `null_resource.packer_build` with `local-exec` leaves orphaned images
- **Infrastructure Solution**: Uses `local_file.cleanup` with destroy provisioner to clean AMIs/snapshots

## Key Workflows

**Monolithic Deployment** (`aws/terraform/control/`):
1. `cd terraform/control/`
2. **NEW**: AMI building now automatic when `ami = ""` in terraform.tfvars (or omitted entirely)
3. `terraform init && terraform plan && terraform apply`
4. **Automatic cleanup**: AMI and snapshots deleted on `terraform destroy`

**Legacy Manual AMI Process** (if preferred):
1. `cd ../../packer && source env-pkr-var.sh && packer build .`
2. Update `terraform.tfvars` with specific AMI ID
3. `terraform init && terraform plan && terraform apply`

**Modular Deployment** (`demos/on-demand-batch/aws/`):
1. `cd demos/on-demand-batch/aws/`
2. Uses `infrastructure/` modules with automatic AMI building when `ami_id = ""`
3. `terraform init && terraform plan && terraform apply`

**Debugging Variable Issues**:
- Use `terraform console` then `var.variable_name` to verify tfvars loading
- Check module variable passing in `main.tf` if console shows correct values but plan doesn't
- For modular: Check each module receives required inputs via explicit variable passing

## Project-Specific Patterns

**Multi-Cloud Structure**: Each cloud has different approaches to image management:
- **AWS enhanced**: Dedicated `aws-nomad-image` module with automatic building and cleanup using existing `aws/packer/` configuration
- **Azure/GCP monolithic**: Automated Packer builds, **orphaned images on destroy**
- **Infrastructure modular**: Automated AMI builds with proper cleanup using `local_file` + destroy provisioner

**Shared Components**: 
- `shared/packer/`: Common HashiStack installation scripts across all clouds
- `shared/terraform/modules/shared-nomad-jobs/`: Standard Nomad jobs (Prometheus, Grafana, Traefik)

**Directory Execution Points**:
- Run `terraform apply` from `terraform/control/` directories (monolithic)
- Run `terraform apply` from `demos/on-demand-batch/aws/` (modular)
- **Never** run from `infrastructure/` - it's a module library

## Critical Integration Points

**Autoscaler Configuration**: Template in `templates/aws_autoscaler.nomad.tpl` generates the autoscaler job
- Uses Prometheus metrics: `nomad_client_allocated_memory`, `nomad_client_allocated_cpu`
- Scales AWS ASG based on resource utilization thresholds (default: 70%)
- **Multi-datacenter**: `demos/on-demand-batch/` creates both "platform" and "batch_workers" datacenters

**Consul Auto-Join**: All instances use `ConsulAutoJoin=auto-join` tag for cluster formation
**Load Balancing**: Separate ELBs for server (4646) and client (configurable) access

## File Structure & Navigation

**Monolithic Pattern**:
```
{aws,azure,gcp}/terraform/control/    # Main deployment configs
├── main.tf                          # Module orchestration - CHECK VARIABLE PASSING
├── terraform.tfvars                 # Environment-specific values
└── variables.tf                     # Variable definitions

aws/terraform/modules/               # AWS-specific modules with dedicated AMI management
├── aws-nomad-image/                 # NEW: Dedicated AMI building with cleanup
│   ├── image.tf                     # Uses aws/packer/ config + destroy cleanup
│   ├── variables.tf                 # AMI management variables
│   └── outputs.tf                   # AMI ID output
└── aws-hashistack/                  # Main infrastructure module
    ├── instances.tf                 # Nomad servers (count-based)
    ├── asg.tf                      # Nomad clients (auto-scaling)
    └── variables.tf                # Module input definitions

{azure,gcp}/terraform/modules/       # Other clouds (still monolithic)
├── instances.tf / servers.tf        # Nomad servers (count-based)  
├── asg.tf / clients.tf              # Nomad clients (auto-scaling)
└── image.tf                         # Packer integration (orphaned images)
```

**Modular Pattern**:
```
infrastructure/aws/terraform/modules/  # Decomposed, reusable modules
├── aws-nomad-image/                  # AMI building with cleanup
├── aws-nomad-servers/                # Server instances only
├── aws-nomad-clients/                # Client ASG only  
└── aws-nomad-network/                # VPC, security groups, ELBs

demos/on-demand-batch/aws/            # Consumer of infrastructure modules
├── infrastructure.tf                 # Calls infrastructure modules
└── main.tf                          # Job deployments
```

## Common Issues & Solutions

1. **Only one server despite `server_count=3`**: Check `main.tf` module block has `server_count = var.server_count`
2. **AWS AMI builds automatically**: Now triggered when `ami = ""` or omitted from terraform.tfvars (uses `env-pkr-var.sh` for version detection)
3. **Azure/GCP orphaned images**: Use `infrastructure/` pattern with proper cleanup or add destroy provisioner
4. **Empty state file**: Normal for fresh deployments - proceed with `terraform apply`
5. **"Image not found" in Azure**: Check `var.build_hashistack_image = true` and verify resource group
6. **Module not found**: Ensure you're in the correct execution directory (`control/` or `demos/on-demand-batch/aws/`)
7. **Packer build fails**: Ensure AWS credentials and default VPC access for build instance (uses aws/packer/ configuration)

## Development Conventions

**Naming**: All resources use `${var.stack_name}` prefix with owner tags (`OwnerName`, `OwnerEmail`)
**Provider Versions**: AWS ~> 5.0 (monolithic), ~> 3.39 (modular), Azure 2.32.0, pinned for stability
**AMI/Image Strategy**: 
- **AWS enhanced**: Automatic conditional builds via `ami == ""` check with cleanup
- Manual pre-build + reference (AWS legacy, Azure/GCP)
- Automated build during apply (Azure/GCP, infrastructure pattern)
- Conditional builds via `ami_id == ""` check (infrastructure pattern)
````

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