# Day 28: Bash Scripting for System Administration

## Introduction

Bash scripting is a powerful tool for system administrators, allowing for automation of routine tasks, system monitoring, and management. This lesson covers essential Bash scripting techniques specifically useful for system administration.

## Key Areas for System Administration Scripts

1. System Monitoring
2. User Management
3. Backup and Recovery
4. Security and Compliance
5. Performance Tuning
6. Log Analysis

## Best Practices for System Administration Scripts

1. Use clear and descriptive variable names
2. Include error handling and logging
3. Use comments to explain complex operations
4. Make scripts modular and reusable
5. Implement proper security measures (e.g., input validation)
6. Use version control for script management

## Essential Commands for System Administration

- `ps`: Process status
- `top`: System monitoring tool
- `df`: Disk space usage
- `du`: Directory space usage
- `free`: Memory usage
- `netstat`: Network statistics
- `iptables`: Firewall management
- `useradd`, `userdel`, `usermod`: User management
- `chmod`, `chown`: File permissions
- `cron`: Task scheduling

## Practical Examples

### 1. System Health Check Script
    
    #!/bin/bash
    
    echo "System Health Check"
    echo "------------------"

# Check CPU usage

    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "CPU Usage: $cpu_usage%"

# Check memory usage

    mem_usage=$(free | awk '/Mem/{printf("%.2f%"), $3/$2*100}')
    echo "Memory Usage: $mem_usage"

# Check disk usage

    disk_usage=$(df -h / | awk '/\/$/{print $(NF-1)}')
    echo "Disk Usage: $disk_usage"

# Check for zombie processes

    zombie_count=$(ps aux | awk '{print $8}' | grep -c Z)
    echo "Zombie Processes: $zombie_count"

2. User Account Creation Script


    #!/bin/bash
    
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo

# Create user

    useradd -m -s /bin/bash "$username"

# Set password

    echo "$username:$password" | chpasswd

# Set expiry

    passwd -e "$username"
    
    echo "User $username created successfully."

3. Automated Backup Script

    
    #!/bin/bash
    
    source_dir="/path/to/source"
    backup_dir="/path/to/backup"
    date=$(date +%Y-%m-%d_%H-%M-%S)
    backup_file="backup_$date.tar.gz"

# Create backup
    
    tar -czf "$backup_dir/$backup_file" "$source_dir"

# Rotate old backups (keep last 5)
    
    ls -t "$backup_dir"/backup_*.tar.gz | tail -n +6 | xargs -r rm
    
    echo "Backup completed: $backup_file"


## Exercises

1. Create a script that monitors system load average and sends an email alert if it exceeds a specified threshold.

2. Write a script to automate the process of creating multiple user accounts from a CSV file.

3. Develop a script that checks for available updates, performs the update, and logs the results.

4. Create a script that analyzes Apache or Nginx access logs and reports the top 10 IP addresses making requests.

5. Write a script that performs a security audit by checking for common misconfigurations and outdated software versions.

## Additional Resources

- [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Linux System Administration Basics](https://www.linode.com/docs/guides/linux-system-administration-basics/)