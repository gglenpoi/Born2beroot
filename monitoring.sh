#!binbash

while true; do
  # Display banner (optional)
  echo --- Server Monitoring ---  wall

  # Get system information
  architecture=$(uname -m)
  kernel=$(uname -r)
  num_physical_processors=$(grep -c ^processor proccpuinfo)
  num_virtual_processors=$(grep -c ^processor proccpuinfo)
  available_ram=$(awk 'MemAvailable {printf %.0fMBn, $21024}' procmeminfo)
  ram_utilization=$(free  awk 'NR==2{printf %.2f%%n, $3100$2 }')
  available_memory=$(df -h  awk '$ {print $4}')
  memory_utilization=$(df -h  awk '$ {print $5}')
  processor_utilization=$(top -bn2 -d 0.01  grep Cpu(s)  
                            sed s., ([0-9.])% id.1  
                            awk '{print 100 - $1%}')
  last_reboot=$(uptime -s)
  lvm_active=$(systemctl is-active lvm2-lvmetad.service)
  active_connections=$(ss -s  grep -o [0-9] active connections established)
  num_users=$(who  wc -l)
  ipv4_address=$(ip -4 addr show eth0  grep -oP (=inet ).(=))
  mac_address=$(ip link show eth0  grep -oP (=linkether ).(= brd))
  num_sudo_commands=$(grep sudo varlogauth.log  wc -l)

  # Display information on all terminals
  echo Operating system architecture $architecture  wall
  echo Kernel version $kernel  wall
  echo Number of physical processors $num_physical_processors  wall
  echo Number of virtual processors $num_virtual_processors  wall
  echo Available RAM $available_ram  wall
  echo RAM utilization rate $ram_utilization  wall
  echo Available memory $available_memory  wall
  echo Memory utilization rate $memory_utilization  wall
  echo Processor utilization rate $processor_utilization  wall
  echo Date and time of last reboot $last_reboot  wall
  echo LVM active $lvm_active  wall
  echo Number of active connections $active_connections  wall
  echo Number of users using the server $num_users  wall
  echo IPv4 address of server $ipv4_address  wall
  echo MAC address of server $mac_address  wall
  echo Number of commands executed with sudo $num_sudo_commands  wall

  # Sleep for 10 minutes
  sleep 600