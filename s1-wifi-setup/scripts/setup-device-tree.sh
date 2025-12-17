#!/bin/bash
#
# Device Tree Overlay Setup Script
#
# This script compiles and applies the device tree overlay for ESP-Hosted
# SPI communication on BeagleV-Fire.
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

echo "==========================================="
echo "  Device Tree Overlay Setup"
echo "==========================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
OVERLAY_DIR="$SCRIPT_DIR/overlays"
DTS_FILE="$OVERLAY_DIR/beaglev-esp-hosted.dts"
DTBO_FILE="$OVERLAY_DIR/beaglev-esp-hosted.dtbo"

# Step 1: Compile device tree overlay (if source exists and binary doesn't)
if [ -f "$DTS_FILE" ]; then
    if [ ! -f "$DTBO_FILE" ] || [ "$DTS_FILE" -nt "$DTBO_FILE" ]; then
        log_info "Compiling device tree overlay..."
        
        dtc -O dtb -o "$DTBO_FILE" -b 0 -@ "$DTS_FILE"
        
        if [ $? -ne 0 ]; then
            log_error "Failed to compile device tree overlay"
            exit 1
        fi
        
        log_success "Device tree overlay compiled"
    else
        log_info "Device tree overlay already compiled"
    fi
elif [ ! -f "$DTBO_FILE" ]; then
    log_error "Neither source ($DTS_FILE) nor compiled overlay ($DTBO_FILE) found"
    exit 1
fi

# Step 2: Load SPI modules
log_info "Loading SPI kernel modules..."

modprobe spidev 2>/dev/null || log_warning "spidev module not available"
modprobe spi-microchip-core 2>/dev/null || log_warning "spi-microchip-core not available"
modprobe spi-microchip-core-qspi 2>/dev/null || log_warning "spi-microchip-core-qspi not available"

log_success "SPI modules loaded"

# Step 3: Copy overlay to firmware directory
log_info "Installing device tree overlay..."

mkdir -p /boot/overlays
mkdir -p /lib/firmware

cp "$DTBO_FILE" /lib/firmware/

if [ $? -ne 0 ]; then
    log_error "Failed to copy overlay to /lib/firmware"
    exit 1
fi

log_success "Overlay installed to /lib/firmware"

# Step 4: Apply overlay
log_info "Applying device tree overlay..."

# Remove old overlay if it exists
if [ -d /sys/kernel/config/device-tree/overlays/esp-hosted ]; then
    log_info "Removing existing overlay..."
    rmdir /sys/kernel/config/device-tree/overlays/esp-hosted 2>/dev/null || true
fi

# Create overlay directory
mkdir -p /sys/kernel/config/device-tree/overlays/esp-hosted

# Apply overlay
echo "beaglev-esp-hosted.dtbo" > /sys/kernel/config/device-tree/overlays/esp-hosted/path

if [ $? -ne 0 ]; then
    log_error "Failed to apply device tree overlay"
    log_error "Check dmesg for details: dmesg | tail -20"
    exit 1
fi

# Give it a moment to apply
sleep 1

# Step 5: Verify overlay status
OVERLAY_STATUS=$(cat /sys/kernel/config/device-tree/overlays/esp-hosted/status 2>/dev/null || echo "unknown")

if [ "$OVERLAY_STATUS" = "applied" ]; then
    log_success "Device tree overlay applied successfully"
else
    log_warning "Overlay status: $OVERLAY_STATUS"
fi

# Step 6: Verify SPI device
log_info "Verifying SPI device..."

if [ -e /dev/spidev0.0 ]; then
    log_success "SPI device /dev/spidev0.0 is present"
    ls -l /dev/spidev0.0
else
    log_error "SPI device /dev/spidev0.0 not found"
    log_error "Try: sudo reboot (overlay may require reboot to take effect)"
    exit 1
fi

echo ""
echo "==========================================="
echo "  ✅ Device Tree Setup Complete"
echo "==========================================="
echo ""
log_info "Next steps:"
echo "  1. Verify ESP32 is flashed with SPI firmware"
echo "  2. Connect hardware (see main README for pinout)"
echo "  3. Build and load ESP-Hosted driver"
echo ""
