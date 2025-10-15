# Connect to BeagleV Board as SuperMQ Client

This is a simple example of connecting to a BeagleV board as a SuperMQ client.

## Prerequisites

- A BeagleV board
- A SuperMQ server

## Start SuperMQ Server

```bash
git clone https://github.com/absmach/supermq.git
cd supermq
make run up args="-d"
```

## MQTT Client

```bash
sudo apt install mosquitto-clients
```

```bash
export SUPERMQ_HOST="192.168.100.129"
export DOMAIN_ID="56a4462e-5001-4bcf-b421-dbbe3d59c53c"
export CHANNEL_ID="0efb859c-f606-442d-9c9e-fd924cfee654"
export CLIENT_ID="bd2733d1-fcda-4974-bd7b-63b87a2e150f"
export CLIENT_KEY="6b648c99-d753-4ccb-9954-db6a504f0737"
```

```bash
mosquitto_sub -u $CLIENT_ID -P $CLIENT_KEY -t m/$DOMAIN_ID/c/$CHANNEL_ID -I supermq -h $SUPERMQ_HOST
```

```bash
mosquitto_pub -u $CLIENT_ID -P $CLIENT_KEY -t m/$DOMAIN_ID/c/$CHANNEL_ID -I supermq -h $SUPERMQ_HOST -m '[{"bn":"mqtt-device:","bu":"A","bver":5,"n":"voltage","u":"V","v":120.1}, {"n":"current","t":-2,"v":1.2}, {"n":"current","t":-1,"v":1.3}]'
```

### MQTTS

```bash
cd docker/ssl
make all
CN_SRV="192.168.100.129" CLIENT_SECRET=5f0a2e75-10a3-4b11-a82f-8bf2349385e8 make client_cert
```

```bash
scp ./docker/ssl/certs/ca.crt beagle@192.168.7.2:/home/beagle/ca.crt
scp ./docker/ssl/certs/client.crt beagle@192.168.7.2:/home/beagle/client.crt
scp ./docker/ssl/certs/client.key beagle@192.168.7.2:/home/beagle/client.key
```

```bash
mosquitto_sub -u $CLIENT_ID -P $CLIENT_KEY -t m/$DOMAIN_ID/c/$CHANNEL_ID -I supermq -h $SUPERMQ_HOST --cafile ca.crt --cert client.crt --key client.key -p 8883
```

```bash
mosquitto_pub -u $CLIENT_ID -P $CLIENT_KEY -t m/$DOMAIN_ID/c/$CHANNEL_ID -I supermq -h $SUPERMQ_HOST --cafile ca.crt --cert client.crt --key client.key -p 8883 -m '[{"bn":"mqtt-device:","bu":"A","bver":5,"n":"voltage","u":"V","v":120.1}, {"n":"current","t":-2,"v":1.2}, {"n":"current","t":-1,"v":1.3}]'
```

## CoAP Client

```bash
git clone https://github.com/absmach/coap-cli.git
cd coap-cli
make all
scp ./build/coap-cli-linux-riscv64 beagle@192.168.7.2:/home/beagle/coap-cli
```

```bash
export SUPERMQ_HOST="192.168.100.129"
export DOMAIN_ID="56a4462e-5001-4bcf-b421-dbbe3d59c53c"
export CHANNEL_ID="0efb859c-f606-442d-9c9e-fd924cfee654"
export CLIENT_ID="bd2733d1-fcda-4974-bd7b-63b87a2e150f"
export CLIENT_KEY="6b648c99-d753-4ccb-9954-db6a504f0737"
```

```bash
coap-cli get m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $SUPERMQ_HOST -o
```

```bash
coap-cli post m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $SUPERMQ_HOST -d '[{"bn":"coap-device:","bu":"A","bver":5,"n":"voltage","u":"V","v":120.1}, {"n":"current","t":-2,"v":1.2}, {"n":"current","t":-1,"v":1.3}]'
```

### CoAP DTLS

```bash
cd docker/ssl
make all
CN_SRV="192.168.100.129" CLIENT_SECRET=5f0a2e75-10a3-4b11-a82f-8bf2349385e8 make client_cert
```

```bash
scp ./docker/ssl/certs/ca.crt beagle@192.168.7.2:/home/beagle/ca.crt
scp ./docker/ssl/certs/coap-server.crt beagle@192.168.7.2:/home/beagle/coap-server.crt
scp ./docker/ssl/certs/coap-server.key beagle@192.168.7.2:/home/beagle/coap-server.key
```

```bash
coap-cli get m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $SUPERMQ_HOST -p 5683 -C coap-server.crt -K coap-server.key -A ca.crt -o
```

```bash
coap-cli post m/$DOMAIN_ID/c/$CHANNEL_ID -a $CLIENT_KEY -H $SUPERMQ_HOST -p 5683 -C coap-server.crt -K coap-server.key -A ca.crt -d '[{"bn":"coap-device:","bu":"A","bver":5,"n":"voltage","u":"V","v":120.1}, {"n":"current","t":-2,"v":1.2}, {"n":"current","t":-1,"v":1.3}]'
```

## HTTP Client

```bash
export SUPERMQ_HOST="192.168.100.129"
export DOMAIN_ID="56a4462e-5001-4bcf-b421-dbbe3d59c53c"
export CHANNEL_ID="0efb859c-f606-442d-9c9e-fd924cfee654"
export CLIENT_ID="bd2733d1-fcda-4974-bd7b-63b87a2e150f"
export CLIENT_KEY="6b648c99-d753-4ccb-9954-db6a504f0737"
```

```bash
curl -s -S -i -X POST -H "Content-Type: application/senml+json" -H "Authorization: Client $CLIENT_KEY" http://$SUPERMQ_HOST:8008/m/$DOMAIN_ID/c/$CHANNEL_ID -d '[{"bn":"http-device:","bu":"A","bver":5,"n":"voltage","u":"V","v":120.1}, {"n":"current","t":-2,"v":1.2}, {"n":"current","t":-1,"v":1.3}]'
```

### HTTPS

```bash
curl -s -S -i --cacert ca.crt --cert client.crt --key client.key -X POST -H "Authorization: Client $CLIENT_KEY" -H "Content-Type: application/senml+json" http://$SUPERMQ_HOST:8008/m/$DOMAIN_ID/c/$CHANNEL_ID -d '[{"bn":"http-device:","bu":"A","bver":5,"n":"voltage","u":"V","v":120.1}, {"n":"current","t":-2,"v":1.2}, {"n":"current","t":-1,"v":1.3}]'
```

## Go Client Example

```bash
GOARCH=riscv64 GOOS=linux go build -ldflags "-s -w" -o supermq-go-client main.go
scp ./supermq-go-client beagle@192.168.7.2:/home/beagle/supermq-go-client
```
