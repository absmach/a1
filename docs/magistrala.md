# Connect S1 Board as Magistrala Client

This guide demonstrates how to connect your BeagleV S1 board to a [Magistrala](https://docs.Magistrala.absmach.eu) instance for IoT messaging and data management.

**Note on RISC-V Support**: Magistrala is being enabled for RISC-V architecture. Until native RISC-V Docker images are available, run Magistrala on an x86/ARM development machine and connect your S1 board to it for testing and development. This temporary setup allows you to develop IoT applications, test messaging protocols (MQTT, CoAP, HTTP), and work with Magistrala's APIs while preparing for native deployment on the S1 board.

## Architecture Overview

- **Your x86/ARM Computer**: Runs the Magistrala (MQTT broker, authentication, data storage)
- **BeagleV Board**: Connects to Magistrala and can publish/subscribe to messages

## Prerequisites

- A BeagleV S1 board
- Docker and Docker Compose installed on your x86/ARM computer
- Both your computer and BeagleV on the same network
- USB-C cable or Ethernet cable for connecting the S1 board

## Connecting to Your BeagleV S1 Board

Before setting up Magistrala, you need to establish a connection to your S1 board.

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

## 1. Setting up and running Magistrala on your PC

Setting up Magistrala is easy. Clone the repository from Github to your PC.

```bash
git clone https://github.com/absmach/magistrala.git
cd magistrala
make run_latest
```

### Install the Magistrala CLI

The cli makes it easy to to manage users, clients, channels and messages. It can be downloaded as separate asset from project realeses or it can be built. For our purposes we will build the CLI.

Build the Magistrala cli and see the available commands using the commands.

```bash
make cli
magistrala-cli health <service>
```

### Create a User

We start off by creating a user.

```bash
magistrala-cli users create <first_name> <last_name> <email> <username> <password>
```

example:

```bash
 magistrala-cli users create john doe johndoe@example.com johndoe 12345678 
```

Expected Response:

```bash
{
  "created_at": "2025-02-11T16:15:12.607701Z",
  "credentials": {
    "username": "johndoe"
  },
  "email": "johndoe@example.com",
  "first_name": "jane",
  "id": "26ae3198-6060-4308-824c-c846953b9898",
  "last_name": "doe",
  "role": "user",
  "status": "enabled",
  "updated_at": "0001-01-01T00:00:00Z"
}
```

### Get Access Token

```bash
# command: magistrala-cli users token <username> <password>
# The command returns the user token.git status
# Then save the access token as USER_TOKEN
magistrala-cli users token johndoe 12345678
export USER_TOKEN=<your-user-token>
```

### Create a Domain

```bash
# command: magistrala-cli domains create <my-domain-name> <route-name> $USER_TOKEN
# This returns the domain ID
# Then save the domain ID as DOMAIN_ID
# export DOMAIN_ID=<your-domain-id>
magistrala-cli domains create "mydomain" "myalias" $USER_TOKEN
export DOMAIN_ID="56a4462e-5001-4bcf-b421-dbbe3d59c53c"
```

### Create a Client

```bash
# command: magistrala-cli clients create '{"name":"client-name"}' $DOMAIN_ID $USER_TOKEN 
# This command returns the client id and the client key
# Then save the client ID and client secret as CLIENT_ID and CLIENT_KEY
# export CLIENT_ID=<your-client-id>
# export CLIENT_KEY=<your-client-secret>
magistrala-cli clients create '{"name":"client_name"}' $DOMAIN_ID $USER_TOKEN
export CLIENT_ID="bd2733d1-fcda-4974-bd7b-63b87a2e150f"
export CLIENT_KEY="6b648c99-d753-4ccb-9954-db6a504f0737"
```

### Create a Channel

```bash
# command: magistrala-cli channels create '{"name":"channel-name"}' $DOMAIN_ID $USER_TOKEN 
# This command returns the channel id
# Then save the channel ID as CHANNEL_ID
# export CHANNEL_ID=<your-channel-id>
magistrala-cli channels create '{"name":"mychannel"}' $DOMAIN_ID $USER_TOKEN
export CHANNEL_ID="0efb859c-f606-442d-9c9e-fd924cfee654"
```

### Connect Client to Channel

```bash
magistrala-cli clients connect $CLIENT_ID $CHANNEL_ID '["publisher","subscriber"]' $DOMAIN_ID $USER_TOKEN
```

Magistrala setup is now complete. We now setup BeagleV Fire.

## Setup the BeagleV Fire

Power the BeagleV-Fire using the USB cable. Find the serial device and connect with your board using screen

```bash
ls /dev/ttyUSB* /dev/ttyACM*
# Usually /dev/ttyUSB0 or /dev/ttyACM0
sudo screen /dev/ttyUSB0 115200
```

### Login to the terminal

```bash
Username: beagle
Password: temppwd
```

Connect an Ethernet cable from the router to the Beagle and get an IP address:

```bash
sudo dhcpcd eth0
ip addr show eth0
# Look for the inet line, e.g., 192.168.8.133
```

With this the Board is connected to the internet and you can now install packages.

### Install mosquitto-clients

```bash
sudo apt update
sudo apt install mosquitto mosquitto-clients -y
```

Set the environment variables by configuring the connection details from the credentials acquired in the Magistrala setup.

```bash
export MAGISTRALA_HOST=<your-computer-ip>
# Magistrala runs in your PC Therefore use your PC's IP  
export DOMAIN_ID="56a4462e-5001-4bcf-b421-dbbe3d59c53c"
export CHANNEL_ID="0efb859c-f606-442d-9c9e-fd924cfee654"
export CLIENT_ID="bd2733d1-fcda-4974-bd7b-63b87a2e150f"
export CLIENT_KEY="6b648c99-d753-4ccb-9954-db6a504f0737"
```

Test the connection. It should result to:

```bash
ping -c 4 $MAGISTRALA_HOST

PING <hostname> (<ip-address>) 56(84) bytes of data.
64 bytes from <ip-address>: icmp_seq=1 ttl=XX time=YY ms
64 bytes from <ip-address>: icmp_seq=2 ttl=XX time=YY ms
64 bytes from <ip-address>: icmp_seq=3 ttl=XX time=YY ms
64 bytes from <ip-address>: icmp_seq=4 ttl=XX time=YY ms

--- <hostname> ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time ZZZ ms
rtt min/avg/max/mdev = aaaa/bbbb/cccc/dddd ms
```

Now that the board is all setup and mosquitto is installed, we can connect to Magistrala.

## MQTT Connection

Using MQTT, on your PC terminal, subscribe to a topic with the following command:

```bash
mosquitto_sub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h localhost -v
```

In this case, we have created a topic called messages and are subscribing to it . This will wait and display any messages published to this channel.

### To publish messages on the BeagleV Fire terminal

```bash
mosquitto_pub -u $CLIENT_KEY -P "" -t "m/$DOMAIN_ID/c/$CHANNEL_ID/messages" -h $MAGISTRALA_HOST -m '{"temperature": 25.5, "humidity": 60}'
```

The message should appear in your PC subscriber terminal.

## CoAP Connection

For this protocol we first need to install the CoAP CLI on your PC.

```bash
git clone https://github.com/absmach/coap-cli.git
cd coap-cli
make all
scp ./build/coap-cli-linux-riscv64 beagle@<beaglev-ip>:/home/beagle/coap-cli
# This sends the CoAP cli from your PC to the BeagleV board
```

### Publishing via CoAP from BeagleV side

```bash
./coap-cli post m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $MAGISTRALA_HOST -d '[{"bn":"coap-device:","n":"temperature","u":"Cel","v":25.5}]'
```

### Subscribing via CoAP from BeagleV side

```bash
coap-cli get m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $MAGISTRALA_HOST -o
```

With this, that is how you conne
### HTTP Client

**Publish via HTTP from BeagleV Board:**

```bash
curl -X POST \
  -H "Content-Type: application/senml+json" \
  -H "Authorization: Client $CLIENT_KEY" \
  http://$Magistrala_HOST:8008/m/$DOMAIN_ID/c/$CHANNEL_ID/messages \
  -d '[{"bn":"http-device:","n":"temperature","u":"Cel","v":25.5}]'
```

## Troubleshooting

### Connection Refused

- Verify Magistrala is running on your x86/ARM machine: `docker ps` (should show multiple containers that are healthy)
- Check your computer's firewall settings
- Ensure MQTT port 1883 is accessible from the network

### Authentication Failed

- Verify CLIENT_KEY is the **client secret**, not the client ID
- Ensure the client is connected to the channel [Step 1.3, Part 6](#step-6-connect-client-to-channel)
- Check that the domain ID matches

### Messages Not Appearing

- Ensure subscriber and publisher use the **exact same topic**
- Verify both are using the same DOMAIN_ID and CHANNEL_ID
- Check Magistrala logs: `docker logs Magistrala-mqtt`

## Additional Resources

- [Magistrala Documentation](https://docs.Magistrala.absmach.eu/)
- [Magistrala CLI Reference](https://docs.Magistrala.absmach.eu/cli)
- [Clients Management](https://docs.Magistrala.absmach.eu/cli#clients-management)
- [Channels Management](https://docs.Magistrala.absmach.eu/cli#channels-management)
- [SenML Format Specification](https://tools.ietf.org/html/rfc8428)
