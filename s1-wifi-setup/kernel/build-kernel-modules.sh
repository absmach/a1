#!/bin/bash
#
# Kernel Module Build Environment Setup for BeagleV-Fire
#
# This script prepares the kernel build environment necessary
# for compiling the ESP-Hosted driver kernel module.
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "==========================================="
echo "  Kernel Build Environment Setup"
echo "  for BeagleV-Fire ESP32 Integration"
echo "==========================================="
echo ""

# Get current kernel version
KERNEL_VERSION=$(uname -r)
log_info "Current kernel version: $KERNEL_VERSION"

# Check if kernel headers already exist
KERNEL_BUILD_DIR="/lib/modules/$KERNEL_VERSION/build"

if [ -f "$KERNEL_BUILD_DIR/include/linux/module.h" ]; then
    log_success "Kernel headers already present at $KERNEL_BUILD_DIR"
    echo ""
    log_info "You can skip the rest of this setup."
    log_info "Your system is ready to build kernel modules."
    exit 0
fi

log_warning "Kernel headers not found. Starting setup..."
echo ""

# Check for required tools
log_info "Checking for required tools..."
REQUIRED_TOOLS="git make gcc bc flex bison"
MISSING_TOOLS=""

for tool in $REQUIRED_TOOLS; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

if [ -n "$MISSING_TOOLS" ]; then
    log_error "Missing required tools:$MISSING_TOOLS"
    log_info "Install with: sudo apt-get install$MISSING_TOOLS"
    exit 1
fi

log_success "All required tools found"
echo ""

# Clone Microchip kernel if not present
KERNEL_SOURCE_DIR="$HOME/microchip-kernel"

if [ -d "$KERNEL_SOURCE_DIR" ]; then
    log_info "Kernel source already exists at $KERNEL_SOURCE_DIR"
else
    log_info "Cloning Microchip Linux kernel..."
    log_warning "This will download ~1.5 GB and may take 5-15 minutes"
    
    cd ~
    git clone --depth=1 -b linux4microchip+fpga-2025.03 \
        https://github.com/linux4microchip/linux.git microchip-kernel
    
    if [ $? -ne 0 ]; then
        log_error "Failed to clone kernel repository"
        exit 1
    fi
    
    log_success "Kernel source cloned successfully"
fi

cd "$KERNEL_SOURCE_DIR"
echo ""

# Extract running kernel configuration
log_info "Extracting running kernel configuration..."

if [ -f /proc/config.gz ]; then
    zcat /proc/config.gz > .config
    log_success "Configuration extracted from /proc/config.gz"
elif [ -f /boot/config-$KERNEL_VERSION ]; then
    cp /boot/config-$KERNEL_VERSION .config
    log_success "Configuration copied from /boot"
else
    log_error "Cannot find kernel configuration"
    log_error "Please ensure your kernel is compiled with CONFIG_IKCONFIG_PROC=y"
    exit 1
fi

echo ""

# Update configuration for new kernel version
log_info "Updating configuration for current kernel..."
make ARCH=riscv olddefconfig > /dev/null 2>&1

if [ $? -ne 0 ]; then
    log_error "Failed to update kernel configuration"
    exit 1
fi

log_success "Configuration updated"
echo ""

# Prepare kernel module build environment
log_info "Preparing kernel module build environment..."
log_warning "This may take 2-5 minutes..."

make ARCH=riscv modules_prepare

if [ $? -ne 0 ]; then
    log_error "Failed to prepare kernel modules"
    log_error "Check error messages above"
    exit 1
fi

log_success "Kernel module environment prepared"
echo ""

# Install kernel headers system-wide
log_info "Installing kernel headers to /usr/include..."

sudo make ARCH=riscv headers_install INSTALL_HDR_PATH=/usr > /dev/null 2>&1

if [ $? -ne 0 ]; then
    log_warning "Failed to install kernel headers (non-critical)"
else
    log_success "Kernel headers installed"
fi

echo ""

# Create symlink for module builds
log_info "Creating kernel build symlink..."

if [ -L "$KERNEL_BUILD_DIR" ]; then
    log_info "Removing old symlink..."
    sudo rm "$KERNEL_BUILD_DIR"
fi

sudo ln -sf "$KERNEL_SOURCE_DIR" "$KERNEL_BUILD_DIR"

if [ $? -ne 0 ]; then
    log_error "Failed to create symlink"
    exit 1
fi

log_success "Symlink created: $KERNEL_BUILD_DIR -> $KERNEL_SOURCE_DIR"
echo ""

# Verify installation
log_info "Verifying installation..."

ERROR_COUNT=0

# Check for module.h
if [ ! -f "$KERNEL_BUILD_DIR/include/linux/module.h" ]; then
    log_error "module.h not found"
    ERROR_COUNT=$((ERROR_COUNT + 1))
else
    log_success "module.h found"
fi

# Check for Makefile
if [ ! -f "$KERNEL_BUILD_DIR/Makefile" ]; then
    log_error "Makefile not found"
    ERROR_COUNT=$((ERROR_COUNT + 1))
else
    log_success "Makefile found"
fi

# Check for Module.symvers
if [ ! -f "$KERNEL_BUILD_DIR/Module.symvers" ]; then
    log_warning "Module.symvers not found (may be OK)"
else
    log_success "Module.symvers found"
fi

# Check version match
KERNEL_RELEASE=$(cat "$KERNEL_BUILD_DIR/include/config/kernel.release" 2>/dev/null | tr -d '\n')
if [ "$KERNEL_RELEASE" != "$KERNEL_VERSION" ]; then
    log_warning "Kernel version mismatch detected"
    log_warning "  Running: $KERNEL_VERSION"
    log_warning "  Build:   $KERNEL_RELEASE"
    log_warning "This may cause module loading issues"
else
    log_success "Kernel version matches: $KERNEL_VERSION"
fi

echo ""

if [ $ERROR_COUNT -eq 0 ]; then
    echo "==========================================="
    echo "  ✅ Setup Complete!"
    echo "==========================================="
    echo ""
    log_success "Your system is ready to build kernel modules"
    echo ""
    log_info "Next steps:"
    echo "  1. Continue with device tree overlay setup"
    echo "  2. Flash ESP32 firmware"
    echo "  3. Build and load ESP-Hosted driver"
    echo ""
    log_info "See: docs/host-driver.md for next steps"
else
    echo "==========================================="
    echo "  ⚠️  Setup Completed with Warnings"
    echo "==========================================="
    echo ""
    log_warning "$ERROR_COUNT error(s) detected"
    log_info "Module building may not work correctly"
    log_info "Please review errors above and fix before continuing"
fi

echo ""
log_info "Disk space used: $(du -sh $KERNEL_SOURCE_DIR | cut -f1)"
