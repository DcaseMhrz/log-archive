# Use the environment’s bash interpreter
#!/usr/bin/env bash

# Exit immediately on errors, unset vars, or pipeline failures
set -euo pipefail

# If not running as root, print error and exit
if [[ $EUID -ne 0 ]]; then
  echo "This tool must be run as root to read system logs." >&2
  exit 1
fi

# Default: verbose mode off
verbose=false
# Default output directory for archives
output_dir="./archives"
# Placeholder for the path to the archive log file
log_file=""

# Function to display correct usage and exit
usage() {
  echo "Usage: $0 [-v] [-o <output-dir>] <log-directory>"
  exit 1
}

# Parse flags: -v for verbose, -o to specify output directory
while getopts ":vo:" opt; do
  case $opt in
    v) verbose=true ;;                       # Turn on verbose output
    o) output_dir=$OPTARG ;;                 # Set custom output directory
    \?) echo "Error: invalid option -$OPTARG" >&2; usage ;;  # Handle unknown flags
    :) echo "Error: option -$OPTARG requires an argument." >&2; usage ;;  # Handle missing args
  esac
done
# Remove parsed options from positional parameters
shift $((OPTIND -1))

# Ensure a log directory argument was provided
if [[ $# -lt 1 ]]; then
  echo "Error: missing <log-directory>" >&2
  usage
fi
# Capture the provided log directory
log_dir=$1

# Verify the log directory exists and is a directory
if [[ ! -d $log_dir ]]; then
  echo "Error: '$log_dir' is not a directory or does not exist." >&2
  exit 1
fi

# Create the output directory if it doesn’t already exist
mkdir -p "$output_dir"
# Define the path to the archive log file
log_file="$output_dir/archive_log.txt"

# Generate a timestamp for the archive filename
timestamp=$(date +%Y%m%d_%H%M%S)
# Build the archive filename using the timestamp
archive_name="logs_archive_${timestamp}.tar.gz"
# Full path to where the archive will be saved
archive_path="$output_dir/$archive_name"

# Helper function: print messages only if verbose is true
vecho() {
  $verbose && echo "$@"
}

# Notify (if verbose) that archiving is starting
vecho "Archiving '$log_dir' → '$archive_path'..."

# Create a compressed tarball of the entire log directory
tar -czf "$archive_path" -C "$log_dir" .

# Notify (if verbose) that the archive was created
vecho "Archive created."

# Append a timestamped entry to the archive log file
echo "$(date '+%Y-%m-%d %H:%M:%S') | ARCHIVED $log_dir → $archive_path" >> "$log_file"

# Notify (if verbose) that the logging entry was written
vecho "Logged to $log_file."
