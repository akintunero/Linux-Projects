# Day 30: Final Project - Building a Comprehensive Bash Script

## Introduction

For your final project, you will create a comprehensive Bash script that demonstrates the skills you've learned throughout this course. This project will involve creating a system administration tool that combines various aspects of Bash scripting.

## Project: System Administration Dashboard

Create a Bash script that serves as a system administration dashboard. This script should provide a menu-driven interface allowing the user to perform various system administration tasks.

### Requirements

1. Menu Interface: Create a main menu that allows users to select different operations.

2. System Information: Display detailed system information including:
    - OS version
    - Kernel version
    - CPU information
    - Memory usage
    - Disk usage

3. User Management:
    - List all users
    - Add a new user
    - Delete a user
    - Modify user properties (e.g., change password, add to a group)

4. Process Management:
    - List top CPU-consuming processes
    - Kill a process by PID or name

5. Service Management:
    - List all services
    - Start/stop/restart a service

6. Network Information:
    - Display IP configuration
    - Show active network connections

7. Log Analysis:
    - Display recent system logs
    - Search logs for specific patterns

8. Backup Utility:
    - Create a backup of specified directories
    - Restore from a backup

9. System Update:
    - Check for system updates
    - Apply updates (with user confirmation)

10. Error Handling:
    - Implement proper error handling throughout the script

11. Logging:
    - Log all actions performed by the script

### Additional Features (Optional)

- Implement user authentication for the script
- Add a feature to schedule tasks using cron
- Include a network scanning tool
- Implement a simple intrusion detection system

## Implementation Guidelines

1. Start with a main script that presents the menu and calls individual functions for each task.

2. Create separate functions for each major feature.

3. Use appropriate Bash scripting techniques like:
    - Command substitution
    - Conditional statements
    - Loops
    - Case statements for menu options
    - File I/O operations

4. Utilize system commands effectively (e.g., `ps`, `top`, `df`, `du`, `netstat`).

5. Implement proper error checking and provide informative error messages.

6. Add comments to explain complex parts of your code.

7. Use variables for configuration to make the script easily customizable.

8. Ensure the script runs with appropriate permissions (use `sudo` where necessary).

## Submission

Your final submission should include:

1. The main Bash script file
2. Any additional script files or modules you created
3. A README file explaining how to use your script, its features, and any dependencies

## Evaluation Criteria

Your project will be evaluated based on:

1. Functionality: Does the script perform all required tasks correctly?
2. Code Quality: Is the code well-organized, readable, and properly commented?
3. Error Handling: How well does the script handle errors and edge cases?
4. User Interface: Is the menu system intuitive and user-friendly?
5. Creativity: Any additional features or innovative approaches used in the script

## Additional Resources

- [Bash Scripting Tutorial](https://linuxconfig.org/bash-scripting-tutorial-for-beginners)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Linux Command Library](https://linuxcommandlibrary.com/)

Remember to test your script thoroughly in a safe environment before using it on a production system. Good luck with your final project!