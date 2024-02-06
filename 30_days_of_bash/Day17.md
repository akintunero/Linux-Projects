# Day 17: Script Automation Techniques

## Introduction

Script automation is a powerful way to streamline repetitive tasks and improve efficiency in system administration and development workflows. This lesson covers various techniques for automating scripts in Bash, including scheduling with cron, using the `at` command, and implementing continuous integration.

## Scheduling with Cron

Cron is a time-based job scheduler in Unix-like operating systems. It allows you to schedule scripts to run automatically at specified intervals.

### Basic Cron Syntax

    *
        * 
            * 
                *
                    *



    command_to_execute

Five fields represent:
- Minute (0-59)
- Hour (0-23)
- Day of month (1-31)
- Month (1-12)
- Day of week (0-7, where 0 and 7 are Sunday)

### Examples

1. Run a script every day at 3:30 AM:


    30 3 * * * /path/to/script.sh



2. Run a script every 15 minutes:


    */15 * * * * /path/to/script.sh



3. Run a script on the first day of every month:


    0 0 1 * * /path/to/script.sh



### Managing Cron Jobs

- Edit crontab: `crontab -e`
- List cron jobs: `crontab -l`
- Remove all cron jobs: `crontab -r`

## Using the `at` Command

The `at` command is used for scheduling one-time tasks at a specific time.

### Basic `at` Syntax


    at TIME

Examples

Run a script at a specific time:

    
    at 2:30 PM
    /path/to/script.sh
    <Ctrl+D>

Run a script after a certain duration:


    at now + 1 hour
    /path/to/script.sh
    <Ctrl+D>

Managing at Jobs

    List pending jobs: atq
    Remove a job: atrm [job_number]

### Continuous Integration (CI)
Continuous Integration involves automatically building and testing code changes as they are committed to a repository.
Basic CI Workflow

1. Set up a CI service (e.g., Jenkins, GitLab CI, GitHub Actions)
2. Create a configuration file (e.g., .gitlab-ci.yml, .github/workflows/main.yml)
3. Define jobs and stages in the configuration file
4. Commit and push changes to trigger the CI pipeline

Example GitHub Actions Workflow


    name: CI
    
    on: [push]
    
    jobs:
      build:
        runs-on: ubuntu-latest
        
        steps:
        - uses: actions/checkout@v2
        - name: Run a script
          run: |
            chmod +x ./script.sh
            ./script.sh

## Exercises

1. Create a cron job that runs a backup script every night at 2 AM.

2. Write a script that uses the `at` command to schedule a system update for the next weekend.

3. Set up a basic CI pipeline using GitHub Actions for a simple Bash script project.

4. Create a script that automates the process of updating and upgrading system packages, and schedule it to run weekly using cron.

5. Implement a monitoring script that checks system resources and sends an alert if certain thresholds are exceeded. Use cron to run this script every 5 minutes.

## Additional Resources

- [Crontab Guru](https://crontab.guru/) - An interactive cron schedule expression editor
- [at, batch, atq, atrm - Linux Commands](https://www.geeksforgeeks.org/at-batch-atq-atrm-linux-commands/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)