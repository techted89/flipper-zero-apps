#!/usr/bin/env bash
set -euo pipefail

# Flipper Zero FAP Build Script
# Compiles external Flipper applications (.fap) with comprehensive error handling,
# artifact management, and build reporting.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIRMWARE_DIR="$ROOT_DIR/firmware"
APPS_USER_DIR="$ROOT_DIR/applications_user"
BUILD_OUTPUT_DIR="$ROOT_DIR/build/fap"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="$ROOT_DIR/build/build_${TIMESTAMP}.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$BUILD_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$BUILD_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$BUILD_LOG"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$BUILD_LOG"
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Flipper Zero external applications (.fap)

OPTIONS:
  -a, --app APP_ID        Build specific app (e.g., example_hello)
  -A, --all               Build all apps in applications_user/
  -c, --clean             Clean build output before building
  -v, --verbose           Enable verbose output
  -o, --output DIR        Output directory for .fap files (default: $BUILD_OUTPUT_DIR)
  -h, --help              Show this help message

EXAMPLES:
  # Build specific app
  $0 --app example_hello

  # Build all apps
  $0 --all

  # Clean build all apps
  $0 --clean --all

  # Build with custom output directory
  $0 --app my_app --output ./dist

EOF
    exit 0
}

# Parse arguments
parse_args() {
    local app_id=""
    local build_all=false
    local clean_build=false
    local verbose=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--app)
                app_id="$2"
                shift 2
                ;;
            -A|--all)
                build_all=true
                shift
                ;;
            -c|--clean)
                clean_build=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -o|--output)
                BUILD_OUTPUT_DIR="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    echo "$app_id" "$build_all" "$clean_build" "$verbose"
}

# Initialize build environment
init_build_env() {
    log_info "Initializing build environment..."
    
    mkdir -p "$BUILD_OUTPUT_DIR"
    mkdir -p "$(dirname "$BUILD_LOG")"
    
    # Write build header to log
    {
        echo "=========================================="
        echo "Flipper Zero FAP Build Log"
        echo "Generated: $(date)"
        echo "=========================================="
        echo ""
    } > "$BUILD_LOG"
    
    log_info "Build log: $BUILD_LOG"
}

# Validate environment
validate_env() {
    log_info "Validating build environment..."
    
    if [ ! -d "$FIRMWARE_DIR" ]; then
        log_error "Firmware directory not found: $FIRMWARE_DIR"
        log_info "Please run: git submodule update --init --recursive"
        exit 1
    fi
    
    if [ ! -f "$FIRMWARE_DIR/fbt" ] && [ ! -f "$FIRMWARE_DIR/fbt.cmd" ]; then
        log_error "fbt not found in $FIRMWARE_DIR"
        exit 1
    fi
    
    if [ ! -d "$APPS_USER_DIR" ]; then
        log_error "Applications directory not found: $APPS_USER_DIR"
        exit 1
    fi
    
    log_info "Environment validation passed"
}

# Get list of available apps
get_available_apps() {
    local apps=()
    
    if [ -d "$APPS_USER_DIR" ]; then
        for app_dir in "$APPS_USER_DIR"/*; do
            if [ -d "$app_dir" ]; then
                local app_name=$(basename "$app_dir")
                if [ -f "$app_dir/application.fam" ]; then
                    apps+=("$app_name")
                fi
            fi
        done
    fi
    
    printf '%s\n' "${apps[@]}"
}

# Build single app
build_app() {
    local app_id=$1
    local verbose=$2
    
    log_info "Building app: $app_id"
    
    # Verify app exists
    if [ ! -d "$APPS_USER_DIR/$app_id" ]; then
        log_error "App directory not found: $APPS_USER_DIR/$app_id"
        return 1
    fi
    
    if [ ! -f "$APPS_USER_DIR/$app_id/application.fam" ]; then
        log_error "application.fam not found for app: $app_id"
        return 1
    fi
    
    cd "$FIRMWARE_DIR"
    
    local build_cmd="./fbt fap_$app_id"
    
    if [ "$verbose" = true ]; then
        log_debug "Executing: $build_cmd"
        $build_cmd 2>&1 | tee -a "$BUILD_LOG"
    else
        $build_cmd >> "$BUILD_LOG" 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_info "Successfully built: $app_id"
        
        # Try to locate and copy the generated .fap file
        find_and_copy_fap "$app_id"
        return 0
    else
        log_error "Failed to build: $app_id"
        return 1
    fi
}

# Find and copy generated .fap file
find_and_copy_fap() {
    local app_id=$1
    
    # Search for the generated .fap file
    local fap_file=$(find "$FIRMWARE_DIR/build" -name "${app_id}.fap" -type f 2>/dev/null | head -1)
    
    if [ -n "$fap_file" ] && [ -f "$fap_file" ]; then
        cp "$fap_file" "$BUILD_OUTPUT_DIR/${app_id}.fap"
        log_info "Copied .fap to: $BUILD_OUTPUT_DIR/${app_id}.fap"
    else
        log_warn "Could not locate generated .fap file for: $app_id"
    fi
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."
    
    cd "$FIRMWARE_DIR"
    ./fbt clean 2>&1 | tee -a "$BUILD_LOG"
    
    rm -rf "$BUILD_OUTPUT_DIR"/*
    log_info "Build output cleaned"
}

# Build report
build_report() {
    local status=$1
    local app_list=$2
    
    cat << EOF | tee -a "$BUILD_LOG"

=========================================="
Build Report
=========================================="
Status:       $([ $status -eq 0 ] && echo "SUCCESS" || echo "FAILED")
Timestamp:    $(date)
Output Dir:   $BUILD_OUTPUT_DIR
Log File:     $BUILD_LOG

Built Apps:
$app_list

FAP Files:
$(ls -lh "$BUILD_OUTPUT_DIR"/*.fap 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' || echo "  None")

=========================================="
EOF
}

# Main build process
main() {
    local args=$(parse_args "$@")
    read -r app_id build_all clean_build verbose <<< "$args"
    
    init_build_env
    validate_env
    
    if [ "$clean_build" = true ]; then
        clean_build
    fi
    
    local built_apps=()
    local failed_apps=()
    
    if [ "$build_all" = true ]; then
        log_info "Building all available apps..."
        
        local available_apps=$(get_available_apps)
        if [ -z "$available_apps" ]; then
            log_warn "No apps found in $APPS_USER_DIR"
            exit 1
        fi
        
        while IFS= read -r app; do
            if build_app "$app" "$verbose"; then
                built_apps+=("$app")
            else
                failed_apps+=("$app")
            fi
        done <<< "$available_apps"
    elif [ -n "$app_id" ]; then
        if build_app "$app_id" "$verbose"; then
            built_apps+=("$app_id")
        else
            failed_apps+=("$app_id")
        fi
    else
        log_error "No app specified. Use -a APP_ID or -A for all apps"
        usage
    fi
    
    # Print summary
    local build_status=0
    echo "" | tee -a "$BUILD_LOG"
    log_info "Build Summary:"
    log_info "  Built: ${#built_apps[@]} app(s)"
    log_info "  Failed: ${#failed_apps[@]} app(s)"
    
    if [ ${#failed_apps[@]} -gt 0 ]; then
        log_error "Failed to build:"
        for app in "${failed_apps[@]}"; do
            log_error "  - $app"
        done
        build_status=1
    fi
    
    # Generate report
    local app_list=$(printf '  - %s\n' "${built_apps[@]}")
    build_report $build_status "$app_list"
    
    exit $build_status
}

# Run main function
main "$@"
