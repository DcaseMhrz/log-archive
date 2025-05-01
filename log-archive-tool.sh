#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This tool must be run as root to read system logs." >&2
  exit 1
fi

# Default settings
verbose=false
output_dir="./archives"
log_file=""

usage() {
  echo "Usage: $0 [-v] [-o <output-dir>] <log-directory>"
  exit 1
}

# Parse flags
while getopts ":vo:" opt; do
  case $opt in
    v) verbose=true ;;
    o) output_dir=$OPTARG ;;
    \?) echo "Error: invalid option -$OPTARG" >&2; usage ;;
    :) echo "Error: option -$OPTARG requires an argument." >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# Ensure we have a log directory
if [[ $# -lt 1 ]]; then
  echo "Error: missing <log-directory>" >&2
  usage
fi
log_dir=$1

# Validate source directory
if [[ ! -d $log_dir ]]; then
  echo "Error: '$log_dir' is not a directory or does not exist." >&2
  exit 1
fi

# Prepare output directory and log file
mkdir -p "$output_dir"
log_file="$output_dir/archive_log.txt"

# Timestamp for archive name
timestamp=$(date +%Y%m%d_%H%M%S)
archive_name="logs_archive_${timestamp}.tar.gz"
archive_path="$output_dir/$archive_name"

# Helper for verbose messages
vecho() {
  $verbose && echo "$@"
}

vecho "Archiving '$log_dir' → '$archive_path'..."

# Create the tar.gz (the trailing `.` is critical)
sudo tar -czf "$archive_path" -C "$log_dir" .

vecho "Archive created."

# Record the action
echo "$(date '+%Y-%m-%d %H:%M:%S') | ARCHIVED $log_dir → $archive_path" >> "$log_file"

vecho "Logged to $log_file."
