#!/bin/bash
#
# ESP32 Firmware Flashing Script
#
# This script automates the process of building and flashing
# ESP-Hosted firmware to ESP32 for SPI mode operation.
#
# Usage: ./flash-esp32.sh [port]
#   port: Serial port (e.g., /dev/ttyUSB0, COM3)
#         If not specified, script will attempt to detect
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
echo "  ESP32 Firmware Flashing"
echo "  ESP-Hosted SPI Mode"
echo "==========================================="
echo ""

# Detect or use provided serial port
if [ -n "$1" ]; then
    PORT="$1"
    log_info "Using specified port: $PORT"
else
    log_info "Attempting to auto-detect serial port..."
    
    # Try common Linux ports
    if [ -e /dev/ttyUSB0 ]; then
        PORT="/dev/ttyUSB0"
    elif [ -e /dev/ttyACM0 ]; then
        PORT="/dev/ttyACM0"
    elif [ -e /dev/cu.usbserial-* ]; then
        PORT=$(ls /dev/cu.usbserial-* | head -n 1)
    else
        log_error "Could not auto-detect serial port"
        echo ""
        echo "Available ports:"
        ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial)" || echo "  None found"
        echo ""
        echo "Usage: $0 <port>"
        echo "Example: $0 /dev/ttyUSB0"
        exit 1
    fi
    
    log_success "Detected port: $PORT"
fi

# Verify port exists
if [ ! -e "$PORT" ]; then
    log_error "Port $PORT not found"
    echo ""
    echo "Available ports:"
    ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial)" || echo "  None found"
    exit 1
fi

echo ""

# Check for ESP-IDF
log_info "Checking for ESP-IDF..."

if [ -z "$IDF_PATH" ]; then
    log_warning "ESP-IDF environment not loaded"
    
    # Try to find and source ESP-IDF
    if [ -f "$HOME/esp-idf/export.sh" ]; then
        log_info "Found ESP-IDF at $HOME/esp-idf"
        log_info "Sourcing ESP-IDF environment..."
        source "$HOME/esp-idf/export.sh"
    else
        log_error "ESP-IDF not found"
        echo ""
        echo "Please install ESP-IDF first:"
        echo "  cd ~"
        echo "  git clone --recursive https://github.com/espressif/esp-idf.git"
        echo "  cd esp-idf"
        echo "  ./install.sh esp32"
        echo "  source ./export.sh"
        echo ""
        echo "Then run this script again"
        exit 1
    fi
fi

log_success "ESP-IDF found: $IDF_PATH"

# Check for idf.py
if ! command -v idf.py &> /dev/null; then
    log_error "idf.py not found in PATH"
    log_error "Please source ESP-IDF environment: source ~/esp-idf/export.sh"
    exit 1
fi

echo ""

# Check for ESP-Hosted repository
ESP_HOSTED_DIR="$HOME/esp-hosted/esp_hosted_ng/esp/esp_driver"
ESP_HOSTED_REPO="${ESP_HOSTED_REPO:-https://github.com/absmach/esp-hosted.git}"

if [ ! -d "$ESP_HOSTED_DIR" ]; then
    log_warning "ESP-Hosted repository not found"
    log_info "Cloning ESP-Hosted from $ESP_HOSTED_REPO..."
    
    cd "$HOME"
    git clone --recurse-submodules "$ESP_HOSTED_REPO"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to clone ESP-Hosted"
        exit 1
    fi
    
    log_success "ESP-Hosted cloned"
fi

cd "$ESP_HOSTED_DIR"
log_info "Working directory: $ESP_HOSTED_DIR"
echo ""

# Set target to ESP32
log_info "Setting target to ESP32..."
idf.py set-target esp32

if [ $? -ne 0 ]; then
    log_error "Failed to set target"
    exit 1
fi

log_success "Target set to ESP32"
echo ""

# Check if already configured for SPI
if [ -f sdkconfig ]; then
    if grep -q "CONFIG_ESP_SPI_HOST_INTERFACE=y" sdkconfig 2>/dev/null; then
        log_info "Already configured for SPI mode"
    else
        log_warning "Configuration may not be set for SPI mode"
        log_info "You may want to run: idf.py menuconfig"
        log_info "And verify: Example Configuration → Transport layer → SPI"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborting. Please configure and run again."
            exit 1
        fi
    fi
fi

# Build firmware
log_info "Building firmware..."
log_warning "This may take 5-15 minutes on first build..."
echo ""

idf.py build

if [ $? -ne 0 ]; then
    log_error "Build failed"
    log_error "Check error messages above"
    exit 1
fi

log_success "Firmware built successfully"
echo ""

# Check firmware size
FIRMWARE_SIZE=$(ls -lh build/network_adapter.bin 2>/dev/null | awk '{print $5}')
if [ -n "$FIRMWARE_SIZE" ]; then
    log_info "Firmware size: $FIRMWARE_SIZE"
fi

echo ""

# Flash firmware
log_info "Flashing firmware to ESP32..."
log_info "Port: $PORT"
log_warning "Make sure ESP32 is connected and powered"
echo ""

read -p "Press Enter to start flashing (Ctrl+C to cancel)..."

idf.py -p "$PORT" flash

if [ $? -ne 0 ]; then
    log_error "Flashing failed"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check USB connection"
    echo "  2. Try holding BOOT button and pressing RESET"
    echo "  3. Try different USB port or cable"
    echo "  4. Check port permissions: sudo usermod -a -G dialout $USER"
    exit 1
fi

log_success "Firmware flashed successfully"
echo ""

# Monitor output
log_info "Starting serial monitor to verify firmware..."
log_warning "Press Ctrl+] to exit monitor"
echo ""

sleep 2

idf.py -p "$PORT" monitor

echo ""
echo "==========================================="
echo "  ✅ ESP32 Flashing Complete"
echo "==========================================="
echo ""
log_info "Next steps:"
echo "  1. Disconnect ESP32 from computer"
echo "  2. Connect ESP32 to BeagleV-Fire (see main README)"
echo "  3. Power on both devices"
echo "  4. Load ESP-Hosted driver on BeagleV-Fire"
echo ""
