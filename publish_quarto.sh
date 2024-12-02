#!/bin/bash

# Check if the commit message is provided
if [ -z "$1" ]; then
  echo "Please provide a commit message."
  exit 1
fi

# Commit the changes with the provided message
git add .
git commit -m "$1"

# Push the changes to the PRA03 branch
git push origin MF03-PRA03-EmmaAlonsoMcCoy

# Go to the project directory
cd my-quarto-site

# Publish to GitHub Pages using quarto
quarto publish gh-pages --no-render --no-prompt

# Create log message
log_message() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] ${message}" >> log.txt
}
