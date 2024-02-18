# Day 23: Working with Git - Bash Commands for Version Control

## Introduction

Git is a distributed version control system widely used in software development. Understanding Git commands in Bash is crucial for effective version control. This lesson covers essential Git commands and how to use them in Bash scripts.

## Basic Git Commands

### 1. Initializing a Repository


    git init

2. Cloning a Repository


    git clone <repository-url>

3. Checking Status


    git status

4. Adding Files

    
    git add <file>
    git add .  # Add all files

5. Committing Changes

    
    git commit -m "Commit message"

6. Pushing Changes

    
    git push origin <branch-name>

7. Pulling Changes

    
    git pull origin <branch-name>

Branch Management
1. Creating a New Branch

    
    git branch <branch-name>

2. Switching Branches
    
    
    git checkout <branch-name>

3. Creating and Switching to a New Branch

    
    git checkout -b <new-branch-name>

4. Merging Branches

    
    git merge <branch-name>

Viewing Information
1. Viewing Commit History

    
    git log
    git log --oneline  # Compact view

2. Viewing Changes

    
    git diff

Advanced Git Operations
1. Stashing Changes

    
    git stash
    git stash pop

2. Tagging
    
    
    git tag -a v1.0 -m "Version 1.0"

3. Rebasing

bash
git rebase <branch-name>

Practical Examples

    Automating Git Workflow:


#!/bin/bash

# Add all changes
git add .

# Prompt for commit message
read -p "Enter commit message: " message

# Commit changes
git commit -m "$message"

# Push to remote
git push origin master

    Creating a Release Branch:

    
    #!/bin/bash
    
    # Ensure we're on the main branch
    git checkout main
    
    # Pull latest changes
    git pull origin main
    
    # Create a new release branch
    release_branch="release-$(date +%Y%m%d)"
    git checkout -b $release_branch
    
    echo "Created new release branch: $release_branch"

## Exercises

1. Write a script that automates the process of creating a new feature branch, making changes, and creating a pull request.

2. Create a script that checks if there are any uncommitted changes in the repository and provides a summary.

3. Develop a script that tags the current commit with a version number and pushes the tag to the remote repository.

4. Write a script that compares two branches and lists the files that are different between them.

5. Create a Git hook script that runs tests before allowing a commit to proceed.

## Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book/en/v2)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
