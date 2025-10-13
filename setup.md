# Setup

## Hardware

The BeagleBone-V Fire is a development board for the BeagleBone family of ARM-based single-board computers.

Connect the BeagleBone-V Fire to your computer using a USB cable. The BeagleBone-V Fire is powered by a USB-C port on the board.

## Software

It comes with a Linux operating system pre-installed.

### Connecting to the BeagleBone-V Fire

Connect the BeagleBone-V Fire to your computer using minicom.

```bash
sudo minicom --device /dev/ttyACM0
```

`192.168.7.2`

Connect to the BeagleBone-V Fire using cockpit. `https://192.168.7.2:9090`

Connect to the BeagleBone-V Fire using ssh.

```bash
ssh beagle@192.168.7.2
```

### Flashing the BeagleBone-V Fire with [Debian Image](https://www.beagleboard.org/distros)

Username: `debian`

Password: `temppwd`

Change the password to something more secure after logging in `beagletemppwd`

### Flashing the BeagleBone-V Fire with [Ubuntu Image](https://www.beagleboard.org/distros)

Username: `debian`

Password: `temppwd`

Change the password to something more secure after logging in `beagletemppwd`

## Setup SuperMQ

We will use ansible to make it easier to setup the software.

Install [ansible](https://docs.ansible.com/).

Clone the repository.

```bash
git clone https://github.com/absmach/beagle-docs.git
```

Change directory to the repository.

```bash
cd beagle-docs
```

Edit the inventory file with the IP address of the BeagleBone-V Fire.

```bash
vim ansible/inventory/beaglebone-v-fire.yml
```

Run the playbook.

```bash
ansible-playbook -i ansible/inventory/beaglebone-v-fire.yml ansible/playbooks/setup.yml
```

Ansible will install the required packages and configure the firewall.

You can now connect to the BeagleBone-V Fire using ssh.

```bash
ssh beagle@192.168.7.2
```
