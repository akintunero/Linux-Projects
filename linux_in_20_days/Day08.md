# Day 8: Networking Basics

## Objectives
- Understand the fundamentals of networking in Linux.
- Learn how to use basic networking commands to configure and troubleshoot network interfaces.

## Introduction to Linux Networking

Linux networking involves configuring and managing network interfaces, understanding and setting up routing, and using various tools to troubleshoot and secure network connections. Linux provides a wide range of tools and utilities to manage these aspects efficiently.

### Network Interfaces

A network interface is a point of interaction between a device (like a computer) and a network. In Linux, network interfaces can be physical (e.g., Ethernet cards) or virtual (e.g., loopback interface).

#### Viewing Network Interfaces

To view the available network interfaces on a Linux system, you can use the `ip` or `ifconfig` command.

- **Using `ip`**:
    - `ip link show`: Displays all network interfaces.

- **Using `ifconfig`**:
    - `ifconfig -a`: Lists all network interfaces.

### Configuring Network Interfaces

#### Static IP Configuration

To configure a static IP address, you need to edit the network configuration files. For example, on Debian-based systems, you can modify the `/etc/network/interfaces` file.

1. Open the configuration file:
    - `sudo nano /etc/network/interfaces`

2. Add the following configuration for a static IP:

```
auto eth0
iface eth0 inet static
address 192.168.1.100
netmask 255.255.255.0
gateway 192.168.1.1
dns-nameservers 8.8.8.8 8.8.4.4

```

3. Save the file and restart the networking service:
- `sudo systemctl restart networking`

### Basic Networking Commands

#### `ping`

The `ping` command checks the connectivity between the local machine and a remote host.

- **Basic Usage**:
- `ping google.com`: Sends packets to check connectivity.

- **Send a specific number of packets**:
- `ping -c 4 google.com`: Sends four packets and then stops.

#### `traceroute`

The `traceroute` command shows the path packets take to reach a network host.

- **Basic Usage**:
- `traceroute google.com`: Displays each hop on the way to the destination.

#### `netstat` and `ss`

These commands display information about active network connections.

- **Using `netstat`**:
- `netstat -a`: Lists all active connections.

- **Using `ss`**:
- `ss -tuln`: Displays listening sockets for TCP/UDP.

## Task

1. Open your terminal and practice using these commands:

- List all network interfaces:
    - `ip link show`

- Check connectivity with your local machine:
    - `ping localhost`

- Trace the route packets take to reach Google:
    - `traceroute google.com`

- View active network connections:
    - `netstat -a`
      or
    - `ss -tuln`

2. Document any challenges you encounter and how you overcame them.

## Additional Resources

- [A Beginner's Guide to Linux Networking Fundamentals](https://dev.to/iaadidev/a-beginners-guide-to-linux-networking-fundamentals-dev-ops-prerequisite-7-434o)
- [Mastering Linux Networking Commands](https://earthly.dev/blog/linux-network-commands/)
- [Networking Basics Every Sysadmin Needs](https://www.redhat.com/en/blog/sysadmin-essentials-networking-basics)
