#!/bin/bash
###
 # @Author       : ZHANG Hua (zhangh23@mails.tsinghua.edu.cn)
 # @Date         : 2025-12-30 12:09:22
 # @LastEditors  : ZHANG Hua (zhangh23@mails.tsinghua.edu.cn)
 # @LastEditTime : 2025-12-30 16:35:17
 # @Description  : Download file shared script using wget
 # @Usage        : source dld.sh <start_year> <start_month> <start_day> <end_year> <end_month> <end_day>
 # 
 # Copyright (c) 2025 by ZHANG Hua, All Rights Reserved. 
### 

# -----------------------------------------------------------------------------
# Global Configuration
# -----------------------------------------------------------------------------

# Wget options:
#   -N: only download newer files
#   -c: continue partial downloads
# Warning: Do NOT use -b (background) option - may cause access blocking
WGET_OPTS="-N -c"

# Retry configuration
MAX_RETRIES=3          # Maximum number of retry attempts
RETRY_DELAY=5          # Delay between retries (seconds)
FAILED_DOWNLOADS=()    # Array to track failed downloads

# -----------------------------------------------------------------------------
# Function: setup_wget_cert
# Description: Check wget version and set certificate option
# Note: wget >= 1.10 supports --no-check-certificate
# -----------------------------------------------------------------------------
setup_wget_cert() {
    local version major minor
    version=$(wget -V | grep 'GNU Wget ' | cut -d ' ' -f 3)
    major=$(echo "${version}" | cut -d '.' -f 1)
    minor=$(echo "${version}" | cut -d '.' -f 2)
    
    if (( 100 * major + minor > 109 )); then
        WGET_CERT_OPT="--no-check-certificate"
    else
        WGET_CERT_OPT=""
    fi
}

# -----------------------------------------------------------------------------
# Function: parse_date_args
# Description: Parse command line arguments into start/end dates
# Arguments: $1-$3: start year, month, day
#            $4-$6: end year, month, day
# Returns: 0 on success, 1 on failure
# -----------------------------------------------------------------------------
parse_date_args() {
    if [[ $# -lt 6 ]]; then
        echo "Usage: source dld.sh start_year start_month start_day end_year end_month end_day"
        return 1
    fi
    
    START_DATE="$1-$2-$3"
    END_DATE="$4-$5-$6"
    
    echo "Start date: ${START_DATE}"
    echo "End   date: ${END_DATE}"
}

# -----------------------------------------------------------------------------
# Function: validate_date_range
# Description: Check if date range is valid and within MAX_DAY limit
# Globals: START_DATE, END_DATE, MAX_DAY (default: 36)
# Returns: 0 on success, 1 on failure
# -----------------------------------------------------------------------------
validate_date_range() {
    : "${MAX_DAY:=36}"
    
    local start_sec end_sec num_days
    start_sec=$(date -ud "${START_DATE}" +%s)
    end_sec=$(date -ud "${END_DATE}" +%s)
    num_days=$(( (end_sec - start_sec) / 86400 + 1 ))
    
    if (( num_days > MAX_DAY )); then
        echo "Error: Number of days (${num_days}) exceeds limit (${MAX_DAY})."
        return 1
    elif (( num_days < 0 )); then
        echo "Error: End date precedes start date."
        return 1
    fi
    
    echo "Total days: ${num_days}"
}

# -----------------------------------------------------------------------------
# Function: init_time_loop
# Description: Initialize time loop variables (in seconds since epoch)
# Globals: START_DATE, END_DATE
# Sets: START_TIME, END_TIME, CURR_TIME
# -----------------------------------------------------------------------------
init_time_loop() {
    START_TIME=$(date -ud "${START_DATE}" +%s)
    END_TIME=$(date -ud "${END_DATE}" +%s)
    CURR_TIME=${START_TIME}
}

# -----------------------------------------------------------------------------
# Function: get_date_components
# Description: Extract date components from current timestamp
# Globals: CURR_TIME
# Sets: YYYY, JJJ, MM, DD, HH
# -----------------------------------------------------------------------------
get_date_components() {
    YYYY=$(date -ud @${CURR_TIME} +%Y)
    JJJ=$(date -ud @${CURR_TIME} +%j)
    MM=$(date -ud @${CURR_TIME} +%m)
    DD=$(date -ud @${CURR_TIME} +%d)
    HH=$(date -ud @${CURR_TIME} +%H)
    
    echo "Processing: ${YYYY}-${MM}-${DD}"
}

# -----------------------------------------------------------------------------
# Function: ensure_directory
# Description: Create directory if it does not exist
# Arguments: $1 - directory path
# -----------------------------------------------------------------------------
ensure_directory() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}"
        echo "Created directory: ${dir}"
    fi
}

