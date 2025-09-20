# General Instruction:

DO NOT PUT ANY MATCHED PUBLIC CODE in your response!

# Nomad Autoscaler Demos - AI Agent Instructions

This repository demonstrates HashiCorp Nomad Autoscaler capabilities across multiple deployment environments and scaling scenarios.

## Architecture Overview

The repository is organized into two main deployment patterns:
- **`vagrant/`**: Local development demos using VirtualBox VMs for rapid prototyping
- **`cloud/`**: Production-ready cloud deployments (AWS, Azure, GCP) with Terraform and Packer

## Key Demo Scenarios

1. **Horizontal App Scaling** (`vagrant/horizontal-app-scaling/`): Scale Nomad task counts based on Prometheus metrics
2. **Dynamic App Sizing** (`vagrant/dynamic-app-sizing/`): Adjust CPU/memory resources of running tasks
3. **Horizontal Cluster Scaling** (`cloud/`): Scale underlying infrastructure nodes via cloud APIs
4. **On-demand Batch** (`cloud/demos/on-demand-batch/`): Scale clusters for batch workloads

## Critical Patterns

### Nomad Job Structure
- All `.nomad` files use HCL syntax with embedded scaling policies
- Autoscaling policies define `min`/`max` bounds, cooldown periods, and target metrics
- Example scaling block pattern:
  ```hcl
  scaling {
    enabled = true
    min = 1
    max = 20
    policy {
      cooldown = "20s"
      check "metric_name" {
        source = "prometheus"
        query = "prometheus_query"
        strategy "target-value" { target = 5 }
      }
    }
  }
  ```

### Infrastructure as Code Workflow
- **Packer**: Build golden images with HashiStack (Nomad/Consul/Vault) pre-installed
- **Terraform**: Deploy infrastructure using modular structure under `cloud/{provider}/terraform/`
- **Nomad Provider**: Deploy jobs via Terraform using `nomad_job` resources

### Configuration Templates
- Nomad jobs use `template` stanzas for dynamic configuration generation
- Common pattern: Consul Template syntax for service discovery (`{{ range service "name" }}`)
- Environment variables follow `NOMAD_*` convention for port/IP binding

### Multi-Cloud Structure
Each cloud provider follows consistent directory structure:
```
cloud/{aws,azure,gcp}/
├── packer/           # Golden image builds
├── terraform/
│   ├── control/      # Main deployment configs
│   └── modules/      # Reusable components
```

## Development Workflows

### Local Development (Vagrant)
1. `vagrant up` provisions VM with Nomad single-node cluster
2. Access services via forwarded ports (4646=Nomad, 9090=Prometheus, 3000=Grafana)
3. Deploy jobs: `nomad job run jobs/*.nomad`
4. Test scaling: Use `hey` tool for load generation

### Cloud Deployment
1. **Image Build**: `source env-pkr-var.sh && packer build .` in packer directory
2. **Infrastructure**: `terraform apply` in control directory
3. **Jobs**: Automatically deployed via `shared-nomad-jobs` module

### Monitoring Integration
- Prometheus scrapes Nomad metrics and application metrics
- Grafana dashboards located in `files/` directories
- Autoscaler exposes metrics on `/metrics` endpoint
- Use Traefik for service mesh and load balancing

## File Naming Conventions
- `.nomad.tpl`: Terraform template files for parameterized job deployment
- `terraform.tfvars.sample`: Example variable files (copy and customize)
- `env-pkr-var.sh`: Environment variables for Packer builds

## Integration Points
- **Nomad ↔ Autoscaler**: HTTP API on port 4646
- **Autoscaler ↔ Prometheus**: Metrics collection for scaling decisions
- **Autoscaler ↔ Cloud APIs**: Infrastructure scaling via provider SDKs
- **Service Discovery**: Consul integration for dynamic service addressing

When working with this codebase, always consider the end-to-end scaling pipeline: metrics collection → autoscaler evaluation → scaling action → monitoring verification.