// Example: How to use the WiFi library in your S1 application
package main

import (
	"fmt"
	"log"
	"time"

	"s1/beaglev/drivers/wifi"
)

func main() {
	// Example 1: Simple WiFi connection
	simpleConnect()

	// Example 2: Network scanning and auto-connect
	// autoConnect()

	// Example 3: Using WiFi in a service
	// runAsService()
}

// Example 1: Simple connection
func simpleConnect() {
	fmt.Println("=== Example 1: Simple WiFi Connection ===")

	// Create WiFi client with default config
	config := wifi.DefaultConfig()
	client, err := wifi.NewClient(config)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	// Connect to WiFi
	err = client.Connect("YourSSID", "YourPassword")
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}

	// Get IP address
	ip, err := client.GetIP()
	if err != nil {
		log.Fatalf("Failed to get IP: %v", err)
	}

	fmt.Printf("Connected! IP: %s\n", ip)
}

// Example 2: Scan and auto-connect to strongest network
func autoConnect() {
	fmt.Println("=== Example 2: Auto-Connect to Strongest Network ===")

	config := wifi.DefaultConfig()
	client, err := wifi.NewClient(config)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	// Scan for networks
	networks, err := client.Scan()
	if err != nil {
		log.Fatalf("Failed to scan: %v", err)
	}

	// Find strongest known network
	knownNetworks := map[string]string{
		"HomeWiFi":   "password1",
		"OfficeWiFi": "password2",
	}

	var bestNetwork *wifi.Network
	var bestPassword string

	for _, network := range networks {
		if password, ok := knownNetworks[network.SSID]; ok {
			if bestNetwork == nil || network.RSSI > bestNetwork.RSSI {
				bestNetwork = &network
				bestPassword = password
			}
		}
	}

	if bestNetwork != nil {
		fmt.Printf("Connecting to %s (signal: %d dBm)...\n",
			bestNetwork.SSID, bestNetwork.RSSI)

		err = client.Connect(bestNetwork.SSID, bestPassword)
		if err != nil {
			log.Fatalf("Failed to connect: %v", err)
		}

		fmt.Println("Connected successfully!")
	} else {
		fmt.Println("No known networks found")
	}
}

// Example 3: Running as a background service
func runAsService() {
	fmt.Println("=== Example 3: WiFi Service ===")

	config := wifi.DefaultConfig()
	client, err := wifi.NewClient(config)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	// Connect to WiFi
	err = client.Connect("YourSSID", "YourPassword")
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}

	fmt.Println("WiFi service started. Monitoring connection...")

	// Monitor connection every 30 seconds
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			status, err := client.GetStatus()
			if err != nil {
				log.Printf("Error checking status: %v", err)
				continue
			}

			if !status.Connected {
				log.Println("Connection lost! Attempting to reconnect...")
				err = client.Connect("YourSSID", "YourPassword")
				if err != nil {
					log.Printf("Reconnection failed: %v", err)
				} else {
					log.Println("Reconnected successfully")
				}
			} else {
				log.Printf("Connected: %s, IP: %s, Signal: %d dBm",
					status.SSID, status.IP, status.RSSI)
			}
		}
	}
}

// Example 4: HTTP request over WiFi
func httpRequest() {
	fmt.Println("=== Example 4: HTTP Request ===")

	config := wifi.DefaultConfig()
	client, err := wifi.NewClient(config)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	// Ensure connected
	status, _ := client.GetStatus()
	if !status.Connected {
		client.Connect("YourSSID", "YourPassword")
	}

	// Make HTTP request
	err = client.TCPConnect("api.example.com", 80)
	if err != nil {
		log.Fatalf("TCP connection failed: %v", err)
	}

	request := "GET /data HTTP/1.1\\r\\nHost: api.example.com\\r\\n\\r\\n"
	err = client.TCPSend(request)
	if err != nil {
		log.Fatalf("Failed to send request: %v", err)
	}

	fmt.Println("HTTP request sent!")

	// In real app, you'd read the response here
	time.Sleep(2 * time.Second)
	client.TCPClose()
}
