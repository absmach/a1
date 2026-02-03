# s1

S1 RISC-V FPGA Linux gateway based on BeagleV-Fire

# Propeller Buildroot External Tree

This is a Buildroot external tree for building a minimal Linux system with Proplet for BeagleV RISC-V boards.

## Quick Start

### 1. Prerequisites

```bash
# Install build dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    cpio \
    unzip \
    rsync \
    bc \
    libncurses5-dev \
    file

# You'll need ~20GB free disk space and 2-4 hours for first build
```

### 2. Clone Buildroot

```bash
# Clone official Buildroot
git clone https://git.buildroot.net/buildroot
cd buildroot

# Optional: Use a stable release
git checkout 2024.11
```

### 3. Clone This External Tree

```bash
# From the buildroot parent directory
cd ..
git clone <your-repo-url> propeller-buildroot
```

Your directory structure should look like:

```
.
├── buildroot/
└── propeller-buildroot/
```

### 4. Configure Buildroot

```bash
cd buildroot

# Load the BeagleV Proplet configuration
make BR2_EXTERNAL=../propeller-buildroot beaglev_proplet_defconfig
```

### 5. Customize Configuration (Optional)

```bash
# Edit Proplet settings
vi ../propeller-buildroot/package/proplet/proplet.conf

# Or use menuconfig to adjust build options
make BR2_EXTERNAL=../propeller-buildroot menuconfig
```

### 6. Build

```bash
# Start the build (this will take 1-3 hours)
make BR2_EXTERNAL=../propeller-buildroot

# Or use parallel builds to speed up
make -j$(nproc) BR2_EXTERNAL=../propeller-buildroot
```

### 7. Find Your Images

```bash
# After successful build, images are in:
ls output/images/

# Key files:
# - rootfs.ext4      Root filesystem for eMMC
# - Image            Linux kernel
# - u-boot.itb       U-Boot bootloader (if built)
# - *.dtb            Device tree blobs
```

---

## What Gets Built

This external tree adds:

- **Proplet**: Edge computing agent with MQTT support
- **Wasmtime**: WebAssembly runtime (v27.0.0)
- **Custom configuration**: Optimized for BeagleV

## Configuration

### 1. SSH into BeagleV

```bash
ssh root@<beaglev-ip>
# or
ssh root@beaglev.local

# Default password: (none) or check your build config
```

### 2. Edit Proplet Configuration

```bash
vi /etc/proplet/proplet.conf

# Update these values:
PROPLET_MQTT_ADDRESS=tcp://192.168.1.100:1883  # Your broker IP
PROPLET_DOMAIN_ID=your-domain-id
PROPLET_CHANNEL_ID=your-channel-id
PROPLET_CLIENT_ID=your-client-id
PROPLET_CLIENT_KEY=your-client-key
```

### 3. Restart Proplet

```bash
systemctl restart proplet
systemctl status proplet

# Check logs
journalctl -u proplet -f
```

---
