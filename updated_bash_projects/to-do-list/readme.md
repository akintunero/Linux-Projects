# To-Do List Manager

## Overview
This script is a simple to-do list manager that allows you to add, remove, and display tasks from the command line.

## Usage

1. **Clone the repository:**
    ```bash
    git clone https://github.com/akintunero/Linux-Projects.git
    cd updated_bash_projects/to-do-list
    ```

2. **Ensure the script has execute permissions:**
    ```bash
    chmod +x to_do_list.sh
    ```

3. **Run the script with the desired action:**
    ```bash
    ./to_do_list.sh [add|remove|list] [task_number|task_description]
    ```

## Examples

- **Add a task:**
    ```bash
    ./to_do_list.sh add "Buy fruits"
    ```

- **Remove a task:**
    ```bash
    ./to_do_list.sh remove 1
    ```

- **List tasks:**
    ```bash
    ./to_do_list.sh list
    ```

## Requirements

This script requires a Unix-like environment with `bash`, `sed`, and `wc` commands available.

## Contributing

Feel free to create a pull request for any enhancements or issues.