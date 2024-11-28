#!/bin/bash

# Log messages function
log_message() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    mkdir -p backlog  # Ensure the backlog folder exists
    echo "[${timestamp}] ${message}" >> backlog/log.txt
}

# Function to select a branch
select_branch() {
    echo "Fetching remote branches..."
    git fetch origin &> /dev/null  # Fetch remote branches silently
    log_message "Fetched remote branches."

    # List remote branches and show options to the user
    branches=$(git branch -r | grep -v "\->")  # Exclude HEAD references
    echo "Available remote branches:"
    select branch in $branches; do
        if [ -n "$branch" ]; then
            echo "You selected branch: $branch"
            log_message "Selected branch: $branch"
            echo "$branch"
            return
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Check if the commit message is provided
if [ -z "$1" ]; then
    echo "Please provide a commit message."
    log_message "Error: Commit message not provided."
    exit 1
fi

# Commit the changes
log_message "Staging all changes."
git add .
log_message "Committing changes with message: $1"
git commit -m "$1" || { log_message "Commit failed."; exit 1; }

# Allow user to choose a branch
branch=$(select_branch)
branch_name=$(echo "$branch" | sed 's/origin\///')  # Extract branch name

# Push the changes to the selected branch
if git push origin "$branch_name"; then
    log_message "Pushed changes to branch: $branch_name successfully."
else
    log_message "Failed to push changes to branch: $branch_name."
    exit 1
fi

# Publish to GitHub Pages using Quarto
if quarto publish gh-pages --no-render --no-prompt; then
    log_message "Published site to GitHub Pages successfully."
else
    log_message "Failed to publish site to GitHub Pages."
    exit 1
fi

log_message "Script execution completed successfully."
