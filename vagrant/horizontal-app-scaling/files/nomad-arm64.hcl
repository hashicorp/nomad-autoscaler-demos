# Copyright IBM Corp. 2020, 2026
# SPDX-License-Identifier: MPL-2.0

# ARM64 VMs cannot auto-detect CPU speed; Nomad reports cpu.totalcompute = 0
# without this override, which prevents scheduling of CPU-requesting jobs.
# This file is only copied into /etc/nomad.d/ on aarch64 VMs (see Vagrantfile).
client {
  cpu_total_compute = 4000
}
