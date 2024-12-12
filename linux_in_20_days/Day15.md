
# Day 15: Network Troubleshooting

## Objectives
- Understand the basics of network troubleshooting in Linux.
- Learn how to use various tools to diagnose and resolve network issues.

## Introduction to Network Troubleshooting

Network troubleshooting involves identifying, diagnosing, and resolving problems affecting network connectivity and performance. Linux provides a variety of tools to help troubleshoot network issues effectively.

### Common Network Troubleshooting Tools

#### `ping`

The `ping` command checks the connectivity between your machine and a remote host.

- **Basic Usage**:
  ```
  ping -c 4 google.com
  ```
  Sends four packets to check connectivity with Google's servers.

### `traceroute`

The traceroute command shows the path that packets take to reach a network host.

- **Basic Usage**:
  ```
  traceroute google.com
  ```
  Displays each hop on the way to the destination.

### `netstat`

The netstat command displays network connections, routing tables, interface statistics, masquerade connections, and multicast memberships.

- **Basic Usage**:
  ```
  netstat -tuln
  ```
  Lists all listening ports and their respective states.

### `ss`

The ss command is used to dump socket statistics. It can display more information than netstat and is considered its replacement.

- **Basic Usage**:
  ```
  ss -tuln
  ```
  Shows listening sockets for TCP/UDP connections.

### `dig`

The dig command is used for querying DNS name servers for information about host addresses, mail exchanges, nameservers, and related information.

- **Basic Usage**:
  ```
  dig example.com
  ```
  Retrieves DNS information for the domain example.com.

### `nslookup`

The nslookup command queries Internet domain name servers. It displays the IP address associated with a domain name.

- **Basic Usage**:
  ```
  nslookup example.com
  ```
  Provides DNS lookup details for example.com.

## Advanced Network Troubleshooting

### Checking Interface Configurations

Use the `ip` command to check interface configurations and statuses.

- **Check Interface Details**:
  ```
  ip addr show
  ```

### Testing Port Connectivity

Use the `nc` (netcat) command to test port connectivity.

- **Test Port Connectivity**:
  ```
  nc -zv google.com 80
  ```
  Tests if port 80 is open on google.com.

## Task

1. Use the tools mentioned above to troubleshoot a simulated network issue on your local machine or network.
2. Document each step you take and the results you obtain.
3. Create a report summarizing your findings and any solutions you implemented.


## Additional Resources

- [Linux Networking Commands](https://www.tecmint.com/ifconfig-vs-ip-command-comparison-network-configuration/)
- [Network Troubleshooting Tools](https://www.geeksforgeeks.org/network-troubleshooting-tools/)
- [Comprehensive Guide to Linux Networking](https://linuxconfig.org/linux-networking)

