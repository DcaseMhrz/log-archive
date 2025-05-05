#!/usr/bin/env bash
set -euo pipefail

# Must be root to read system logs
if [[ $EUID -ne 0 ]]; then
  echo "This tool must be run as root to read system logs." >&2
  exit 1
fi

# Defaults
verbose=false
output_dir="./archives"
log_file=""

usage() {
  echo "Usage: $0 [-v] [-o <output-dir>] <log-directory>"
  exit 1
}

# Parse -v and -o flags
while getopts ":vo:" opt; do
  case $opt in
    v) verbose=true ;;
    o) output_dir=$OPTARG ;;
    \?) echo "Error: invalid option -$OPTARG" >&2; usage ;;
    :) echo "Error: option -$OPTARG requires an argument." >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# Require a log directory argument
[[ $# -ge 1 ]] || { echo "Error: missing <log-directory>" >&2; usage; }
log_dir=$1

# Validate it exists
[[ -d $log_dir ]] || { echo "Error: '$log_dir' is not a directory or does not exist." >&2; exit 1; }

# Prepare output
mkdir -p "$output_dir"
log_file="$output_dir/archive_log.txt"

# Timestamp for naming
timestamp=$(date +%Y%m%d_%H%M%S)
archive_name="logs_archive_${timestamp}.tar.gz"
archive_path="$output_dir/$archive_name"

# Script-only verbose helper
vecho() { $verbose && echo "$@"; }

vecho "Archiving '$log_dir' → '$archive_path'..."

# Build tar options: always c (create), z (gzip), f (file); add v if verbose
tar_opts="czf"
$verbose && tar_opts="czvf"

# Run tar, listing files if verbose
tar $tar_opts "$archive_path" -C "$log_dir" .

vecho "Archive created."

# Log the action
echo "$(date '+%Y-%m-%d %H:%M:%S') | ARCHIVED $log_dir → $archive_path" >> "$log_file"

vecho "Logged to $log_file."
