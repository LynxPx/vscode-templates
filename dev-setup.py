#!/bin/bash

###################################################################################################
### 1. Checks for PYENV and installs it if not present
### 2. Checks with the user to select which available version of python to use for the Local VENV
### 3. Creates local PYENV for development
### 4. Upgrades Pip 
### 5. Installs Dev requirements: which include pre-commit, black, etc.
### 6. Install pre-commit config
### 7. Allows the user to initialize a git repo
###################################################################################################

# Stop the script if any command fails
set -e

# Check if pyenv is installed, install if not
if ! command -v pyenv >/dev/null 2>&1; then
    echo "Installing pyenv..."
    curl https://pyenv.run | bash

    # Add pyenv to path
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\n  eval "$(pyenv virtualenv-init -)"\nfi' >> ~/.bashrc
    source ~/.bashrc
fi

# Reload shell session
exec "$SHELL"

# Function to list and select Python version
select_python_version() {
    echo "Fetching available Python versions..."
    available_versions=$(pyenv versions --bare)
    echo "Available versions:"
    select version in $available_versions; do
        if [ -n "$version" ]; then
            PYTHON_VERSION=$version
            echo "Selected version: $PYTHON_VERSION"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

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

# Call the function to select Python version
select_python_version

# Install the specified Python version using pyenv if not already installed
if ! pyenv versions --bare | grep -q "^$PYTHON_VERSION\$"; then
    echo "Installing Python $PYTHON_VERSION..."
    pyenv install $PYTHON_VERSION
fi

# Set the local Python version for the project directory
pyenv local $PYTHON_VERSION

# Create a virtual environment using Python - no need to use virtualenv
python -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Update pip to the latest version
pip install --upgrade pip

# Install development dependencies
pip install -r requirements-dev.txt

# Setup pre-commit in your project
pre-commit install
pre-commit install -t commit-msg

# check with user for git init
ask_git_init

echo "Python environment setup is complete. Next time don't forget to activate your virtual environment using 'source .venv/bin/activate'."
