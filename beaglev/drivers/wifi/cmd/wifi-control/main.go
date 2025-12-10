// WiFi Control CLI - Command line interface for ESP32 WiFi bridge
// This is part of the S1 project driver tools
package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"

	"s1/beaglev/drivers/wifi"
)

func main() {
	fmt.Println(strings.Repeat("=", 50))
	fmt.Println("S1 Project - ESP32 WiFi Control")
	fmt.Println(strings.Repeat("=", 50))

	// Get configuration
	config := wifi.DefaultConfig()
	if len(os.Args) > 1 {
		config.PortName = os.Args[1]
		fmt.Printf("Using port: %s\n", config.PortName)
	} else {
		fmt.Printf("Using default port: %s\n", config.PortName)
	}

	// Connect to ESP32
	client, err := wifi.NewClient(config)
	if err != nil {
		log.Fatalf("Failed to connect: %v\n", err)
	}
	defer client.Close()

	fmt.Println("Connected to ESP32 WiFi Bridge")

	// Main interactive loop
	for {
		choice := showMenu()

		switch choice {
		case 1:
			scanNetworks(client)
		case 2:
			connectToWiFi(client)
		case 3:
			getStatus(client)
		case 4:
			getIP(client)
		case 5:
			disconnect(client)
		case 6:
			tcpTest(client)
		case 7:
			fmt.Println("\nExiting...")
			return
		default:
			fmt.Println("Invalid choice!")
		}
	}
}

func showMenu() int {
	fmt.Println("\n" + strings.Repeat("=", 50))
	fmt.Println("Commands:")
	fmt.Println("  1. Scan networks")
	fmt.Println("  2. Connect to WiFi")
	fmt.Println("  3. Get status")
	fmt.Println("  4. Get IP address")
	fmt.Println("  5. Disconnect")
	fmt.Println("  6. TCP test")
	fmt.Println("  7. Exit")
	fmt.Println(strings.Repeat("=", 50))
	fmt.Print("\nEnter choice (1-7): ")

	var choice int
	fmt.Scanln(&choice)
	return choice
}

func getInput(prompt string) string {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print(prompt)
	input, _ := reader.ReadString('\n')
	return strings.TrimSpace(input)
}

func scanNetworks(client *wifi.Client) {
	fmt.Println("\nScanning for networks...")
	networks, err := client.Scan()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("\nFound %d networks:\n", len(networks))
	for i, network := range networks {
		security := "Open"
		if network.Secured {
			security = "Secured"
		}
		fmt.Printf("%d. %s (%d dBm) - %s\n", i+1, network.SSID, network.RSSI, security)
	}
}

func connectToWiFi(client *wifi.Client) {
	ssid := getInput("Enter WiFi SSID: ")
	password := getInput("Enter password: ")

	fmt.Printf("\nConnecting to %s...\n", ssid)
	if err := client.Connect(ssid, password); err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Println("Connected successfully!")
	getStatus(client)
}

func getStatus(client *wifi.Client) {
	fmt.Println("\nGetting status...")
	status, err := client.GetStatus()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	if status.Connected {
		fmt.Printf("\nStatus: Connected\n")
		fmt.Printf("SSID: %s\n", status.SSID)
		fmt.Printf("IP: %s\n", status.IP)
		fmt.Printf("Signal: %d dBm\n", status.RSSI)
	} else {
		fmt.Println("\nStatus: Disconnected")
	}
}

func getIP(client *wifi.Client) {
	fmt.Println("\nGetting IP address...")
	ip, err := client.GetIP()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	fmt.Printf("IP Address: %s\n", ip)
}

func disconnect(client *wifi.Client) {
	fmt.Println("\nDisconnecting...")
	if err := client.Disconnect(); err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	fmt.Println("Disconnected")
}

func tcpTest(client *wifi.Client) {
	fmt.Println("\nTesting TCP connection to example.com:80...")

	if err := client.TCPConnect("example.com", 80); err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	fmt.Println("Connected!")

	fmt.Println("Sending HTTP request...")
	if err := client.TCPSend("GET / HTTP/1.1\\r\\nHost: example.com\\r\\n\\r\\n"); err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Println("Request sent. Closing connection...")
	client.TCPClose()
	fmt.Println("Test complete")
}
