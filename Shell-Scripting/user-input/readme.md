# User Inputs

## This lesson will capture a simple example of a Bash script that takes user input and performs different actions based on the provided choices.

## Running the Script

Open a text editor of your choice (e.g., Vim, Nano, or VSCode).
Copy and paste the script into the editor.
Save the file with a .sh extension, for example, user_input_script.sh.
Make the script executable by running: chmod +x user_input_script.sh.
Execute the script in the terminal: ./user_input_script.sh.

## Script Walkthrough
Let's break down the script to understand how it works:

1. Welcome Message
The script starts with a welcoming message:

        echo "Welcome to the User Input Script!"
   
2. User Input
Prompt the user to enter their name:

        read -p "Please enter your name: " userName

3. Personalized Greeting
Display a personalized greeting using the entered name:

        echo "Hello, $userName! How can I assist you today?"
   
4. Menu Options
Present the user with options to choose from:

        echo "Select an option:"
        echo "1. Display a greeting"
        echo "2. Perform a calculation"
        echo "3. Exit"
   
5. User Choice
Read the user's choice:

        read -p "Enter your choice (1/2/3): " userChoice
   
6. Conditional Actions
Perform actions based on the user's choice using a case statement:

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

   Script is in the repository and can be copied for you to try out. 
