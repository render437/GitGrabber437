#!/bin/bash

# --- Configuration ---
# GitGrabber437: A tool to fetch file content, repo tree, or all files from public GitHub repos.

__version__="1.0.0"

## DEFAULT HOST & PORT
HOST='127.0.0.1'
PORT='8080' 

## ANSI Colors (Foreground + Background)
# Standard Colors
BLACK="$(printf '\033[30m')"   RED="$(printf '\033[31m')"     GREEN="$(printf '\033[32m')"  
YELLOW="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"    MAGENTA="$(printf '\033[35m')"  
CYAN="$(printf '\033[36m')"    WHITE="$(printf '\033[37m')"   ORANGE="$(printf '\033[38;5;208m')"

# Bright Colors
BRIGHT_BLACK="$(printf '\033[90m')"   BRIGHT_RED="$(printf '\033[91m')"    
BRIGHT_GREEN="$(printf '\033[92m')"   BRIGHT_YELLOW="$(printf '\033[93m')"  
BRIGHT_BLUE="$(printf '\033[94m')"    BRIGHT_MAGENTA="$(printf '\033[95m')"  
BRIGHT_CYAN="$(printf '\033[96m')"    BRIGHT_WHITE="$(printf '\033[97m')"

# Background Colors
BLACKBG="$(printf '\033[40m')"   REDBG="$(printf '\033[41m')"     GREENBG="$(printf '\033[42m')"  
YELLOWBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"    MAGENTABG="$(printf '\033[45m')"  
CYANBG="$(printf '\033[46m')"    WHITEBG="$(printf '\033[47m')"

# Bright Background Colors
BRIGHT_BLACKBG="$(printf '\033[100m')"   BRIGHT_REDBG="$(printf '\033[101m')"    
BRIGHT_GREENBG="$(printf '\033[102m')"   BRIGHT_YELLOWBG="$(printf '\033[103m')"  
BRIGHT_BLUEBG="$(printf '\033[104m')"    BRIGHT_MAGENTABG="$(printf '\033[105m')"  
BRIGHT_CYANBG="$(printf '\033[106m')"    BRIGHT_WHITEBG="$(printf '\033[107m')"

# Text Effects
BOLD="$(printf '\033[1m')"
DIM="$(printf '\033[2m')"
ITALIC="$(printf '\033[3m')"
UNDERLINE="$(printf '\033[4m')"
INVERT="$(printf '\033[7m')"
HIDDEN="$(printf '\033[8m')"
STRIKE="$(printf '\033[9m')"

# Reset
RESET="$(printf '\033[0m')"
RESETBG="$(printf '\033[49m')"


## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
	return
}

