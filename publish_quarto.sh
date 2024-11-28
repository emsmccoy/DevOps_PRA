#!/bin/bash

# Log messages function
log_message() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    mkdir -p backlog  # Ensure the backlog folder exists
    echo "[${timestamp}] ${message}" >> backlog/log.txt
}

# Function to select a branch (local or remote)
select_branch() {
    local type="$1"  # "local" or "remote"
    echo "Fetching $type branches..."
    if [ "$type" == "remote" ]; then
        git fetch origin &> /dev/null  # Fetch remote branches silently
        log_message "Fetched remote branches."
        branches=$(git branch -r | grep -v "\->")  # Exclude HEAD references
    elif [ "$type" == "local" ]; then
        branches=$(git branch | sed 's/\* //')  # List local branches without highlighting
    else
        echo "Invalid branch type."
        log_message "Invalid branch type: $type."
        exit 1
    fi

    echo "Available $type branches:"
    select branch in $branches; do
        if [ -n "$branch" ]; then
            log_message "Selected $type branch: $branch"
            echo "$branch"
            return
        elif [ -z "$branch" ] && [ "$type" == "remote" ]; then
            echo "No remote branch selected. You can create a new remote branch."
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

# Allow user to select a local branch
local_branch=$(select_branch "local")

# Ask if the user wants to upstream this branch
read -p "Do you want to upstream the local branch '$local_branch' to a remote branch? (y/n): " upstream_response
if [[ "$upstream_response" =~ ^[Yy]$ ]]; then
    # Allow user to select a remote branch or create a new one
    echo "Select a remote branch to upstream to or press Enter to create a new remote branch."
    remote_branch=$(select_branch "remote")

    if [ -z "$remote_branch" ]; then
        # User pressed Enter, create a new remote branch
        remote_branch_name="$local_branch"
        echo "No remote branch selected. Creating a new remote branch with the name: $remote_branch_name"
        log_message "No remote branch selected. Creating a new remote branch: $remote_branch_name"
        if git push --set-upstream origin "$local_branch"; then
            log_message "Local branch '$local_branch' successfully upstreamed to new remote branch '$remote_branch_name'."
        else
            log_message "Failed to upstream local branch '$local_branch' to new remote branch '$remote_branch_name'."
            exit 1
        fi
    else
        # User selected an existing remote branch
        remote_branch_name=$(echo "$remote_branch" | sed 's/origin\///')
        if git push --set-upstream origin "$local_branch:$remote_branch_name"; then
            log_message "Local branch '$local_branch' successfully upstreamed to existing remote branch '$remote_branch_name'."
        else
            log_message "Failed to upstream local branch '$local_branch' to remote branch '$remote_branch_name'."
            exit 1
        fi
    fi
else
    echo "Skipping upstreaming for local branch '$local_branch'."
    log_message "Skipping upstreaming for local branch: $local_branch."
fi

# Push changes to the selected branch
if git push origin "$local_branch"; then
    log_message "Pushed changes to branch: $local_branch successfully."
else
    log_message "Failed to push changes to branch: $local_branch."
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
