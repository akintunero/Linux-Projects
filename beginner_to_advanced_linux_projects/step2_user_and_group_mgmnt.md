
# Step 2: Master User and Group Management

## Beginner

1. **Create new users and groups**
   - Use `useradd` to create at least 3 new users
   - Use `groupadd` to create at least 2 new groups
   - Verify creations by checking `/etc/passwd` and `/etc/group`

2. **Add users to groups**
   - Use `usermod -aG` to add users to the groups you created
   - Verify group memberships using `groups` command

3. **Change user passwords**
   - Use `passwd` to set/change passwords for the users you created
   - Try to switch to these users using `su` to verify the passwords

## Intermediate

1. **Set up user-specific environments**
   - Edit `.bashrc` and `.bash_profile` for a user
   - Add custom aliases, environment variables, and startup commands
   - Test the changes by logging in as that user

2. **Implement password policies**
   - Use `chage` to set password expiration
   - Edit `/etc/login.defs` to set global password policies
   - Use `pam_pwquality` to enforce password complexity

3. **Use sudo to delegate specific permissions**
   - Edit `/etc/sudoers` using `visudo`
   - Grant a user permission to run specific commands with sudo
   - Test the configuration by trying to run commands as that user

## Advanced

1. **Implement LDAP for centralized user management**
   - Install and configure OpenLDAP
   - Set up LDAP client on another machine
   - Configure NSS and PAM to use LDAP for authentication

2. **Create a script to automate user onboarding and offboarding**
   - Write a script that:
     - Creates a user account
     - Sets up their home directory with standard files
     - Adds them to appropriate groups
     - Creates an email account (you can simulate this)
   - Include an offboarding function that disables the account and archives their data

3. **Set up disk quotas for users and groups**
   - Enable quota support on a filesystem
   - Use `edquota` to set quotas for users and groups
   - Write a script to generate quota usage reports
