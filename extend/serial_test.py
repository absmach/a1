import time

import serial

ser = serial.Serial("/dev/ttyS1", 115200, timeout=1)

print("Serial port opened. Type messages (Ctrl+C to exit):")

try:
    while True:
        # Send data
        message = input("Send: ")
        ser.write((message + "\n").encode())

        # Read response
        time.sleep(0.1)
        if ser.in_waiting:
            response = ser.readline().decode("utf-8").strip()
            print(f"Received: {response}")
except KeyboardInterrupt:
    print("\nClosing...")
    ser.close()
