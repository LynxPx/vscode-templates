#!/bin/bash

###################################################################################################
### 1. Checks for PYENV and installs it if not present
### 2. Creates local PYENV for development
### 3. Upgrades Pip 
### 4. Installs Dev requirements: which include pre-commit, black, etc.
### 5. Install pre-commit config
### 6. Allows the user to initialize a git repo
###################################################################################################

# Stop the script if any command fails
set -e

# Initialize global consent variable
MOVE_AND_CLEANUP=false

# Function to ask the user if they want to start a new git repository
ask_git_init() {
    read -p "Do you want to start a new Git repository in this project? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            echo "Initializing a new Git repository..."
            git init
        ;;
        * )
            echo "Skipping Git initialization."
        ;;
    esac
}

# Function to remove the .git directory to avoid conflicts
remove_git_dir() {
    if [ -d ".git" ]; then
        read -p "A .git directory exists which may conflict with your project. Remove it? (y/n) " answer
        case ${answer:0:1} in
            y|Y )
                echo "Removing .git directory..."
                rm -rf .git
            ;;
            * )
                echo "Keeping .git directory."
            ;;
        esac
    fi
}

# Move content from setup back ../ hopefully you cloned into existing repo
copy_contents_to_parent() {
    read -p "Do you want to copy the setup script's contents to the parent directory? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            echo "Copying contents to the parent directory..."
            # Find and copy all files and directories except the script itself, .git, and .vscode to the parent directory
            find . -maxdepth 1 ! -name . ! -name .git ! -name .vscode ! -name $(basename -- "$0") -exec cp -r {} ../ \;
            
            # Handle .vscode separately to ensure it's not skipped and existing configurations are not overwritten
            if [ -d ".vscode" ]; then
                # Check if .vscode directory already exists in the parent
                if [ ! -d "../.vscode" ]; then
                    echo "Creating .vscode in the parent directory."
                    mkdir -p ../.vscode
                fi
                echo "Copying .vscode settings to the parent directory."
                cp -r .vscode/ ../.vscode/
            fi
            
            echo "Content copied successfully."
            # Optionally, confirm with the user before changing directories
            read -p "Switch to the parent directory? (y/n) " moveAnswer
            if [[ ${moveAnswer:0:1} =~ [yY] ]]; then
                MOVE_AND_CLEANUP=true
                echo "Changing directory to the parent."
                cd ..
            else
                echo "Staying in the current directory."
            fi
        ;;
        * )
            echo "Proceeding without copying."
        ;;
    esac
}

perform_cleanup() {
    if [ "$MOVE_AND_CLEANUP" = true ]; then
        echo "Scheduled cleanup and moving to the parent directory..."

        # Confirm current directory
        echo "Current directory: $(pwd)"
        target_dir="$(pwd)/vscode-templates"
        
        # Move out of the vscode-templates directory to avoid issues when deleting it
        cd ..

        echo "Target directory for removal: $target_dir"
        if [ -d "$target_dir" ]; then

            echo "Directory found. Preparing to delete in 5 seconds."
            # Background process to wait 5 seconds before removing the directory
            #(sleep 5; rm -rf "$target_dir" && echo "$target_dir successfully deleted" || echo "Failed to delete $target_dir") &
            nohup bash -c "sleep 5; rm -rf \"$target_dir\"" >/dev/null 2>&1 &
        else
            echo "Directory not found. No need to delete."
        fi
    else
        echo "Cleanup not requested. Exiting."
    fi
}

# check with user for git init
copy_contents_to_parent

ask_git_init

# Create a virtual environment using Python - no need to use virtualenv
python3.11 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Update pip to the latest version
pip install --upgrade pip

# Install development dependencies
pip install -r requirements-dev.txt

# Setup pre-commit in your project
setup_pre_commit() {
    pre-commit install
    pre-commit install -t commit-msg
}

setup_pre_commit || 

echo "Python environment setup is complete. Next time don't forget to activate your virtual environment using 'source .venv/bin/activate'."
perform_cleanup
