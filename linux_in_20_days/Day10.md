# Day 10: Process Management

## Objectives
- Understand how to manage processes in Linux.
- Learn how to use commands to view, control, and manage system processes.

## Introduction to Process Management

In Linux, a process is an instance of a running program. Managing processes effectively is crucial for maintaining system performance and stability. Linux provides several tools to monitor and control processes.

### Viewing Processes

#### Using `ps`

The `ps` command displays information about active processes.

- **Basic Usage**: Use `ps` to list currently running processes for the current shell session.
- **Detailed Process List**: Use `ps aux` to display a detailed list of all running processes.

#### Using `top`

The `top` command provides a dynamic, real-time view of running processes.

- **Basic Usage**: Use `top` to view active processes and their resource usage. Press `q` to exit.

### Managing Processes

#### Using `kill`

The `kill` command sends signals to processes, typically used to terminate them.

- **Basic Usage**: Use `kill PID` to send a termination signal (SIGTERM) to a process with the specified Process ID (PID).
- **Force Termination**: Use `kill -9 PID` to forcefully terminate a process using the SIGKILL signal.

#### Using `nice` and `renice`

These commands adjust the priority of a process, affecting its CPU scheduling.

- **Start a Process with a Specific Priority**: Use `nice -n priority command` to start a process with a specified priority level.
- **Change Priority of an Existing Process**: Use `renice priority -p PID` to change the priority of an existing process.

### Task

1. Open your terminal and practice using these commands:

    - List all running processes with detailed information:
        - Use `ps aux`

    - View active processes in real-time:
        - Use `top`

    - Find the PID of a specific process (e.g., "bash"):
        - Use `pgrep bash`

    - Terminate a process using its PID:
        - First, find the PID using `ps aux | grep process_name`
        - Then, use `kill PID`

    - Start a new process with lower priority:
        - Use `nice -n 10 command_name`

    - Change the priority of an existing process:
        - Use `renice 5 -p PID`

2. Document any challenges you encounter and how you overcame them.

## Additional Resources

- [Linux Process Management](https://www.tecmint.com/manage-processes-in-linux/)
- [Understanding Linux Processes](https://www.digitalocean.com/community/tutorials/understanding-processes-on-linux)
- [Using Top for Process Monitoring](https://www.howtogeek.com/668986/how-to-use-the-top-command-to-show-running-processes-on-linux/)
