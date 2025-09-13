# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

advertise_addr = "IP_ADDRESS"
bind_addr      = "0.0.0.0"
client_addr    = "0.0.0.0"
data_dir       = "/opt/consul/data"
retry_join     = ["provider=aws tag_key=ConsulAutoJoin tag_value=auto-join"]
ui             = true
enable_syslog  = true
log_level      = "TRACE"
log_file       = "/opt/consul/logs/"
log_rotate_duration  = "1h"
log_rotate_max_files = 3
retry_join = ["RETRY_JOIN"]