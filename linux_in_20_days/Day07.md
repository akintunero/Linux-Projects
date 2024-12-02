# Day 7: Disk Management

## Objectives
- Understand how to manage disk partitions and file systems in Linux.
- Learn how to use commands like `df`, `du`, `fdisk`, `mkfs`, `mount`, and `umount`.

## Disk Management Commands

Linux provides several powerful tools for managing disk space and partitions. Here are some essential commands that can help you manage disks effectively:

### `df`

The `df` command displays the amount of disk space used and available on file systems.

- **Basic Usage**:
    - `df -h`: Displays disk usage in a human-readable format (e.g., MB, GB).

### `du`

The `du` command estimates file space usage.

- **Basic Usage**:
    - `du -sh /path/to/directory`: Shows the total size of a directory in a human-readable format.

### `fdisk`

`fdisk` is a command-line utility for managing disk partitions. It allows you to create, delete, and modify partitions on a hard drive.

- **List Partitions**:
    - `sudo fdisk -l`: Lists all available partitions on your system.

- **Start `fdisk`**:
    - `sudo fdisk /dev/sda`: Opens the partition table for `/dev/sda`.

### `mkfs`

After creating a partition, you need to format it with a file system using the `mkfs` command.

- **Format as ext4**:
    - `sudo mkfs.ext4 /dev/sda1`: Formats the partition `/dev/sda1` with the ext4 file system.

### `mount` and `umount`

Mounting is the process of making a file system accessible at a certain point in the directory tree.

- **Mount a Partition**:
    - `sudo mount /dev/sda1 /mnt`: Mounts `/dev/sda1` at the `/mnt` directory.

- **Unmount a Partition**:
    - `sudo umount /mnt`: Unmounts the file system from `/mnt`.

## Task

1. Open your terminal and practice managing disks:

    - Use `df -h` to view disk usage across all mounted file systems.
    - Use `du -sh ~` to check the total size of your home directory.
    - Start `fdisk` on a test device (e.g., `/dev/sdb`) and create a new partition.
    - Format the new partition with ext4 using `mkfs.ext4`.
    - Create a directory (e.g., `/mnt/test`) and mount your new partition there.
    - Use `df -h` again to verify that your partition is mounted and check its usage.
    - Unmount the partition using `umount`.

2. Document any challenges you encounter and how you overcame them.

## Additional Resources
- [Red Hat Disk Management Guide](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/5/html/deployment_guide/ch-disk-storage)
- [Disk Partitioning in Linux](https://www.geeksforgeeks.org/disk-partitioning-in-linux/)
- [Linux Disk Commands Overview](https://www.ugurakcil.com/en/post/linux-disk-commands)

