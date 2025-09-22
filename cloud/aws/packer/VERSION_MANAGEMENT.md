# Version Management Documentation

## Hybrid Version Management System

This Packer configuration implements a flexible hybrid approach for managing HashiCorp product versions with multiple fallback levels.

## Current Default Versions (as of September 2025)

- **CNI**: v1.8.0
- **Consul**: 1.21.4  
- **Nomad**: 1.10.5
- **Vault**: 1.20.3
- **Consul Template**: 0.41.2

## Priority Order

The system resolves versions in this priority order:

1. **Manual Variable Override** (highest priority)
2. **Environment Variable** 
3. **Built-in Default** (lowest priority)

## Usage Scenarios

### 1. Use Built-in Defaults
```bash
# Simply run packer - uses current stable versions
packer build .
```

### 2. Use Auto-detected Latest Versions
```bash
# Source the environment script to get latest versions
source env-pkr-var.sh
packer build .
```

### 3. Override Specific Versions
```bash
# Override individual versions
packer build -var="nomad_version=1.9.2" -var="consul_version=1.20.0" .
```

### 4. Create a Custom Version File
Create `custom-versions.pkrvars.hcl`:
```hcl
nomad_version = "1.9.2"
consul_version = "1.20.0"
vault_version = "1.19.0"
```

Then use it:
```bash
packer build -var-file="custom-versions.pkrvars.hcl" .
```

### 5. Mix Environment and Manual Overrides
```bash
# Use environment for most, override specific ones
source env-pkr-var.sh
packer build -var="nomad_version=1.9.2" .
```

## Environment Variables

The system recognizes these environment variables:
- `CNIVERSION`
- `CONSULVERSION` 
- `NOMADVERSION`
- `VAULTVERSION`
- `CONSULTEMPLATEVERSION`

## Validation

Always validate your configuration:
```bash
packer validate .
```

Inspect resolved values:
```bash
packer inspect .
```

## Examples

### Production Deployment (Specific Versions)
```bash
packer build \
  -var="nomad_version=1.10.5" \
  -var="consul_version=1.21.4" \
  -var="vault_version=1.20.3" \
  .
```

### Development (Latest Versions)
```bash
source env-pkr-var.sh
packer build .
```

### Testing (Mixed Versions)
```bash
export NOMADVERSION=1.10.5
export CONSULVERSION=1.21.4
packer build -var="vault_version=1.19.0" .
```