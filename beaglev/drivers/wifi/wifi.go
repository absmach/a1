// Package wifi provides an interface to control ESP32 WiFi bridge
// This is a reusable library that can be imported by other S1 components
package wifi

import (
	"bufio"
	"fmt"
	"strings"
	"time"

	"github.com/tarm/serial"
)

// Client represents an ESP32 WiFi bridge connection
type Client struct {
	port   *serial.Port
	reader *bufio.Reader
	config Config
}

// Config holds the ESP32 connection configuration
type Config struct {
	PortName    string
	BaudRate    int
	ReadTimeout time.Duration
}

// DefaultConfig returns the default configuration
func DefaultConfig() Config {
	return Config{
		PortName:    "/dev/ttyS0",
		BaudRate:    115200,
		ReadTimeout: time.Second,
	}
}

// Status represents WiFi connection status
type Status struct {
	Connected bool
	SSID      string
	IP        string
	RSSI      int
}

// Network represents a scanned WiFi network
type Network struct {
	SSID    string
	RSSI    int
	Secured bool
}

// NewClient creates a new WiFi client connection
func NewClient(config Config) (*Client, error) {
	serialConfig := &serial.Config{
		Name:        config.PortName,
		Baud:        config.BaudRate,
		ReadTimeout: config.ReadTimeout,
	}

	port, err := serial.OpenPort(serialConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to open port %s: %w", config.PortName, err)
	}

	client := &Client{
		port:   port,
		reader: bufio.NewReader(port),
		config: config,
	}

	// Wait for ESP32 to initialize
	time.Sleep(2 * time.Second)

	return client, nil
}

// Close closes the serial connection
func (c *Client) Close() error {
	if c.port != nil {
		return c.port.Close()
	}
	return nil
}

// SendCommand sends a command to the ESP32
func (c *Client) SendCommand(command string) error {
	_, err := c.port.Write([]byte(command + "\n"))
	if err != nil {
		return fmt.Errorf("failed to send command: %w", err)
	}
	time.Sleep(100 * time.Millisecond)
	return nil
}

// ReadLine reads a single line from ESP32
func (c *Client) ReadLine() (string, error) {
	line, err := c.reader.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(line), nil
}

// ReadLines reads multiple lines for a given duration
func (c *Client) ReadLines(timeout time.Duration) []string {
	var lines []string
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		line, err := c.ReadLine()
		if err != nil {
			continue
		}
		if line != "" {
			lines = append(lines, line)
		}
	}

	return lines
}

// Connect connects to a WiFi network
func (c *Client) Connect(ssid, password string) error {
	cmd := fmt.Sprintf("CONNECT:%s:%s", ssid, password)
	if err := c.SendCommand(cmd); err != nil {
		return err
	}

	// Wait for connection
	lines := c.ReadLines(5 * time.Second)

	// Check if connection succeeded
	for _, line := range lines {
		if strings.Contains(line, "OK:Connected") {
			return nil
		}
		if strings.Contains(line, "ERROR") {
			return fmt.Errorf("connection failed: %s", line)
		}
	}

	return fmt.Errorf("connection timeout")
}

// Disconnect disconnects from WiFi
func (c *Client) Disconnect() error {
	return c.SendCommand("DISCONNECT")
}

// GetStatus returns the current WiFi status
func (c *Client) GetStatus() (*Status, error) {
	if err := c.SendCommand("STATUS"); err != nil {
		return nil, err
	}

	lines := c.ReadLines(1 * time.Second)
	status := &Status{}

	for _, line := range lines {
		if strings.HasPrefix(line, "STATUS:") {
			status.Connected = strings.Contains(line, "CONNECTED")
		} else if strings.HasPrefix(line, "SSID:") {
			status.SSID = strings.TrimPrefix(line, "SSID:")
		} else if strings.HasPrefix(line, "IP:") {
			status.IP = strings.TrimPrefix(line, "IP:")
		} else if strings.HasPrefix(line, "RSSI:") {
			fmt.Sscanf(line, "RSSI:%d", &status.RSSI)
		}
	}

	return status, nil
}

// Scan scans for available WiFi networks
func (c *Client) Scan() ([]Network, error) {
	if err := c.SendCommand("SCAN"); err != nil {
		return nil, err
	}

	lines := c.ReadLines(5 * time.Second)
	var networks []Network

	for _, line := range lines {
		if strings.HasPrefix(line, "NETWORK:") {
			parts := strings.Split(strings.TrimPrefix(line, "NETWORK:"), ":")
			if len(parts) >= 3 {
				network := Network{
					SSID:    parts[0],
					Secured: parts[2] == "SECURED",
				}
				fmt.Sscanf(parts[1], "%d", &network.RSSI)
				networks = append(networks, network)
			}
		}
	}

	return networks, nil
}

// GetIP returns the current IP address
func (c *Client) GetIP() (string, error) {
	if err := c.SendCommand("IP"); err != nil {
		return "", err
	}

	lines := c.ReadLines(1 * time.Second)
	for _, line := range lines {
		if strings.HasPrefix(line, "IP:") {
			return strings.TrimPrefix(line, "IP:"), nil
		}
	}

	return "", fmt.Errorf("no IP address received")
}

// TCPConnect opens a TCP connection
func (c *Client) TCPConnect(host string, port int) error {
	cmd := fmt.Sprintf("TCPCONNECT:%s:%d", host, port)
	if err := c.SendCommand(cmd); err != nil {
		return err
	}

	lines := c.ReadLines(2 * time.Second)
	for _, line := range lines {
		if strings.Contains(line, "OK:TCP connected") {
			return nil
		}
		if strings.Contains(line, "ERROR") {
			return fmt.Errorf("TCP connection failed: %s", line)
		}
	}

	return fmt.Errorf("TCP connection timeout")
}

// TCPSend sends data over TCP
func (c *Client) TCPSend(data string) error {
	cmd := fmt.Sprintf("TCPSEND:%s", data)
	return c.SendCommand(cmd)
}

// TCPClose closes the TCP connection
func (c *Client) TCPClose() error {
	return c.SendCommand("TCPCLOSE")
}
