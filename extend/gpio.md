# Extend the BeagleBone with S0

## Identify the Available Interfaces Between BeagleBoard-V and Your HAT

```bash
beagle@BeagleV:~$ ls /dev/ttyS*
/dev/ttyS0  /dev/ttyS1  /dev/ttyS2  /dev/ttyS3  /dev/ttyS4  /dev/ttyS5  /dev/ttyS6  /dev/ttyS7

beagle@BeagleV:~$ ls /dev/ttyUSB*
ls: cannot access '/dev/ttyUSB*': No such file or directory

beagle@BeagleV:~$ ls /dev/ttyAMA*
ls: cannot access '/dev/ttyAMA*': No such file or directory

beagle@BeagleV:~$ ls /dev/spidev*
ls: cannot access '/dev/spidev*': No such file or directory

beagle@BeagleV:~$ ls /dev/i2c-*
/dev/i2c-0  /dev/i2c-1

beagle@BeagleV:~$ ls /dev/ttyUSB*
ls: cannot access '/dev/ttyUSB*': No such file or directory

beagle@BeagleV:~$ ls /dev/ttyACM*
ls: cannot access '/dev/ttyACM*': No such file or directory

beagle@BeagleV:~$ ls /sys/class/gpio/
export  gpiochip512  gpiochip526  gpiochip550  unexport

beagle@BeagleV:~$ ls /dev/gpiochip*
/dev/gpiochip0  /dev/gpiochip1  /dev/gpiochip2
```

## Download ESP32 AT Firmware

```bash
```

Compile and flash the ESP32 AT firmware to your ESP32 module. Use the following [link](https://docs.espressif.com/projects/esp-at/en/latest/esp32/Compile_and_Develop/How_to_clone_project_and_compile_it.html)