## Banner
banner() {
    cat << EOF
 ${CYAN}    _______ __  ______           __    __              __ __ __________
 ${CYAN}   / ____(_) /_/ ____/________ _/ /_  / /_  ___  _____/ // /|__  /__  /
 ${CYAN}  / / __/ / __/ / __/ ___/ __ `/ __ \/ __ \/ _ \/ ___/ // /_ /_ <  / / 
 ${CYAN} / /_/ / / /_/ /_/ / /  / /_/ / /_/ / /_/ /  __/ /  /__  __/__/ / / /  
 ${CYAN} \____/_/\__/\____/_/   \__,_/_.___/_.___/\___/_/     /_/ /____/ /_/   
 ${CYAN}     ${RED}Tool created by Render${CYAN}                ${RED}Version: ${__version__}                                                                         
                                                                      
EOF
}

## Small Banner
banner_small() {
	cat <<- EOF
		 ${BLUE} ░█▀▀░▀█▀░▀█▀░█▀▀░█▀▄░█▀█░█▀▄░█▀▄░█▀▀░█▀▄░█░█░▀▀█░▀▀█
		 ${BLUE} ░█░█░░█░░░█░░█░█░█▀▄░█▀█░█▀▄░█▀▄░█▀▀░█▀▄░░▀█░░▀▄░▄▀░
		 ${BLUE} ░▀▀▀░▀▀▀░░▀░░▀▀▀░▀░▀░▀░▀░▀▀░░▀▀░░▀▀▀░▀░▀░░░▀░▀▀░░▀░░
 		 ${BLUE}					${RED}Version ${__version__}
	EOF
}

# Global variables
REPO_URL=""
REPO_USER=""
REPO_NAME=""
DEFAULT_BRANCH="main" # Common default, but could be 'master'
BRANCH_FALLBACK="master"
DIVIDER="-------------------------------------------------------------------------"


# --- Helper Functions ---

# Function to clear the screen
function clear_screen() {
  clear
}

# Function to display a message with a visual indicator
function display_message() {
  local message="$1"
  echo ">>> $message"
}

# Function to display the divider
function print_divider() {
  echo "$DIVIDER"
}

# Function to check if jq is installed
function check_jq() {
  if ! command -v jq &> /dev/null; then
    display_message "Error: The 'jq' command is required for Repository Tree and All Files options."
    display_message "Please install it. For example, on Debian/Ubuntu: sudo apt-get install jq"
    return 1
  fi
  return 0
}

# Function to parse GitHub URL into user and repo name
function parse_repo_url() {
  local url=$1
  # This regex handles URLs like:
  # https://github.com/username/repo
  # https://github.com/username/repo.git
  local repo_info=$(echo "$url" | sed -n 's|https://github.com/\(.*\)/\(.*\)| \1 \2 |p')
  read -r user repo <<< "$repo_info"

  # Remove .git extension if present
  repo=${repo%.git}

  if [ -z "$user" ] || [ -z "$repo" ]; then
    display_message "Error: Could not parse username and repository name from URL '$url'."
    return 1
  fi
  REPO_USER="$user"
  REPO_NAME="$repo"
  return 0
}

# Function to fetch content from a given URL, with fallback branch support
function fetch_content() {
  local url_main="$1"
  local url_master="$2"
  local content=""

  if content=$(curl -s -f -L "$url_main"); then
    if [ -n "$content" ]; then
      echo "$content"
      return 0 # Success
    else
      display_message "Content from '${DEFAULT_BRANCH}' is empty. Trying '${BRANCH_FALLBACK}' branch..."
    fi
  else
    display_message "Failed to fetch from '${DEFAULT_BRANCH}'. Trying '${BRANCH_FALLBACK}' branch..."
  fi

  # Fallback to master branch
  if content=$(curl -s -f -L "$url_master"); then
    if [ -n "$content" ]; then
      echo "$content"
      return 0 # Success
    else
      display_message "Error: File content is empty from both branches. The file might be empty or not exist."
      return 1 # Empty content
    fi
  else
    display_message "Error: Failed to fetch content from '${BRANCH_FALLBACK}' branch as well."
    return 1 # Fetch error
  fi
}

# --- Core Functionalities ---

# Option 1: Fetch Specific File Content
function fetch_specific_file() {
  local file_path="$1"
  local raw_url_main="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${DEFAULT_BRANCH}/${file_path}"
  local raw_url_master="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${BRANCH_FALLBACK}/${file_path}"

  display_message "Attempting to fetch content for '$file_path' from '${REPO_USER}/${REPO_NAME}'..."

  local file_content
  if file_content=$(fetch_content "$raw_url_main" "$raw_url_master"); then
    display_message "--- Content of: $file_path (from ${REPO_USER}/${REPO_NAME}) ---"
    echo "$file_content"
    print_divider
    display_message "--- End of content for: $file_path ---"
    return 0
  else
    display_message "Failed to retrieve content for '$file_path'."
    return 1
  fi
}

# Option 2: Get Repository Tree
function get_repo_tree() {
  if ! check_jq; then return 1; fi

  local api_url_main="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/git/trees/${DEFAULT_BRANCH}?recursive=1"
  local api_url_master="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/git/trees/${BRANCH_FALLBACK}?recursive=1"

  display_message "Fetching repository tree for '${REPO_USER}/${REPO_NAME}'..."

  local tree_data
  if tree_data=$(fetch_content "$api_url_main" "$api_url_master"); then
    display_message "Repository Tree (from ${REPO_USER}/${REPO_NAME}):"
    print_divider

    # Parse JSON using jq and display tree structure
    echo "$tree_data" | jq -r '.tree[] | select(.type == "blob") | .path' | while IFS= read -r file; do
      echo "$file"
    done
    print_divider
    display_message "--- End of Repository Tree ---"
    return 0
  else
    display_message "Failed to retrieve repository tree. Ensure the repo is public and exists."
    return 1
  fi
}

# Option 3: Get Code for All Files (Excluding LICENSE.md/LICENSE)
function get_all_files_content() {
  if ! check_jq; then return 1; fi

  local api_url_main="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/git/trees/${DEFAULT_BRANCH}?recursive=1"
  local api_url_master="https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/git/trees/${BRANCH_FALLBACK}?recursive=1"

  display_message "Fetching list of all files for '${REPO_USER}/${REPO_NAME}'..."

  local tree_data
  if tree_data=$(fetch_content "$api_url_main" "$api_url_master"); then
    local files_list
    # Filter out 'blob' types (files) and exclude LICENSE.md and LICENSE
    files_list=$(echo "$tree_data" | jq -r '.tree[] | select(.type == "blob" and .path != "LICENSE.md" and .path != "LICENSE") | .path')

    if [ -z "$files_list" ]; then
      display_message "No files found to display (after excluding LICENSE.md/LICENSE)."
      return 1
    fi

    local count=0
    local total_files=$(echo "$files_list" | wc -l)

    display_message "Found ${total_files} files (excluding LICENSE.md/LICENSE). Fetching content for each..."
    print_divider

    echo "$files_list" | while IFS= read -r file; do
      ((count++))
      display_message "Fetching file $count/$total_files: $file"
      local raw_url_main="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${DEFAULT_BRANCH}/${file}"
      local raw_url_master="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${BRANCH_FALLBACK}/${file}"

      local file_content
      if file_content=$(fetch_content "$raw_url_main" "$raw_url_master"); then
        # Format as requested: "file name:\n\nfile code:\n"
        echo "File name: $file"
        echo "" # Blank line
        echo "File code:"
        echo "$file_content"
        print_divider # Separator between files
      else
        display_message "Error: Failed to fetch content for '$file'."
        print_divider
      fi
    done
    display_message "--- Finished fetching all files (excluding LICENSE.md/LICENSE). ---"
    return 0
  else
    display_message "Failed to retrieve repository tree to list files. Ensure the repo is public and exists."
    return 1
  fi
}


# --- Main Menu Logic ---
function show_menu() {
  clear_screen
  display_message "Welcome to GitGrabber437!"
  print_divider
  display_message "GitHub Repository: ${REPO_USER}/${REPO_NAME}"
  print_divider
  echo "Please choose an option:"
  echo "  01. Fetch Specific File Content"
  echo "  02. View Repository Tree"
  echo "  03. Fetch Content of All Files (excluding LICENSE)"
  echo "  XX. Exit"
  print_divider
  read -p "Enter your choice: " choice
  echo "" # Newline for spacing
}

# --- Main Script Execution ---
function main() {
  clear_screen
  banner
  display_message "Welcome to GitGrabber437!"
  print_divider
  display_message "This tool helps you interact with public GitHub repositories."
  print_divider

  # Prompt for the GitHub repository URL
  read -p "Please enter the GitHub repository URL (e.g., https://github.com/user/repo): " REPO_URL

  # Validate URL input
  if [ -z "$REPO_URL" ]; then
    display_message "Error: No repository URL provided. Exiting."
    exit 1
  fi

  # Parse the URL to get user and repo name
  if ! parse_repo_url "$REPO_URL"; then
    exit 1
  fi

  # Main loop for the menu
  while true; do
    show_menu

    case "$choice" in
      "01"|"1")
        read -p "Enter the exact path to the file (e.g., README.md or src/app.js): " file_path
        if [ -n "$file_path" ]; then
          fetch_specific_file "$file_path"
        else
          display_message "Error: No file path provided."
        fi
        read -p "Press Enter to continue..."
        ;;
      "02"|"2")
        get_repo_tree
        read -p "Press Enter to continue..."
        ;;
      "03"|"3")
        get_all_files_content
        read -p "Press Enter to continue..."
        ;;
      "XX"|"xx"|"exit"|"quit")
        display_message "Exiting GitGrabber437. Goodbye!"
        exit 0
        ;;
      *)
        display_message "Invalid choice. Please select an option from the menu."
        read -p "Press Enter to continue..."
        ;;
    esac
  done
}

# Execute the main function
main
