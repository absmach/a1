# Connect S1 Board as SuperMQ Client

This guide demonstrates how to connect your BeagleV S1 board to a SuperMQ instance for IoT messaging and data management.

**Note on RISC-V Support**: SuperMQ is being enabled for RISC-V architecture. Until native RISC-V Docker images are available, run SuperMQ on an x86/ARM development machine and connect your S1 board to it for testing and development. This temporary setup allows you to develop IoT applications, test messaging protocols (MQTT, CoAP, HTTP), and work with SuperMQ's APIs while preparing for native deployment on the S1 board.

## Architecture Overview

- **Your x86/ARM Computer**: Runs the SuperMQ server (MQTT broker, authentication, data storage)
- **BeagleV Board**: Connects to SuperMQ and can publish/subscribe to messages

## Prerequisites

- A BeagleV S1 board
- Docker and Docker Compose installed on your x86/ARM computer
- Both your computer and BeagleV on the same network
- USB-C cable or Ethernet cable for connecting the S1 board

## Connecting to Your BeagleV S1 Board

Before setting up SuperMQ, you need to establish a connection to your S1 board.

### Option 1: USB Serial Connection

**On Linux:**

1. Connect the S1 board via USB-C cable
2. Find the serial device:

   ```bash
   ls /dev/ttyUSB* /dev/ttyACM*
   # Usually /dev/ttyUSB0 or /dev/ttyACM0
   ```

3. Connect using screen:

   ```bash
   screen /dev/ttyUSB0 115200
   ```

   **On macOS:**

4. Connect the S1 board to your computer via USB-C cable
5. Power on the S1 board
6. Find the serial device:

   ```bash
   ls /dev/tty.*
   # Look for something like /dev/tty.usbmodem1234BBBK56783
   ```

7. Connect using screen:

   ```bash
   screen /dev/tty.usbmodem1234BBBK56783 115200
   ```

   If you get a `$TERM too long` error, use:

   ```bash
   TERM=xterm screen /dev/tty.usbmodem1234BBBK56783 115200
   ```

**Default Login:**

- Username: `beagle`
- Password: varies by image (commonly `temppwd` or no password)

**Exiting screen:** Press `Ctrl+A` then `K`, confirm with `y`

### Option 2: SSH Connection

Once your S1 board has network connectivity, SSH is more convenient for multiple terminal sessions.

**Via USB Network:**

```bash
ssh beagle@192.168.7.2
```

**Via Ethernet (after connecting to your network):**

First, connect to the board via serial (Option 1) and configure network:

1. **Connect Ethernet cable** from your router to the S1 board

2. **Get an IP address:**

   ```bash
   sudo dhcpcd eth0
   ```

3. **Find the assigned IP:**

   ```bash
   ip addr show eth0
   # Look for the inet line, e.g., 192.168.8.133
   ```

4. **From your computer, SSH to that IP:**

   ```bash
   ssh beagle@192.168.8.133  # Use your actual IP
   ```

### Enabling Internet Access on S1 Board

Your S1 board needs internet access to install packages like mosquitto-clients.

**If connected via Ethernet:**
The board should automatically get internet access via DHCP:

```bash
# Test connectivity
ping -c 4 8.8.8.8
ping -c 4 google.com
```

**If connected via USB only:**
Enable internet sharing on your computer:

- **Linux:** Use `iptables` and IP forwarding (varies by distribution)

Then on the S1 board:

```bash
sudo ip route add default via 192.168.7.1 dev usb0
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
ping -c 4 google.com
```

- **macOS:** System Settings → Sharing → Internet Sharing
  - Share from: Wi-Fi
  - To: USB connection (RNDIS/Ethernet Gadget)

## Part 1: Setup SuperMQ Locally on Your x86/ARM Machine

### 1.1 Clone and Start SuperMQ

On your x86 or ARM computer (not on the BeagleV):

```bash
git clone https://github.com/absmach/supermq.git
cd supermq
make run up args="-d"
```

