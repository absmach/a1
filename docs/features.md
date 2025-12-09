# 🌟 **Features**

## 🔧 **Hardware Architecture**

In the S1 IoT Gateway architecture:

🧠 BeagleV-Fire acts as the central controller, running Linux to manage device coordination, networking, and cloud communication.

🔄 It receives metering data from the S0 (ESP32-C6) over UART or another serial interface.

☁️ Processes, aggregates, and forwards data securely to SuperMQ via MQTT, MQTTS, HTTP, HTTPS, CoAP and CoAP DTLS.

🔐 Handles system-level services such as security, data persistence, logging, and firmware updates.

🔌 Can run Docker containers or system daemons to enable flexible and modular gateway functionality.

## ⚙️ **BeagleV-Fire Features**

The BeagleV-Fire is a powerful, open-source RISC-V single-board computer developed by BeagleBoard.org. It is designed for embedded Linux, FPGA acceleration, and edge computing applications.

Below are key features that make it ideal as the main controller in the S1 IoT Gateway:

🧩 **Beagle-V Fire Specifications**

**Processor:**

- Microchip PolarFire SoC

- 5x RV64GC RISC-V cores running at up to 667 MHz

- 1x FPGA fabric for hardware acceleration or custom peripheral logic

**Memory and Storage:**

- Up to 2 GB LPDDR4 RAM

- 16 GB eMMC onboard storage (depending on configuration)

- microSD card slot for additional storage

**Connectivity:**

- Gigabit Ethernet port

- USB 3.0 and USB 2.0 ports

- UART, SPI, I²C, and GPIO interfaces for peripheral communication

- M.2 E-key slot for wireless modules (e.g., Wi-Fi or Bluetooth adapters)

**FPGA Integration:**

- Built-in PolarFire FPGA fabric allows hardware-level customization — ideal for timing-critical or communication-intensive applications.

**Video and Display (Optional):**

- HDMI output support (on compatible models)

## ⚙️ **S0 Features**

The S0 provides support for the following communication interfaces:

- 📶 **Wireless M-Bus (868 MHz)** via the **RC-S2LP module**
- 🌐 **NB-IoT / LTE-M** via the **SIM7080G** module for cellular connectivity
- 🌍 **Internet connectivity** via ESP32C6 WiFi capabilities and Ethernet via Beagle-V Fire

The custom PCB for S0 integrates multiple communication modules and power interfaces designed for industrial deployment:

| Component         | Description                              |
| ----------------- | ---------------------------------------- |
| ESP32-C6          | Microcontroller (RISC-V, WiFi, BLE)      |
| RC-S2LP           | Wireless M-Bus 868 MHz transceiver       |
| SIM7080G          | NB-IoT/LTE-M module                      |
| USB-C & Terminals | For power and debug                      |
| GNSS Support      | Optional via SIM7080G for asset tracking |

The S0 board serves as an extender, by adding these functionalities to the Beagle-V Fire
