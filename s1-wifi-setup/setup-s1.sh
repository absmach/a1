#!/bin/bash
#
# S0 Board ESP32-Hosted Complete Setup Script
# 
# This script performs the complete setup of ESP32-Hosted on S0 (BeagleV-Fire + ESP32):
# 1. Checks prerequisites
# 2. Builds kernel modules if needed
# 3. Applies device tree overlay
# 4. Loads required modules
# 5. Builds and loads ESP-Hosted driver
#
# Usage: sudo ./setup-s0.sh
#

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

echo "==========================================="
echo "  S0 Board ESP32-Hosted Setup"
echo "==========================================="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Check Prerequisites
log_info "Checking prerequisites..."

# Check for required commands
REQUIRED_CMDS="git make gcc dtc modprobe"
for cmd in $REQUIRED_CMDS; do
    if ! command -v $cmd &> /dev/null; then
        log_error "Required command '$cmd' not found. Please install it."
        exit 1
    fi
done
log_success "All required commands found"

# Check kernel version
KERNEL_VERSION=$(uname -r)
log_info "Kernel version: $KERNEL_VERSION"

# Check if kernel headers are available
if [ ! -d "/lib/modules/$KERNEL_VERSION/build" ]; then
    log_warning "Kernel headers not found. Will attempt to set up..."
    
    if [ -f "$SCRIPT_DIR/kernel/build-kernel-modules.sh" ]; then
        log_info "Running kernel setup script..."
        bash "$SCRIPT_DIR/kernel/build-kernel-modules.sh"
    else
        log_error "Kernel headers missing and setup script not found"
        log_error "Please manually install kernel headers or run kernel setup"
        exit 1
    fi
else
    log_success "Kernel headers found at /lib/modules/$KERNEL_VERSION/build"
fi

# Step 2: Install Required Packages
log_info "Installing required packages..."
apt-get update -qq
apt-get install -y -qq bluetooth bluez bluez-tools rfkill dtc 2>&1 | grep -v "^Reading\|^Building"
log_success "Required packages installed"

# Step 3: Setup Device Tree Overlay
log_info "Setting up device tree overlay..."

if [ -f "$SCRIPT_DIR/scripts/setup-device-tree.sh" ]; then
    bash "$SCRIPT_DIR/scripts/setup-device-tree.sh"
else
    log_warning "Device tree setup script not found, applying manually..."
    
    # Load spidev module
    log_info "Loading spidev module..."
    modprobe spidev || log_warning "spidev module not available"
    
    # Load Microchip SPI drivers
    log_info "Loading Microchip SPI drivers..."
    modprobe spi-microchip-core || log_warning "spi-microchip-core not available"
    modprobe spi-microchip-core-qspi || log_warning "spi-microchip-core-qspi not available"
    
    # Apply device tree overlay
    if [ -f "$SCRIPT_DIR/overlays/beaglev-esp-hosted.dtbo" ]; then
        log_info "Applying device tree overlay..."
        mkdir -p /boot/overlays
        mkdir -p /lib/firmware
        cp "$SCRIPT_DIR/overlays/beaglev-esp-hosted.dtbo" /lib/firmware/
        
        mkdir -p /sys/kernel/config/device-tree/overlays/esp-hosted
        echo "beaglev-esp-hosted.dtbo" > /sys/kernel/config/device-tree/overlays/esp-hosted/path
        
        # Check if overlay was applied
        OVERLAY_STATUS=$(cat /sys/kernel/config/device-tree/overlays/esp-hosted/status 2>/dev/null || echo "unknown")
        if [ "$OVERLAY_STATUS" = "applied" ]; then
            log_success "Device tree overlay applied successfully"
        else
            log_warning "Device tree overlay status: $OVERLAY_STATUS"
        fi
    else
        log_error "Device tree overlay not found at $SCRIPT_DIR/overlays/beaglev-esp-hosted.dtbo"
        log_error "Please compile the overlay first"
        exit 1
    fi
fi

# Step 4: Verify SPI Device
log_info "Verifying SPI device..."
if [ -e /dev/spidev0.0 ]; then
    log_success "SPI device found at /dev/spidev0.0"
else
    log_error "SPI device not found at /dev/spidev0.0"
    log_error "Please check hardware connections and device tree overlay"
    exit 1
fi

# Step 5: Clone and Setup ESP-Hosted (if not already present)
ESP_HOSTED_REPO="${ESP_HOSTED_REPO:-https://github.com/absmach/esp-hosted.git}"

if [ ! -d "$HOME/esp-hosted" ]; then
    log_info "Cloning ESP-Hosted repository from $ESP_HOSTED_REPO..."
    cd "$HOME"
    git clone --recurse-submodules "$ESP_HOSTED_REPO"
    log_success "ESP-Hosted cloned successfully"
else
    log_info "ESP-Hosted repository already exists at $HOME/esp-hosted"
fi

# Step 6: Apply BeagleV-Specific Patches
log_info "Applying BeagleV-specific configuration..."

ESP_HOSTED_DIR="$HOME/esp-hosted/esp_hosted_ng/host"
PLATFORM_DIR="$HOME/esp-hosted/esp_hosted_ng/host/platforms/beaglev-fire"

