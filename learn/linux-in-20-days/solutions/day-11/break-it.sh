#!/usr/bin/env bash
# Day 11 - Break it (BUGGY on purpose). It only PRINTS the commands an admin would run; nothing is executed.
# Goal: plan "create user $1, add to the existing group $2, allow them to restart one service".
user=${1:-alice}
group=${2:-devs}

echo useradd -m $user
echo usermod -G $group $user
echo "echo '$user ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$user"
echo chmod 777 /home/$user
