# s1 Board WiFi Setup

Automated WiFi setup for s1 board (BeagleV-Fire + ESP32).

## Quick Start

```bash
# On s1 board
sudo ./setup-s1.sh

# On dev machine (for ESP32)
cd esp-firmware
./flash-esp32.sh /dev/ttyUSB0
```

## What's Included

- **setup-s1.sh** - Complete automated setup for s1
- **kernel/build-kernel-modules.sh** - Kernel headers and build environment
- **esp-firmware/flash-esp32.sh** - ESP32 firmware flashing automation
- **overlays/beaglev-esp-hosted.dts** - Device tree overlay for SPI
- **scripts/setup-device-tree.sh** - DT compilation and application
- **scripts/verify-setup.sh** - Verify everything works

## Hardware Connections (s1 Board)

| ESP32 Pin | s1 Board Pin | Function  |
| --------- | ------------ | --------- |
| GPIO13    | SPI0_MOSI    | MOSI      |
| GPIO12    | SPI0_MISO    | MISO      |
| GPIO14    | SPI0_CLK     | Clock     |
| GPIO15    | SPI0_CS0     | CS        |
| GPIO2     | GPIO 513     | Handshake |
| GPIO4     | GPIO 514     | Data Rdy  |
| EN        | GPIO 512     | Reset     |
| GND       | GND          | Ground    |

## Key Changes from Upstream esp-hosted

### For BeagleV-Fire (RISC-V)

1. **Architecture**: `ARCH=arm` → `ARCH=riscv`
2. **GPIO pins**: Updated in `esp_spi.h`
   - `HANDSHAKE_PIN` → 513
   - `SPI_DATA_READY_PIN` → 514
3. **Reset pin**: `resetpin=6` → `resetpin=512` in init script
4. **Removed**: ARM-specific raspi-gpio commands
5. **Added**: Device tree overlay for Microchip PolarFire SoC

### Files Modified in esp-hosted Fork

```bash
esp_hosted_ng/host/
├── beaglev_init.sh              # Created from rpi_init.sh
└── linux/host_driver/esp32/spi/
    └── esp_spi.h                # GPIO pins changed to 513, 514
```

## Usage

```bash
# After setup, connect to WiFi:
sudo ip link set wlan0 up
sudo iw dev wlan0 scan
wpa_passphrase "SSID" "password" | sudo tee /etc/wpa_supplicant.conf
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
sudo dhclient wlan0
```

## Troubleshooting

```bash
# Check status
./scripts/verify-setup.sh

# View logs
dmesg | grep -i esp

# Check SPI
ls /dev/spidev0.0

# Check interface
ip link show wlan0
```
