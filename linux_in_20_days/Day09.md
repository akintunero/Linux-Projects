# Day 9: Package Management

## Objectives
- Learn how to manage software packages in Linux using APT and YUM.
- Understand the differences between these package managers and their usage.

## Introduction to Package Management

Package management is a crucial aspect of maintaining a Linux system. It involves installing, updating, and removing software packages, ensuring that your system remains up-to-date and secure. Different Linux distributions use different package managers; Debian-based systems like Ubuntu use APT, while Red Hat-based systems like CentOS and Fedora use YUM.

### APT (Advanced Package Tool)

APT is a package management system used by Debian-based distributions. It simplifies the process of managing software by handling dependencies automatically.

#### Basic APT Commands

- **Update Package List**: Use `sudo apt update` to update the list of available packages and their versions.

- **Upgrade Installed Packages**: Use `sudo apt upgrade` to install the newest versions of all installed packages.

- **Install a Package**: Use `sudo apt install package-name` to install a specific package.

- **Remove a Package**: Use `sudo apt remove package-name` to remove a specific package but leave its configuration files.

- **Remove a Package Completely**: Use `sudo apt purge package-name` to remove a package along with its configuration files.

### YUM (Yellowdog Updater, Modified)

YUM is used in Red Hat-based distributions for managing RPM packages. It can automatically resolve dependencies when installing, updating, or removing packages.

#### Basic YUM Commands

- **Update Package List and Upgrade Packages**: Use `sudo yum update` to update the list of available packages and upgrade all installed packages.

- **Install a Package**: Use `sudo yum install package-name` to install a specific package.

- **Remove a Package**: Use `sudo yum remove package-name` to remove a specific package from the system.

- **List Installed Packages**: Use `yum list installed` to list all installed packages on the system.

- **Search for a Package**: Use `yum search keyword` to search for packages related to a keyword.

## Task

1. Open your terminal and practice using these commands:

    - Update your system's package list using APT or YUM.
        - For APT: Use `sudo apt update && sudo apt upgrade`
        - For YUM: Use `sudo yum update`

    - Install a new software package (e.g., `nmap`).
        - For APT: Use `sudo apt install nmap`
        - For YUM: Use `sudo yum install nmap`

    - Remove the software package you just installed.
        - For APT: Use `sudo apt remove nmap`
        - For YUM: Use `sudo yum remove nmap`

2. Document any challenges you encounter and how you overcame them.

## Additional Resources

- [How to Use Package Managers in Linux: APT and YUM](https://www.geeksforgeeks.org/apt-and-yum-package-managers-in-linux/)
- [YUM Commands for Linux Package Management](https://www.geeksforgeeks.org/yum-commands-for-linux-package-management/)
- [Package Management in Ubuntu](https://ubuntu.com/server/docs/package-management)

