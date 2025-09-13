#!/bin/bash
# https://discuss.hashicorp.com/t/hcl2-environment-variables/9290/2
# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/functions/contextual/env
# SHELL FRIENDLY
# source env-pkr-var.sh

export CNIVERSION=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r .tag_name)
export CONSULVERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/consul | jq -r '.current_version')
export NOMADVERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/nomad | jq -r '.current_version')
export VAULTVERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vault | jq -r '.current_version')
export CONSULTEMPLATEVERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/consul-template | jq -r '.current_version')

export PACKER_LOG=1
export PACKER_LOG_PATH="packer.log"

# export CNIVERSION CONSULVERSION NOMADVERSION VAULTVERSION CONSULTEMPLATEVERSION PACKER_LOG PACKER_LOG_PATH

echo "CNIVERSION:             $CNIVERSION"
echo "CONSULVERSION:          $CONSULVERSION"
echo "NOMADVERSION:           $NOMADVERSION"
echo "VAULTVERSION:           $VAULTVERSION"
echo "CONSULTEMPLATEVERSION:  $CONSULTEMPLATEVERSION"

echo "PACKER_LOG:             $PACKER_LOG"
echo "PACKER_LOG_PATH:        $PACKER_LOG_PATH"