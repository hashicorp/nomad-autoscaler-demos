advertise_addr   = "IP_ADDRESS"
bind_addr        = "0.0.0.0"
client_addr      = "0.0.0.0"
server           = true
ui               = true
enable_syslog    = true
data_dir         = "/opt/consul/data"
log_level        = "TRACE"
log_file         = "/opt/consul/logs/"
log_rotate_duration  = "1h"
log_rotate_max_files = 3
bootstrap_expect     = SERVER_COUNT
retry_join           = ["RETRY_JOIN"]

service {
  name = "consul"
}
