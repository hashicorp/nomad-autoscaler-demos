# Copyright IBM Corp. 2020, 2026
# SPDX-License-Identifier: MPL-2.0

# Nomad uses gopsutil to read "cpu MHz" from /proc/cpuinfo to compute
# cpu.totalcompute. Some hypervisors (notably VirtualBox on macOS ARM64)
# do not expose CPU frequency there; Nomad then reports 0 MHz and cannot
# schedule any CPU-requesting jobs.
# This file is only copied into /etc/nomad.d/ when /proc/cpuinfo lacks a
# "cpu MHz" entry — see the guard in Vagrantfile.
client {
  cpu_total_compute = 4000
}
