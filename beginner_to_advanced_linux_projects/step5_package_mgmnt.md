# Step 5: Master Package Management

## Beginner

1. **Install, update, and remove packages using `apt` (Debian/Ubuntu)**
   - Use `apt` to:
     - Install at least 3 different packages
     - Update the system package list
     - Remove a package and clean up unused dependencies

2. **Create a simple repository for custom packages**
   - Set up a local directory as a repository
   - Use `dpkg-deb` to create a custom `.deb` package
   - Add the package to your local repository and install it using `apt`

3. **Write a script to automate system updates**
   - Write a script that:
     - Updates the package list (`apt update`)
     - Upgrades installed packages (`apt upgrade`)
     - Automatically cleans up old packages (`apt autoremove`)

## Intermediate

1. **Set up a local mirror of a distribution's repositories**
   - Use `apt-mirror` or `rsync` to set up a local mirror of your distribution's repository
   - Configure local machines to use this mirror in `/etc/apt/sources.list`

2. **Create and manage Software Collections (SCLs) on CentOS/RHEL**
   - Install and configure `scl-utils`
   - Set up a custom Software Collection with a specific version of software (e.g., Python or Ruby)
   - Enable and use the SCL in your environment

3. **Implement version pinning for critical packages**
   - Modify the `apt` configuration to pin a specific version of a package
   - Ensure the pinned version remains installed even when upgrading the system

## Advanced

1. **Develop a custom package management system for in-house software**
   - Write a script or tool that:
     - Manages custom software packages for internal use
     - Tracks package versions and dependencies
     - Automates the installation, upgrade, and removal of these packages

2. **Create a script to manage and sync packages across multiple systems**
   - Write a script that:
     - Syncs package lists between multiple servers
     - Ensures all systems have the same versions of critical packages
     - Automates package updates across all systems

3. **Implement a continuous integration system for package testing and deployment**
   - Set up a CI/CD pipeline using Jenkins or GitLab CI
   - Integrate automated testing for new packages
   - Deploy packages to a production repository after successful tests
