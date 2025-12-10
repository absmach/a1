#include <WiFi.h>

/*
 * ESP32 WiFi Bridge for BeagleV
 * This makes your ESP32 act as a WiFi modem for BeagleV board
 *
 * Communication Protocol:
 * BeagleV sends commands via Serial, ESP32 responds
 *
 * Commands from BeagleV:
 * - CONNECT:SSID:PASSWORD    -> Connect to WiFi
 * - STATUS                   -> Get connection status
 * - SCAN                     -> Scan for networks
 * - DISCONNECT               -> Disconnect from WiFi
 * - TCPCONNECT:host:port     -> Open TCP connection
 * - TCPSEND:data             -> Send data over TCP
 * - TCPCLOSE                 -> Close TCP connection
 */

// Serial communication settings
#define SERIAL_BAUD 115200

// WiFi client for TCP connections
WiFiClient tcpClient;

// Buffer for incoming serial data
String serialBuffer = "";

void setup()
{
    // Initialize serial communication with BeagleV
    Serial.begin(SERIAL_BAUD);

    // Wait for serial to be ready
    delay(1000);

    // Set WiFi mode to station (client)
    WiFi.mode(WIFI_STA);

    // Send ready signal
    Serial.println("READY");
    Serial.println("ESP32 WiFi Bridge v1.0");
    Serial.println("Waiting for commands...");
}

void loop()
{
    // Check for incoming serial data from BeagleV
    while (Serial.available())
    {
        char c = Serial.read();

        if (c == '\n' || c == '\r')
        {
            // End of command, process it
            if (serialBuffer.length() > 0)
            {
                processCommand(serialBuffer);
                serialBuffer = "";
            }
        }
        else
        {
            serialBuffer += c;
        }
    }

    // Check for incoming TCP data
    if (tcpClient.connected() && tcpClient.available())
    {
        String data = "";
        while (tcpClient.available())
        {
            char c = tcpClient.read();
            data += c;
        }
        Serial.print("TCPDATA:");
        Serial.println(data);
    }

    // Small delay to prevent overwhelming the CPU
    delay(10);
}

void processCommand(String cmd)
{
    cmd.trim();

    // CONNECT command: CONNECT:SSID:PASSWORD
    if (cmd.startsWith("CONNECT:"))
    {
        int firstColon = cmd.indexOf(':', 8);
        if (firstColon > 0)
        {
            String ssid = cmd.substring(8, firstColon);
            String password = cmd.substring(firstColon + 1);
            connectToWiFi(ssid, password);
        }
        else
        {
            Serial.println("ERROR:Invalid CONNECT format. Use CONNECT:SSID:PASSWORD");
        }
    }

    // STATUS command
    else if (cmd == "STATUS")
    {
        getStatus();
    }

    // SCAN command
    else if (cmd == "SCAN")
    {
        scanNetworks();
    }

    // DISCONNECT command
    else if (cmd == "DISCONNECT")
    {
        WiFi.disconnect();
        Serial.println("OK:Disconnected");
    }

    // TCPCONNECT command: TCPCONNECT:host:port
    else if (cmd.startsWith("TCPCONNECT:"))
    {
        int colonPos = cmd.lastIndexOf(':');
        if (colonPos > 11)
        {
            String host = cmd.substring(11, colonPos);
            int port = cmd.substring(colonPos + 1).toInt();
            connectTCP(host, port);
        }
        else
        {
            Serial.println("ERROR:Invalid TCPCONNECT format");
        }
    }

    // TCPSEND command: TCPSEND:data
    else if (cmd.startsWith("TCPSEND:"))
    {
        String data = cmd.substring(8);
        sendTCP(data);
    }

    // TCPCLOSE command
    else if (cmd == "TCPCLOSE")
    {
        if (tcpClient.connected())
        {
            tcpClient.stop();
            Serial.println("OK:TCP connection closed");
        }
        else
        {
            Serial.println("ERROR:No active TCP connection");
        }
    }

    // IP command - get current IP address
    else if (cmd == "IP")
    {
        if (WiFi.status() == WL_CONNECTED)
        {
            Serial.print("IP:");
            Serial.println(WiFi.localIP().toString());
        }
        else
        {
            Serial.println("ERROR:Not connected to WiFi");
        }
    }

    // Unknown command
    else
    {
        Serial.print("ERROR:Unknown command: ");
        Serial.println(cmd);
    }
}

void connectToWiFi(String ssid, String password)
{
    Serial.print("CONNECTING:");
    Serial.println(ssid);

    WiFi.begin(ssid.c_str(), password.c_str());

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20)
    {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED)
    {
        Serial.println("OK:Connected");
        Serial.print("IP:");
        Serial.println(WiFi.localIP().toString());
    }
    else
    {
        Serial.println("ERROR:Connection failed");
    }
}

void getStatus()
{
    if (WiFi.status() == WL_CONNECTED)
    {
        Serial.println("STATUS:CONNECTED");
        Serial.print("SSID:");
        Serial.println(WiFi.SSID());
        Serial.print("IP:");
        Serial.println(WiFi.localIP().toString());
        Serial.print("RSSI:");
        Serial.print(WiFi.RSSI());
        Serial.println(" dBm");
    }
    else
    {
        Serial.println("STATUS:DISCONNECTED");
    }
}

void scanNetworks()
{
    Serial.println("SCANNING...");
    int n = WiFi.scanNetworks();

    if (n == 0)
    {
        Serial.println("SCAN:No networks found");
    }
    else
    {
        Serial.print("SCAN:Found ");
        Serial.print(n);
        Serial.println(" networks");

        for (int i = 0; i < n; i++)
        {
            Serial.print("NETWORK:");
            Serial.print(WiFi.SSID(i));
            Serial.print(":");
            Serial.print(WiFi.RSSI(i));
            Serial.print(":");
            Serial.println((WiFi.encryptionType(i) == WIFI_AUTH_OPEN) ? "OPEN" : "SECURED");
        }
    }
}

void connectTCP(String host, int port)
{
    Serial.print("TCP:Connecting to ");
    Serial.print(host);
    Serial.print(":");
    Serial.println(port);

    if (tcpClient.connect(host.c_str(), port))
    {
        Serial.println("OK:TCP connected");
    }
    else
    {
        Serial.println("ERROR:TCP connection failed");
    }
}

void sendTCP(String data)
{
    if (tcpClient.connected())
    {
        tcpClient.print(data);
        Serial.println("OK:Data sent");
    }
    else
    {
        Serial.println("ERROR:Not connected");
    }
}