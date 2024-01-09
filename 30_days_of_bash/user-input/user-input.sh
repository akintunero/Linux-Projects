#!/bin/bash

echo "Welcome to the User Input Script!"

# Prompt the user to enter their name
read -p "Please enter your name: " userName

# Display a personalized greeting
echo "Hello, $userName! How can I assist you today?"

# Prompt the user to choose an option
echo "Select an option:"
echo "1. Display a greeting"
echo "2. Perform a calculation"
echo "3. Exit"

# Read the user's choice
read -p "Enter your choice (1/2/3): " userChoice

# Perform action based on user's choice
case $userChoice in
  1)
    echo "You chose to display a greeting."
    # Additional actions for displaying a greeting can be added here
    ;;
  2)
    echo "You chose to perform a calculation."
    # Prompt the user to enter two numbers
    read -p "Enter the first number: " num1
    read -p "Enter the second number: " num2
    # Perform the calculation (sum in this case)
    result=$((num1 + num2))
    echo "The sum of $num1 and $num2 is: $result"
    ;;
  3)
    echo "Exiting the script. Goodbye, $userName!"
    exit 0
    ;;
  *)
    echo "Invalid choice. Please choose 1, 2, or 3."
    ;;
esac
