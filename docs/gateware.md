# Flashing Custom Gateware on BeagleV-Fire

Gateware refers to the digital logic configuration that defines how an FPGA behaves similar to how firmware defines the behavior of a microcontroller.

On the BeagleV-Fire, the gateware configures the FPGA fabric to enable hardware-level functionalities such as GPIO, UART, SPI, and custom logic extensions that work alongside the Linux-running RISC-V processor.

By customizing the gateware, you can tailor the BeagleV-Fire’s hardware capabilities for specific applications, such as enhanced I/O performance or specialized communication interfaces for the A1 Gateway.

To customize and flash the Beagle V Fire gateware, follow these steps:

- Fork the BeagleV-Fire gateware repository on [GitLab](https://git.beagleboard.org/beaglev-fire/gateware).

- Clone your fork:

  ```bash
  git clone <your-namespace>/my-gateware.git
  ```

- Create a build config YAML in `custom-fpga-design/` and set the `CAPE_OPTION` to your custom name.

- Copy and rename the cape Verilog template under `sources/FPGA-design/script_support/components/CAPE/`, modify the `HDL` folder with your custom .v files.

- Edit the device-tree overlay to reflect your custom gateware so it appears under `/proc/device-tree/chosen/overlays/`.

- Commit & push your changes into the forked repo.

- In GitLab CI, download the build artifact (bitstream) from the pipeline.

- Copy bitstream to the BeagleV-Fire:

  ```bash
  scp my_custom_bitstream.zip beagle@<BeagleIP>:/home/beagle/
  ```

- On the board:

  ```bash
  sudo /usr/share/beagleboard/gateware/change-gateware.sh ./my_custom_fpga_design
  ```

More information on Flashing Gateware, follow [Beagle V Fire Gateware Flashing](https://docs.beagle.cc/boards/beaglev/fire/demos-and-tutorials/gateware/customize-cape-gateware-verilog.html)
