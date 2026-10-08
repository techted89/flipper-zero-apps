#!/usr/bin/env bash
set -euo pipefail

# Flipper Zero FAP Build Environment Setup Script
# This script initializes the build environment for Flipper Zero external applications (.fap)
# It sets up the firmware dependency, validates the build tools, and prepares the workspace.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIRMWARE_DIR="$ROOT_DIR/firmware"
APPS_USER_DIR="$ROOT_DIR/applications_user"
BUILD_DIR="$ROOT_DIR/build"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    if ! command -v git &> /dev/null; then
        log_error "git is not installed"
        missing=1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is not installed"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Please install missing prerequisites and try again"
        exit 1
    fi
    
    log_info "All prerequisites found"
}

# Initialize firmware submodule
init_firmware_submodule() {
    log_info "Initializing firmware submodule..."
    
    if [ ! -d "$FIRMWARE_DIR/.git" ]; then
        cd "$ROOT_DIR"
        git submodule update --init --recursive
    fi
    
    if [ ! -f "$FIRMWARE_DIR/fbt" ]; then
        log_error "Firmware initialization failed. fbt not found."
        exit 1
    fi
    
    log_info "Firmware submodule initialized at $FIRMWARE_DIR"
}

# Create directory structure
setup_directories() {
    log_info "Setting up directory structure..."
    
    mkdir -p "$APPS_USER_DIR"
    mkdir -p "$BUILD_DIR"
    
    if [ ! -f "$APPS_USER_DIR/README.md" ]; then
        cat > "$APPS_USER_DIR/README.md" << 'EOF'
# External Applications

Place your Flipper Zero .fap applications here. Each app should have its own directory with:

- `application.fam` - Application manifest
- Source files (`.c`, `.h`, etc.)

Example structure:

```
applications_user/
└── my_app/
    ├── application.fam
    ├── my_app.c
    └── my_app.h
```

For more information, see the [Flipper Zero Developer Documentation](https://developer.flipper.net/flipperzero/).
EOF
    fi
    
    log_info "Directory structure ready"
}

# Validate firmware build system
validate_fbt() {
    log_info "Validating Flipper Build Tool (fbt)..."
    
    cd "$FIRMWARE_DIR"
    
    if [ ! -f "fbt" ] && [ ! -f "fbt.cmd" ]; then
        log_error "fbt executable not found in $FIRMWARE_DIR"
        exit 1
    fi
    
    log_info "fbt validation successful"
}

# Display build information
show_build_info() {
    cat << EOF

${GREEN}=== Flipper Zero FAP Build Environment ===${NC}

Root Directory:       $ROOT_DIR
Firmware Directory:   $FIRMWARE_DIR
Apps Directory:       $APPS_USER_DIR
Build Directory:      $BUILD_DIR

${GREEN}Quick Start:${NC}

1. Create a new app:
   mkdir -p applications_user/my_app
   cat > applications_user/my_app/application.fam << 'MANIFEST'
App(
    appid="my_app",
    name="My App",
    apptype=FlipperAppType.EXTERNAL,
    entry_point="my_app_main",
    stack_size=2 * 1024,
    fap_category="Misc",
)
MANIFEST

2. Implement your app:
   # Create my_app.c with your app logic

3. Build the app:
   cd $FIRMWARE_DIR
   ./fbt fap_my_app

4. The .fap file will be generated in the build output directory

${GREEN}Available Commands:${NC}

Build all FAPs:
  cd $FIRMWARE_DIR && ./fbt fap

Build specific FAP:
  cd $FIRMWARE_DIR && ./fbt fap_my_app

Clean build:
  cd $FIRMWARE_DIR && ./fbt clean

Generate VSCode workspace:
  cd $FIRMWARE_DIR && ./fbt vscode_dist

${GREEN}Documentation:${NC}

- Developer Docs: https://developer.flipper.net/flipperzero/
- Application Manifests: firmware/documentation/AppManifests.md
- Flipper Build Tool: firmware/documentation/fbt.md

EOF
}

# Main execution
main() {
    log_info "Starting Flipper Zero FAP build environment setup..."
    
    check_prerequisites
    init_firmware_submodule
    setup_directories
    validate_fbt
    show_build_info
    
    log_info "Setup complete! Your environment is ready for FAP development."
}

main "$@"
