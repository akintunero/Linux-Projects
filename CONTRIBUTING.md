# Contributing to Linux-Projects

Thank you for your interest in contributing to Linux-Projects! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)
- [Contact Information](#contact-information)

## Getting Started

### Prerequisites

- Basic knowledge of Linux and Bash scripting
- Git installed on your system
- A text editor (VS Code, Vim, Nano, etc.)
- For testing: Bats-core framework (optional but recommended)

### Setting Up Your Development Environment

1. **Fork the Repository**
   ```bash
   # Fork the repository on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/Linux-Projects.git
   cd Linux-Projects
   ```

2. **Set Up Upstream Remote**
   ```bash
   git remote add upstream https://github.com/akintunero/Linux-Projects.git
   ```

3. **Create a New Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **Bug Fixes**: Fix issues in existing scripts or documentation
2. **New Features**: Add new scripts, tutorials, or learning materials
3. **Documentation**: Improve README files, add comments, or create new guides
4. **Testing**: Add tests for existing scripts or improve test coverage
5. **Code Quality**: Refactor code, improve error handling, or enhance security

### Contribution Areas

#### 1. Scripts and Code
- **Location**: `updated_bash_projects/`, `Basic_Projects/`
- **Requirements**: 
  - Add proper error handling
  - Include input validation
  - Add usage examples
  - Follow security best practices

#### 2. Documentation
- **Location**: All directories with README files
- **Requirements**:
  - Clear and concise writing
  - Include prerequisites
  - Add troubleshooting sections
  - Provide usage examples

#### 3. Learning Materials
- **Location**: `30_days_of_bash/`, `beginner_to_advanced_linux_projects/`
- **Requirements**:
  - Accurate and up-to-date information
  - Progressive difficulty levels
  - Practical examples
  - Clear explanations

## Code Style Guidelines

### Bash Script Guidelines

1. **Shebang and Options**
   ```bash
   #!/bin/bash
   set -euo pipefail  # Exit on error, undefined vars, pipe failures
   ```

2. **Variable Naming**
   ```bash
   # Use descriptive names in UPPER_CASE for constants
   readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   
   # Use descriptive names in lowercase for variables
   local file_path="$1"
   ```

3. **Function Definitions**
   ```bash
   # Use descriptive function names and add comments
   function validate_input() {
       # Validate that input is not empty
       if [[ -z "$1" ]]; then
           echo "Error: Input cannot be empty" >&2
           return 1
       fi
   }
   ```

4. **Error Handling**
   ```bash
   # Always check for errors
   if ! command; then
       echo "Error: command failed" >&2
       exit 1
   fi
   ```

### Documentation Guidelines

1. **README Files**
   - Start with a brief description
   - Include prerequisites
   - Provide usage examples
   - Add troubleshooting section
   - Include contribution guidelines

2. **Code Comments**
   - Explain complex logic
   - Document function parameters
   - Include usage examples
   - Add security considerations

## Testing Guidelines

### Setting Up Bats Testing Framework

1. **Install Bats**
   ```bash
   # On macOS
   brew install bats-core
   
   # On Ubuntu/Debian (manual installation required)
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   sudo ./install.sh /usr/local
   cd ..
   rm -rf bats-core
   
   # Alternative: Use package manager if available
   sudo apt-get install bats  # Some distributions have this package
   ```

2. **Create Test Files**
   ```bash
   # Test file naming: script_name_test.sh
   # Example: todo_manager_test.sh
   ```

3. **Write Tests**
   ```bash
   #!/usr/bin/env bats
   
   @test "todo list add functionality" {
       run ./todo_manager.sh add "test task"
       [ "$status" -eq 0 ]
       [ "$output" = "Task added successfully." ]
   }
   
   @test "todo list remove functionality" {
       # Setup: add a task first
       echo "test task" > todo_list.txt
       
       run ./todo_manager.sh remove 1
       [ "$status" -eq 0 ]
       [ "$output" = "Task removed successfully." ]
   }
   ```

### Running Tests

```bash
# Run all tests
bats test/

# Run specific test file
bats test/todo_manager_test.sh

# Run with verbose output
bats --verbose test/
```

## Pull Request Process

### Before Submitting

1. **Test Your Changes**
   ```bash
   # Run existing tests
   bats test/
   
   # Test your specific changes
   ./your_script.sh
   ```

2. **Check Code Quality**
   ```bash
   # Use shellcheck for bash scripts
   shellcheck your_script.sh
   
   # Check for common issues
   bash -n your_script.sh  # Syntax check
   ```

3. **Update Documentation**
   - Update relevant README files
   - Add comments to new code
   - Update any affected documentation

### Submitting a Pull Request

1. **Create a Descriptive Title**
   - Use present tense ("Add feature" not "Added feature")
   - Be specific about the change

2. **Write a Detailed Description**
   ```markdown
   ## Description
   Brief description of what this PR does.

   ## Changes Made
   - List specific changes
   - Include any new files added
   - Mention any files modified

   ## Testing
   - Describe how you tested the changes
   - Include test results if applicable

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Tests pass
   - [ ] Documentation updated
   - [ ] No breaking changes
   ```

3. **Link Issues**
   - If fixing an issue, use "Fixes #123"
   - If related to an issue, use "Related to #123"

### Review Process

1. **Automated Checks**
   - GitHub Actions will run tests
   - Code quality checks will be performed
   - All checks must pass

2. **Code Review**
   - At least one maintainer will review
   - Address any feedback provided
   - Make requested changes if needed

3. **Merge**
   - Once approved, your PR will be merged
   - Your contribution will be included in the next release

## Reporting Issues

### Before Reporting

1. **Check Existing Issues**
   - Search for similar issues
   - Check if the issue is already reported

2. **Gather Information**
   - OS and version
   - Bash version (`bash --version`)
   - Steps to reproduce
   - Expected vs actual behavior

### Issue Template

```markdown
## Bug Report

### Environment
- OS: [e.g., Ubuntu 20.04, macOS 12.0]
- Bash Version: [e.g., 5.1.16]
- Script: [e.g., todo_manager.sh]

### Description
Brief description of the issue.

### Steps to Reproduce
1. Run command: `./script.sh`
2. Provide input: `example`
3. See error: `error message`

### Expected Behavior
What you expected to happen.

### Actual Behavior
What actually happened.

### Additional Information
Any other relevant information, logs, or screenshots.
```

## Contact Information

### Maintainer
- **Name**: Olúmáyòwá Akinkuehinmi
- **Email**: akintunero101@gmail.com
- **Twitter**: [@akintunero](https://twitter.com/akintunero)
- **LinkedIn**: [olumayowaa](https://linkedin.com/in/olumayowaa)

### Communication Channels
- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Discussions**: Use GitHub Discussions for general questions
- **Email**: For sensitive matters or detailed discussions

## Recognition

Contributors will be recognized in the following ways:
- Listed in the [CONTRIBUTORS.md](CONTRIBUTORS.md) file
- Mentioned in release notes
- Invited to join the maintainers team for significant contributions

Thank you for contributing to Linux-Projects! Your contributions help make this a valuable resource for the Linux and Bash scripting community. 