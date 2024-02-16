# Day 22: Networking Basics in Bash

## Introduction

Networking is a crucial aspect of system administration and scripting. Bash provides several built-in commands and utilities for network-related tasks. This lesson covers the basics of networking operations in Bash scripting.

## Common Networking Commands

### 1. ping

Used to test connectivity to a host:

    ping google.com

2. ifconfig / ip
Display or configure network interface parameters:


    ifconfig
    ip addr show

3. netstat
Display network connections, routing tables, interface statistics, etc.:


    netstat -tuln

4. ss
Another utility to investigate sockets:


    ss -tuln

5. curl
Transfer data from or to a server:


    curl https://api.example.com

6. wget
Non-interactive network downloader:


    wget https://example.com/file.zip

Network Configuration
1. Configuring IP Address
Temporarily set an IP address:


    sudo ifconfig eth0 192.168.1.100 netmask 255.255.255.0

2. DNS Configuration
Edit /etc/resolv.conf to set DNS servers:


    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

Network Diagnostics
1. traceroute
Print the route packets take to a network host:


    traceroute google.com

2. nslookup / dig
Query DNS servers:


    nslookup google.com
    dig google.com

Firewall Management (iptables)
List current rules:


    sudo iptables -L

Add a rule to allow incoming traffic on port 80:

    
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

Network Monitoring
1. tcpdump
Dump traffic on a network:


    sudo tcpdump -i eth0

2. nmap
Network exploration tool and security scanner:


    nmap 192.168.1.0/24

Practical Examples

Check if a host is up:

    
    #!/bin/bash
    host="google.com"
    ping -c 4 $host > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$host is up"
    else
        echo "$host is down"
    fi


Get public IP address:

    
    #!/bin/bash
    public_ip=$(curl -s https://api.ipify.org)
    echo "Your public IP address is: $public_ip"

## Exercises

1. Write a script that pings a list of hosts and reports which ones are reachable.

2. Create a script that monitors a specific port on a server and sends an alert if it becomes unreachable.

3. Develop a script that fetches the content of a webpage and extracts all unique IP addresses mentioned in it.

4. Write a script that performs a simple port scan on a given IP address for common ports.

5. Create a network diagnostics script that collects information about the system's network interfaces, routing table, and DNS configuration.

## Additional Resources

- [Linux Networking Commands](https://www.tecmint.com/linux-networking-commands/)
- [Bash Scripting for Network Diagnostics](https://www.networkworld.com/article/3219684/using-the-linux-bash-shell-for-network-diagnostics.html)
- [Advanced Bash-Scripting Guide: Network Programming](https://tldp.org/LDP/abs/html/networkprogramming.html)