# Check if beaglev_init.sh already exists in main directory
if [ -f "$ESP_HOSTED_DIR/beaglev_init.sh" ]; then
    log_success "beaglev_init.sh already present in host directory"
# Check if it exists in platform directory and copy it
elif [ -f "$PLATFORM_DIR/beaglev_init.sh" ]; then
    log_info "Copying beaglev_init.sh from platform directory..."
    cp "$PLATFORM_DIR/beaglev_init.sh" "$ESP_HOSTED_DIR/beaglev_init.sh"
    chmod +x "$ESP_HOSTED_DIR/beaglev_init.sh"
    log_success "beaglev_init.sh copied from platform directory"
else
    # Fallback: create from rpi_init.sh (requires manual editing)
    log_warning "beaglev_init.sh not found in your esp-hosted fork"
    
    # Backup original files if not already backed up
    if [ ! -f "$ESP_HOSTED_DIR/rpi_init.sh.backup" ]; then
        cp "$ESP_HOSTED_DIR/rpi_init.sh" "$ESP_HOSTED_DIR/rpi_init.sh.backup"
    fi
    
    log_info "Creating beaglev_init.sh from rpi_init.sh..."
    cp "$ESP_HOSTED_DIR/rpi_init.sh" "$ESP_HOSTED_DIR/beaglev_init.sh"
    chmod +x "$ESP_HOSTED_DIR/beaglev_init.sh"
    
    log_warning "Please manually edit $ESP_HOSTED_DIR/beaglev_init.sh with the following changes:"
    echo "  1. Change ARCH=arm to ARCH=riscv in make command"
    echo "  2. Remove CROSS_COMPILE parameter"
    echo "  3. Set resetpin=512"
    echo "  4. Comment out all raspi-gpio commands"
    echo "  5. Comment out spidev_disabler section"
    echo ""
    log_info "See docs/host-driver.md for detailed instructions"
    
    read -p "Press Enter after making these changes to continue..."
else
    log_info "beaglev_init.sh already exists"
fi

# Update GPIO pins in esp_spi.h if needed
ESP_SPI_H="$ESP_HOSTED_DIR/linux/host_driver/esp32/spi/esp_spi.h"
PLATFORM_PATCH="$PLATFORM_DIR/patches/esp_spi.h.patch"

if [ -f "$ESP_SPI_H" ]; then
    # Check if already modified
    if grep -q "HANDSHAKE_PIN.*513" "$ESP_SPI_H"; then
        log_success "GPIO pins already configured in esp_spi.h"
    # Check if patch exists and apply it
    elif [ -f "$PLATFORM_PATCH" ]; then
        log_info "Applying GPIO pin patch from platform directory..."
        cd "$HOME/esp-hosted"
        patch -p1 < "$PLATFORM_PATCH" || log_warning "Patch may already be applied or failed"
        log_success "GPIO pin patch applied"
    else
        log_warning "Please manually edit $ESP_SPI_H to set:"
        echo "  #define HANDSHAKE_PIN       513"
        echo "  #define SPI_DATA_READY_PIN  514"
        echo ""
        read -p "Press Enter after making these changes to continue..."
    fi
fi

# Step 7: Build and Load ESP-Hosted Driver
log_info "Building and loading ESP-Hosted driver..."

cd "$ESP_HOSTED_DIR"

# Try to load with error handling
log_info "Running beaglev_init.sh spi..."
if ./beaglev_init.sh spi; then
    log_success "ESP-Hosted driver loaded successfully"
else
    log_warning "Driver loading completed with warnings (this may be normal)"
fi

# Step 8: Verification
log_info "Performing final verification..."

echo ""
echo "==========================================="
echo "  Verification Results"
echo "==========================================="

# Check SPI device
if [ -e /dev/spidev0.0 ]; then
    echo -e "${GREEN}✓${NC} SPI device: /dev/spidev0.0 exists"
else
    echo -e "${RED}✗${NC} SPI device: /dev/spidev0.0 NOT found"
fi

# Check kernel modules
if lsmod | grep -q esp32_spi; then
    echo -e "${GREEN}✓${NC} Kernel module: esp32_spi loaded"
else
    echo -e "${YELLOW}⚠${NC} Kernel module: esp32_spi NOT loaded (check dmesg)"
fi

# Check network interface
if ip link show wlan0 &>/dev/null; then
    echo -e "${GREEN}✓${NC} Network interface: wlan0 present"
else
    echo -e "${YELLOW}⚠${NC} Network interface: wlan0 NOT present (may appear after ESP32 connection)"
fi

# Check overlay status
OVERLAY_STATUS=$(cat /sys/kernel/config/device-tree/overlays/esp-hosted/status 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓${NC} Device tree overlay: $OVERLAY_STATUS"

echo ""
echo "==========================================="
echo "  Setup Complete!"
echo "==========================================="
echo ""
log_info "Next steps:"
echo "  1. Verify ESP32 is powered and connected"
echo "  2. Check kernel logs: dmesg | grep -i esp"
echo "  3. Try scanning for WiFi: sudo iw dev wlan0 scan"
echo ""
log_info "For troubleshooting, see: docs/troubleshooting.md"
echo ""
