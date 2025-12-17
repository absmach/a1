#!/bin/bash
#
# Setup Verification Script
#
# This script verifies that all components of the ESP-Hosted
# setup are properly installed and configured.
#

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

echo "==========================================="
echo "  ESP-Hosted Setup Verification"
echo "==========================================="
echo ""

# Check 1: Kernel headers
echo "1. Checking kernel headers..."
if [ -f "/lib/modules/$(uname -r)/build/include/linux/module.h" ]; then
    check_pass "Kernel headers present"
else
    check_fail "Kernel headers missing"
    echo "   Run: kernel/build-kernel-modules.sh"
fi
echo ""

# Check 2: Device tree overlay
echo "2. Checking device tree overlay..."
if [ -f /sys/kernel/config/device-tree/overlays/esp-hosted/status ]; then
    STATUS=$(cat /sys/kernel/config/device-tree/overlays/esp-hosted/status)
    if [ "$STATUS" = "applied" ]; then
        check_pass "Device tree overlay applied"
    else
        check_warn "Device tree overlay status: $STATUS"
    fi
else
    check_fail "Device tree overlay not applied"
    echo "   Run: scripts/setup-device-tree.sh"
fi
echo ""

# Check 3: SPI device
echo "3. Checking SPI device..."
if [ -e /dev/spidev0.0 ]; then
    check_pass "SPI device /dev/spidev0.0 present"
    ls -l /dev/spidev0.0 | awk '{print "   " $0}'
else
    check_fail "SPI device /dev/spidev0.0 not found"
    echo "   Try: sudo reboot (overlay may require reboot)"
fi
echo ""

# Check 4: SPI kernel modules
echo "4. Checking SPI kernel modules..."
if lsmod | grep -q "spi.*microchip"; then
    check_pass "Microchip SPI modules loaded"
    lsmod | grep "spi.*microchip" | awk '{print "   " $1}'
else
    check_warn "Microchip SPI modules not loaded"
    echo "   Try: sudo modprobe spi-microchip-core"
fi
echo ""

# Check 5: ESP-Hosted kernel module
echo "5. Checking ESP-Hosted driver..."
if lsmod | grep -q esp32_spi; then
    check_pass "ESP32 SPI driver loaded"
    lsmod | grep esp32 | awk '{print "   " $0}'
else
    check_warn "ESP32 SPI driver not loaded"
    echo "   This is expected if you haven't run beaglev_init.sh yet"
fi
echo ""

# Check 6: Network interface
echo "6. Checking WiFi interface..."
if ip link show wlan0 &>/dev/null; then
    check_pass "wlan0 interface present"
    ip link show wlan0 | awk '{print "   " $0}'
else
    check_warn "wlan0 interface not present"
    echo "   This will appear after ESP-Hosted driver loads and ESP32 responds"
fi
echo ""

# Check 7: cfg80211 module
echo "7. Checking wireless support..."
if lsmod | grep -q cfg80211; then
    check_pass "cfg80211 wireless module loaded"
else
    check_warn "cfg80211 module not loaded"
    echo "   Try: sudo modprobe cfg80211"
fi
echo ""

# Check 8: ESP-Hosted repository
echo "8. Checking ESP-Hosted repository..."
if [ -d "$HOME/esp-hosted/esp_hosted_ng/host" ]; then
    check_pass "ESP-Hosted repository present"
    
    # Check for beaglev_init.sh
    if [ -f "$HOME/esp-hosted/esp_hosted_ng/host/beaglev_init.sh" ]; then
        check_pass "beaglev_init.sh script present"
    else
        check_warn "beaglev_init.sh not found"
        echo "   You need to create this from rpi_init.sh"
    fi
else
    check_fail "ESP-Hosted repository not found"
    echo "   Clone with: git clone --recurse-submodules https://github.com/espressif/esp-hosted.git"
fi
echo ""

# Check 9: Kernel logs
echo "9. Checking kernel logs for ESP messages..."
if dmesg | grep -qi esp; then
    ESP_MESSAGES=$(dmesg | grep -i esp | tail -5)
    if echo "$ESP_MESSAGES" | grep -qi "error\|fail\|timeout"; then
        check_warn "Found error messages in kernel log"
        echo "$ESP_MESSAGES" | tail -3 | awk '{print "   " $0}'
    else
        check_pass "No errors in recent ESP kernel messages"
        echo "$ESP_MESSAGES" | tail -2 | awk '{print "   " $0}'
    fi
else
    check_warn "No ESP messages in kernel log"
    echo "   This is normal if driver hasn't been loaded yet"
fi
echo ""

# Summary
echo "==========================================="
echo "  Verification Summary"
echo "==========================================="
echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "${YELLOW}Warnings:${NC} $WARN_COUNT"
echo -e "${RED}Failed:${NC} $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo "Your system is fully configured."
    echo ""
    echo "If you haven't already:"
    echo "  1. Flash ESP32 firmware (esp-firmware/flash-esp32.sh)"
    echo "  2. Connect hardware (see main README)"
    echo "  3. Load driver (sudo ~/esp-hosted/esp_hosted_ng/host/beaglev_init.sh spi)"
    echo "  4. Connect to WiFi"
elif [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Setup mostly complete with warnings${NC}"
    echo "Some components are not yet loaded, which may be normal"
    echo "depending on your setup stage."
    echo ""
    echo "Review warnings above and:"
    echo "  - Load missing kernel modules if needed"
    echo "  - Run beaglev_init.sh to load ESP-Hosted driver"
else
    echo -e "${RED}❌ Setup incomplete${NC}"
    echo "Please fix the failed checks above."
    echo ""
    echo "Common fixes:"
    echo "  - Kernel headers: Run kernel/build-kernel-modules.sh"
    echo "  - Device tree: Run scripts/setup-device-tree.sh"
    echo "  - SPI device: Reboot after applying overlay"
fi

echo ""

# Additional diagnostic info
if [ $FAIL_COUNT -gt 0 ] || [ $WARN_COUNT -gt 2 ]; then
    echo "==========================================="
    echo "  Diagnostic Information"
    echo "==========================================="
    echo ""
    
    echo "Kernel version:"
    uname -r
    echo ""
    
    echo "Loaded kernel modules (SPI/ESP related):"
    lsmod | grep -E "spi|esp|cfg80211" || echo "  None found"
    echo ""
    
    echo "Available SPI devices:"
    ls -l /dev/spi* 2>/dev/null || echo "  None found"
    echo ""
    
    echo "Network interfaces:"
    ip link show | grep -E "^[0-9]:" | awk '{print "  " $2}'
    echo ""
fi