Wait for all containers to start (check with `docker ps`).

### 1.2 Install SuperMQ CLI

The CLI tool helps you provision users, domains, clients, and channels:

```bash
# Download the CLI
make cli

# Or build from source
cd cmd/cli
go build -o ../../build/cli main.go
cd ../..
```

### 1.3 Provision SuperMQ Resources

Follow these steps to create the necessary resources. For complete CLI documentation, see the [SuperMQ CLI Documentation](https://docs.supermq.absmach.eu/cli).

#### Step 1: Create a User

```bash
./build/cli users create <username> <email> <password>
```

#### Step 2: Get User Token

```bash
./build/cli users token <username> <password>
# Save this access token as token as USER_TOKEN
export USER_TOKEN=<your-user-token>
```

#### Step 3: Create a Domain

```bash
./build/cli domains create '{"name":"my-domain"}' $USER_TOKEN
# Note the domain ID from the response
export DOMAIN_ID=<your-domain-id>
```

#### Step 4: Create a Client (Thing)

```bash
./build/cli clients create '{"name":"beaglev-sensor"}' $DOMAIN_ID $USER_TOKEN
# Note the client ID and secret from the response
export CLIENT_ID=<your-client-id>
export CLIENT_KEY=<your-client-secret>
```

#### Step 5: Create a Channel

```bash
./build/cli channels create '{"name":"sensor-data"}' $DOMAIN_ID $USER_TOKEN
# Note the channel ID from the response
export CHANNEL_ID=<your-channel-id>
```

#### Step 6: Connect Client to Channel

```bash
./build/cli clients connect $CLIENT_ID $CHANNEL_ID '["publisher","subscriber"]' $DOMAIN_ID $USER_TOKEN
```

### 1.4 Find Your Computer's IP Address

You'll need your x86/ARM machine's IP address to connect from the BeagleV:

```bash
# On Linux
ip addr show

# On macOS
ifconfig | grep "inet "

# Look for your local network IP (e.g., 192.168.x.x or 10.x.x.x)
export SUPERMQ_HOST=<your-computer-ip>  # e.g., 192.168.8.108
```

**Important**: Use your local network IP, not `127.0.0.1` or `localhost`.

## Part 2: Connect BeagleV Board

### 2.1 Install MQTT Client on BeagleV

SSH into your BeagleV board and install mosquitto-clients:

```bash
sudo apt update
sudo apt install mosquitto-clients
```

### 2.2 Set Environment Variables

On the BeagleV, configure the connection details using the values from Part 1:

```bash
export SUPERMQ_HOST=<your-computer-ip>      # From Step 1.4
export DOMAIN_ID=<your-domain-id>           # From Step 1.3
export CHANNEL_ID=<your-channel-id>         # From Step 1.3
export CLIENT_ID=<your-client-id>           # From Step 1.3
export CLIENT_KEY=<your-client-secret>      # From Step 1.3
```

**One-line export (replace with your actual values):**

```bash
export SUPERMQ_HOST=192.168.8.108 DOMAIN_ID=<domain-id> CHANNEL_ID=<channel-id> CLIENT_ID=<client-id> CLIENT_KEY=<client-secret>
```

### 2.3 Test the Connection

Verify network connectivity:

```bash
ping -c 4 $SUPERMQ_HOST
```

## Part 3: Publish and Subscribe

### 3.1 Subscribe to Messages (On Your x86/ARM Machine)

Open a terminal on your x86/ARM computer and subscribe to the channel:

```bash
mosquitto_sub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h localhost -v
```

This will wait and display any messages published to this channel.

### 3.2 Publish Messages (On BeagleV Board)

From your BeagleV board, publish sensor data:

```bash
mosquitto_pub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h $SUPERMQ_HOST -m '{"temperature": 25.5, "humidity": 60}'
```

You should see this message appear in your subscriber terminal!

### 3.3 Publish Sensor Data in SenML Format

SuperMQ supports the SenML (Sensor Markup Language) format:

```bash
mosquitto_pub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h $SUPERMQ_HOST -m '[{"bn":"beaglev-sensor:","bu":"A","bver":5,"n":"voltage","u":"V","v":3.3}, {"n":"current","u":"A","v":0.5}]'
```

## Advanced: Secure Connections (MQTTS)

For production deployments, use encrypted MQTT connections.

### Copy SSL Certificates to BeagleV

From your x86/ARM computer (in the supermq directory):

```bash
scp ./docker/ssl/certs/ca.crt beagle@<beaglev-ip>:/home/beagle/ca.crt
```

### Subscribe with TLS

**On your x86/ARM machine:**

```bash
mosquitto_sub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h localhost --cafile ./docker/ssl/certs/ca.crt -p 8883 -v
```

**On BeagleV Board:**

```bash
mosquitto_pub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h $SUPERMQ_HOST --cafile ca.crt -p 8883 -m '{"temperature": 25.5}'
```

## Alternative Protocols

### CoAP Client

Install CoAP CLI on your x86/ARM machine:

```bash
git clone https://github.com/absmach/coap-cli.git
cd coap-cli
make all
scp ./build/coap-cli-linux-riscv64 beagle@<beaglev-ip>:/home/beagle/coap-cli
```

**Publish via CoAP from BeagleV Board:**

```bash
./coap-cli post m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $SUPERMQ_HOST -d '[{"bn":"coap-device:","n":"temperature","u":"Cel","v":25.5}]'
```

### HTTP Client

**Publish via HTTP from BeagleV Board:**

```bash
curl -X POST \
  -H "Content-Type: application/senml+json" \
  -H "Authorization: Client $CLIENT_KEY" \
  http://$SUPERMQ_HOST:8008/m/$DOMAIN_ID/c/$CHANNEL_ID/messages \
  -d '[{"bn":"http-device:","n":"temperature","u":"Cel","v":25.5}]'
```

## Troubleshooting

### Connection Refused

- Verify SuperMQ is running on your x86/ARM machine: `docker ps` (should show multiple containers)
- Check your computer's firewall settings
- Ensure MQTT port 1883 is accessible from the network

### Authentication Failed

- Verify CLIENT_KEY is the **client secret**, not the client ID
- Ensure the client is connected to the channel (Step 1.3, Part 6)
- Check that the domain ID matches

### Messages Not Appearing

- Ensure subscriber and publisher use the **exact same topic**
- Verify both are using the same DOMAIN_ID and CHANNEL_ID
- Check SuperMQ logs: `docker logs supermq-mqtt`

## Additional Resources

- [SuperMQ Documentation](https://docs.supermq.absmach.eu/)
- [SuperMQ CLI Reference](https://docs.supermq.absmach.eu/cli)
- [Clients Management](https://docs.supermq.absmach.eu/cli#clients-management)
- [Channels Management](https://docs.supermq.absmach.eu/cli#channels-management)
- [SenML Format Specification](https://tools.ietf.org/html/rfc8428)

## Quick Reference Commands

```bash
# Create user and get token
./build/cli users create <username> <email> <password>
./build/cli users token <username> <password>

# Create resources
./build/cli domains create '{"name":"<domain-name>"}' $USER_TOKEN
./build/cli clients create '{"name":"<client-name>"}' $DOMAIN_ID $USER_TOKEN
./build/cli channels create '{"name":"<channel-name>"}' $DOMAIN_ID $USER_TOKEN

# Connect client to channel
./build/cli clients connect $CLIENT_ID $CHANNEL_ID '["publisher","subscriber"]' $DOMAIN_ID $USER_TOKEN

# Publish from BeagleV Board
mosquitto_pub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h $SUPERMQ_HOST -m '{"sensor":"data"}'

# Subscribe on x86/ARM machine
mosquitto_sub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h localhost -v
```
