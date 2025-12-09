// Copyright (c) Abstract Machines
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strings"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/plgd-dev/go-coap/v3/message"
	"github.com/plgd-dev/go-coap/v3/message/codes"
	"github.com/plgd-dev/go-coap/v3/udp"
	"github.com/plgd-dev/go-coap/v3/udp/client"
)

type SenMLRecord struct {
	BaseName    string  `json:"bn,omitempty"`
	BaseUnit    string  `json:"bu,omitempty"`
	BaseVersion int     `json:"bver,omitempty"`
	Name        string  `json:"n"`
	Unit        string  `json:"u,omitempty"`
	Value       float64 `json:"v"`
	Time        float64 `json:"t,omitempty"`
}

type Config struct {
	Host      string
	DomainID  string
	ChannelID string
	ClientID  string
	ClientKey string
}

func generateSensorData(devicePrefix string) []SenMLRecord {
	return []SenMLRecord{
		{
			BaseName:    devicePrefix + ":",
			BaseUnit:    "A",
			BaseVersion: rand.Intn(10),
			Name:        "voltage",
			Unit:        "V",
			Value:       rand.Float64() * 100,
		},
		{
			Name:  "current",
			Time:  -2,
			Value: rand.Float64() * 10,
		},
		{
			Name:  "current",
			Time:  -1,
			Value: rand.Float64() * 10,
		},
	}
}

func publishHTTP(cfg Config, data []SenMLRecord) error {
	url := fmt.Sprintf("http://%s:8008/m/%s/c/%s", cfg.Host, cfg.DomainID, cfg.ChannelID)

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal data: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/senml+json")
	req.Header.Set("Authorization", "Client "+cfg.ClientKey)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	log.Printf("HTTP: Published successfully (status: %d)", resp.StatusCode)
	return nil
}

func publishMQTT(cfg Config, data []SenMLRecord) error {
	topic := fmt.Sprintf("m/%s/c/%s", cfg.DomainID, cfg.ChannelID)

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal data: %w", err)
	}

	opts := mqtt.NewClientOptions()
	opts.AddBroker(fmt.Sprintf("tcp://%s:1883", cfg.Host))
	opts.SetClientID("supermq-go-client")
	opts.SetUsername(cfg.ClientID)
	opts.SetPassword(cfg.ClientKey)
	opts.SetConnectionLostHandler(func(c mqtt.Client, err error) {
		log.Printf("MQTT: Connection lost: %v", err)
	})

	client := mqtt.NewClient(opts)
	token := client.Connect()
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("failed to connect: %w", token.Error())
	}
	defer client.Disconnect(250)

	pubToken := client.Publish(topic, 0, false, jsonData)
	if pubToken.Wait() && pubToken.Error() != nil {
		return fmt.Errorf("failed to publish: %w", pubToken.Error())
	}

	log.Println("MQTT: Published successfully")
	return nil
}

type CoAPClient struct {
	conn *client.Conn
}

func NewCoAPClient(addr string) (*CoAPClient, error) {
	conn, err := udp.Dial(addr)
	if err != nil {
		return nil, fmt.Errorf("failed to dial: %w", err)
	}
	return &CoAPClient{conn: conn}, nil
}

func (c *CoAPClient) Post(ctx context.Context, path string, contentFormat message.MediaType, payload io.ReadSeeker, opts ...message.Option) error {
	resp, err := c.conn.Post(ctx, path, contentFormat, payload, opts...)
	if err != nil {
		return fmt.Errorf("failed to send POST: %w", err)
	}

	if resp.Code() != codes.Changed && resp.Code() != codes.Created && resp.Code() != codes.Valid {
		body, _ := resp.ReadBody()
		return fmt.Errorf("unexpected response code: %v, body: %s", resp.Code(), string(body))
	}

	return nil
}

func (c *CoAPClient) Close() error {
	return c.conn.Close()
}

func publishCoAP(cfg Config, data []SenMLRecord) error {
	path := fmt.Sprintf("m/%s/c/%s", cfg.DomainID, cfg.ChannelID)
	addr := fmt.Sprintf("%s:5683", cfg.Host)

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal data: %w", err)
	}

	client, err := NewCoAPClient(addr)
	if err != nil {
		return fmt.Errorf("failed to create CoAP client: %w", err)
	}
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	opts := make(message.Options, 0)
	opts = append(opts, message.Option{
		ID:    message.URIQuery,
		Value: []byte("auth=" + cfg.ClientKey),
	})

	payload := strings.NewReader(string(jsonData))

	if err := client.Post(ctx, path, message.AppJSON, payload, opts...); err != nil {
		return fmt.Errorf("failed to publish: %w", err)
	}

	log.Println("CoAP: Published successfully")
	return nil
}

func main() {
	log.Println("Starting SuperMQ Multi-Protocol Publisher...")

	cfg := Config{
		Host:      os.Getenv("SUPERMQ_HOST"),
		DomainID:  os.Getenv("DOMAIN_ID"),
		ChannelID: os.Getenv("CHANNEL_ID"),
		ClientID:  os.Getenv("CLIENT_ID"),
		ClientKey: os.Getenv("CLIENT_KEY"),
	}
	if cfg.Host == "" || cfg.DomainID == "" || cfg.ChannelID == "" || cfg.ClientID == "" || cfg.ClientKey == "" {
		log.Fatal("Missing configuration")
	}

	log.Printf("Configuration loaded - Host: %s, Domain: %s", cfg.Host, cfg.DomainID)

	log.Println("\n--- Publishing via HTTP ---")
	httpData := generateSensorData("http-device")
	if err := publishHTTP(cfg, httpData); err != nil {
		log.Printf("HTTP Error: %v", err)
	}

	time.Sleep(time.Second)

	log.Println("\n--- Publishing via MQTT ---")
	mqttData := generateSensorData("mqtt-device")
	if err := publishMQTT(cfg, mqttData); err != nil {
		log.Printf("MQTT Error: %v", err)
	}

	time.Sleep(time.Second)

	log.Println("\n--- Publishing via CoAP ---")
	coapData := generateSensorData("coap-device")
	if err := publishCoAP(cfg, coapData); err != nil {
		log.Printf("CoAP Error: %v", err)
	}

	log.Println("\nAll publishing attempts completed!")
}
