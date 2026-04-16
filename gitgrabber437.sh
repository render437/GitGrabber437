#!/bin/bash

# --- Configuration ---
# This script fetches and displays the content of a specific file from a public GitHub repository.

# --- Functions ---

# Function to display a message with a visual indicator
function display_message() {
  local message="$1"
  echo ">>> $message"
}

# Function to fetch and display file content from GitHub
function fetch_and_display_file() {
  local repo_url="$1"
  local file_path="$2"
  local default_branch="main" # Common default, but could be 'master'

  # Extract username and repository name from the URL
  # This regex handles URLs like:
  # https://github.com/username/repo
  # https://github.com/username/repo.git
  local repo_info=$(echo "$repo_url" | sed -n 's|https://github.com/\(.*\)/\(.*\)| \1 \2 |p')
  read -r REPO_USER REPO_NAME <<< "$repo_info"

  # Remove .git extension if present
  REPO_NAME=${REPO_NAME%.git}

  if [ -z "$REPO_USER" ] || [ -z "$REPO_NAME" ]; then
    display_message "Error: Could not parse username and repository name from URL '$repo_url'."
    return 1
  fi

  # Construct the raw content URL. We'll try 'main' then 'master' branch.
  local raw_url_main="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${default_branch}/${file_path}"
  local raw_url_master="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/master/${file_path}" # Fallback for 'master' branch

  display_message "Attempting to fetch content for '$file_path' from '${REPO_USER}/${REPO_NAME}'..."

  # Use curl to fetch the content.
  # -s: silent mode, shows errors but no progress meter
  # -f: fail silently (no output at all) on HTTP errors (4xx, 5xx). We'll check the exit code.
  # -L: follow redirects
  local FILE_CONTENT=""

  display_message "Trying default branch: '${default_branch}'..."
  if FILE_CONTENT=$(curl -s -f -L "$raw_url_main"); then
    if [ -n "$FILE_CONTENT" ]; then # Check if content is not empty
      display_message "--- Content of: $file_path (from ${REPO_USER}/${REPO_NAME} - ${default_branch}) ---"
      echo "$FILE_CONTENT"
      display_message "--- End of content for: $file_path ---"
      return 0
    else
      display_message "Content from '${default_branch}' is empty. Trying 'master' branch..."
    fi
  else
    display_message "Failed to fetch from '${default_branch}'. Trying 'master' branch..."
  fi

  # If the first attempt failed or returned empty, try the 'master' branch
  if FILE_CONTENT=$(curl -s -f -L "$raw_url_master"); then
    if [ -n "$FILE_CONTENT" ]; then
      display_message "--- Content of: $file_path (from ${REPO_USER}/${REPO_NAME} - master) ---"
      echo "$FILE_CONTENT"
      display_message "--- End of content for: $file_path ---"
      return 0
    else
      display_message "Error: File content is empty from both '${default_branch}' and 'master' branches. The file might be empty or not exist."
      return 1
    fi
  else
    display_message "Error: Failed to fetch content from 'master' branch as well. Please verify the repository URL, file path, and ensure the repository is public."
    return 1
  fi
}

# --- Main Script Logic ---

display_message "Welcome to GitGrabber437!"
display_message "This script fetches and displays the content of a specific file from a public GitHub repository."

# Prompt the user for the GitHub repository URL
read -p "Please enter the GitHub repository URL (e.g., https://github.com/user/repo): " REPO_URL

# Validate if the input is not empty
if [ -z "$REPO_URL" ]; then
  display_message "Error: No repository URL provided. Exiting."
  exit 1
fi

# Prompt the user for the file path within the repository
read -p "Please enter the exact path to the file within the repository (e.g., README.md or src/app.js): " FILE_PATH

# Validate if the file path is not empty
if [ -z "$FILE_PATH" ]; then
  display_message "Error: No file path provided. Exiting."
  exit 1
fi

# Attempt to fetch and display the file content
if fetch_and_display_file "$REPO_URL" "$FILE_PATH"; then
  display_message "GitGrabber437 process complete."
else
  display_message "GitGrabber437 process failed."
  exit 1
fi

exit 0