# -----------------------------------------------------------------------------
# Function: download_file
# Description: Download a file using wget
# Arguments: $1 - local directory
#            $2 - remote file URL
# Returns: wget exit status (0 on success, non-zero on failure)
# -----------------------------------------------------------------------------
download_file() {
    local local_dir="$1"
    local remote_url="$2"
    local cmd="wget ${WGET_CERT_OPT} ${WGET_OPTS} -P ${local_dir} ${remote_url}"
    
    echo "${cmd}"
    eval "${cmd}"
    return $?
}

# -----------------------------------------------------------------------------
# Function: download_with_retry
# Description: Download a file with retry logic on failure
# Arguments: $1 - local directory
#            $2 - remote file URL
# Returns: 0 on success, 1 on failure after all retries
# -----------------------------------------------------------------------------
download_with_retry() {
    local local_dir="$1"
    local remote_url="$2"
    local attempt=1
    local status
    
    while (( attempt <= MAX_RETRIES )); do
        download_file "${local_dir}" "${remote_url}"
        status=$?
        
        if (( status == 0 )); then
            return 0
        fi
        
        echo "Warning: Download failed (attempt ${attempt}/${MAX_RETRIES}), exit code: ${status}"
        
        if (( attempt < MAX_RETRIES )); then
            echo "Retrying in ${RETRY_DELAY} seconds..."
            sleep "${RETRY_DELAY}"
        fi
        
        (( attempt++ ))
    done
    
    echo "Error: Download failed after ${MAX_RETRIES} attempts: ${remote_url}"
    return 1
}

# -----------------------------------------------------------------------------
# Function: advance_time
# Description: Increment current time by specified hours
# Arguments: $1 - hours to advance
# Globals: CURR_TIME
# -----------------------------------------------------------------------------
advance_time() {
    local hours="$1"
    (( CURR_TIME += hours * 3600 ))
}

# -----------------------------------------------------------------------------
# Function: run_download_loop
# Description: Main download loop - iterates through time range
# Requires: TIME_RESOLUTION (hours), build_file_paths function
# Note: build_file_paths must set LOCAL_DIR and REMOTE_URL
# -----------------------------------------------------------------------------
run_download_loop() {
    FAILED_DOWNLOADS=()
    
    while (( CURR_TIME <= END_TIME )); do
        get_date_components
        build_file_paths
        ensure_directory "${LOCAL_DIR}"
        
        if ! download_with_retry "${LOCAL_DIR}" "${REMOTE_URL}"; then
            FAILED_DOWNLOADS+=("${REMOTE_URL}")
        fi
        
        advance_time "${TIME_RESOLUTION}"
    done
    
    echo "=========================================="
    if (( ${#FAILED_DOWNLOADS[@]} > 0 )); then
        echo "Download completed with ${#FAILED_DOWNLOADS[@]} failure(s):"
        for url in "${FAILED_DOWNLOADS[@]}"; do
            echo "  - ${url}"
        done
        echo "=========================================="
        return 1
    else
        echo "All files downloaded successfully!"
        echo "=========================================="
        return 0
    fi
}

# -----------------------------------------------------------------------------
# Function: init_downloader
# Description: Main initialization - setup wget, parse args, validate, init loop
# Arguments: Command line arguments (date range)
# Returns: 0 on success, 1 on failure
# -----------------------------------------------------------------------------
init_downloader() {
    setup_wget_cert
    parse_date_args "$@" || return 1
    validate_date_range || return 1
    init_time_loop
}

# -----------------------------------------------------------------------------
# Auto-initialize when sourced with sufficient arguments
# -----------------------------------------------------------------------------
if [[ $# -ge 6 ]]; then
    init_downloader "$@"
fi

