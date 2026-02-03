#!/bin/bash
set -e

TARGET_DIR=$1

echo "==> Proplet post-build script for BeagleV"

# Create proplet user and group
if ! grep -q "^proplet:" ${TARGET_DIR}/etc/group 2>/dev/null; then
    echo "Creating proplet group..."
    echo "proplet:x:1000:" >> ${TARGET_DIR}/etc/group
fi

if ! grep -q "^proplet:" ${TARGET_DIR}/etc/passwd 2>/dev/null; then
    echo "Creating proplet user..."
    echo "proplet:x:1000:1000:Propeller Proplet:/var/lib/proplet:/bin/sh" \
        >> ${TARGET_DIR}/etc/passwd
fi

# Create directories
echo "Creating proplet directories..."
mkdir -p ${TARGET_DIR}/var/lib/proplet/{wasm-cache,workloads,data}
mkdir -p ${TARGET_DIR}/var/log/proplet
mkdir -p ${TARGET_DIR}/tmp/proplet
mkdir -p ${TARGET_DIR}/etc/proplet

# Set ownership and permissions
echo "Setting permissions..."
chown -R 1000:1000 ${TARGET_DIR}/var/lib/proplet 2>/dev/null || true
chown -R 1000:1000 ${TARGET_DIR}/var/log/proplet 2>/dev/null || true
chmod 1777 ${TARGET_DIR}/tmp/proplet 2>/dev/null || true
chmod 755 ${TARGET_DIR}/usr/bin/proplet 2>/dev/null || true
chmod 644 ${TARGET_DIR}/etc/proplet/proplet.conf 2>/dev/null || true

# Enable proplet service
if [ -d "${TARGET_DIR}/etc/systemd/system" ]; then
    echo "Enabling proplet service..."
    mkdir -p ${TARGET_DIR}/etc/systemd/system/multi-user.target.wants
    ln -sf /usr/lib/systemd/system/proplet.service \
        ${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/proplet.service
fi

echo "==> Post-build completed successfully"
echo ""
echo "=============================================="
echo "IMPORTANT: Configuration Required!"
echo "=============================================="
echo "After booting BeagleV, you MUST edit:"
echo "  /etc/proplet/proplet.conf"
echo ""
echo "Update these values:"
echo "  PROPLET_MQTT_ADDRESS=tcp://YOUR_BROKER_IP:1883"
echo "  PROPLET_DOMAIN_ID=your-domain-id"
echo "  PROPLET_CHANNEL_ID=your-channel-id"
echo "  PROPLET_CLIENT_ID=your-client-id"
echo "  PROPLET_CLIENT_KEY=your-client-key"
echo ""
echo "Then restart proplet:"
echo "  systemctl restart proplet"
echo "=============================================="
