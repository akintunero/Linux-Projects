# Step 1: Learn Linux Fundamentals (File Systems, Permissions, Bash)

## Beginner

1. **Create a directory structure for a personal project**
   - Open a terminal
   - Use `mkdir` to create a main project directory
   - Create at least 3 subdirectories within the main directory
   - Use `tree` command to visualize the structure

2. **Change permissions on files and directories**
   - Create several files in your project directories
   - Use `chmod` to set read, write, and execute permissions
   - Practice using both symbolic (u+x) and octal (755) notation
   - Verify changes using `ls -l`

3. **Write a simple Bash script to list files**
   - Open a text editor (e.g., nano, vim)
   - Write a script that uses `ls` to list files in a specified directory
   - Make the script executable using `chmod`
   - Run the script and verify its output

## Intermediate

1. **Set up a complex directory structure with specific permissions**
   - Create a directory structure for a hypothetical company
   - Include departments like HR, Finance, and IT
   - Set permissions so that:
     - HR can access Finance, but Finance can't access HR
     - IT can access all directories
   - Use `groups` to manage these permissions

2. **Use ACLs for granular permissions**
   - Install ACL if not already available (`sudo apt-get install acl`)
   - Use `setfacl` to give a specific user read access to a file without changing its main permissions
   - Verify ACL settings with `getfacl`

3. **Create a Bash script to organize files by extension**
   - Write a script that:
     - Scans a specified directory
     - Creates subdirectories for each file extension found
     - Moves files into appropriate subdirectories
   - Use file globbing and conditional statements

## Advanced

1. **Implement a file system hierarchy for a multi-user environment**
   - Set up a chroot environment to simulate a separate system
   - Implement disk quotas using `quota` tools
   - Create a script that reports on quota usage

2. **Write a Bash script to monitor file permission changes**
   - Use `inotifywait` to watch for file changes
   - When a change occurs, compare the new permissions with a stored baseline
   - Send an alert (e.g., email) if unauthorized changes are detected

3. **Create a custom filesystem using a loop device and ext4**
   - Create a large file to serve as the filesystem (`dd` command)
   - Use `losetup` to set up a loop device
   - Format the loop device with ext4 (`mkfs.ext4`)
   - Mount the new filesystem and test it