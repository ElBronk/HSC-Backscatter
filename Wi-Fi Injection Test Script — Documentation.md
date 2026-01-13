# Wi-Fi Injection Test Script — Documentation

This script automates enabling monitor mode and forcing operation in **802.11b** rates on an external Wi-Fi adapter. It uses the Wi-Fi frame-injection tools from the GitHub repository **wifi-injection** (https://github.com/vanhoefm/wifi-injection).  
When configured properly, this setup allows your device to act as the transmitter for **Colleen Josephine’s Backcam module**.

---

## Requirements

Before running the scripts, ensure the following are installed:

- **wifi-injection** repository
- All dependencies listed in wifi-injection documentation
- `aircrack-ng`
- `iw`
- External Wi-Fi adapter (we use the TL-WN722N revision 2)

---

## Setup Instructions

### **Step 1 — Clone the wifi-injection repository**

Clone the repository and install its required dependencies:

```bash
git clone https://github.com/vanhoefm/wifi-injection
```

Follow all setup instructions listed on the repository page (virtual environment, Python requirements, etc.).

### **Step 2 — Install required system tools**

Install aircrack-ng and iw using your preferred package manager.

**Debian/Ubuntu**
```bash
sudo apt install aircrack-ng iw
```

**Arch Linux**
```bash
sudo pacman -S aircrack-ng iw
```

**Fedora**
```bash
sudo dnf install aircrack-ng iw
```

### **Step 3 — Identify your external Wi-Fi adapter**

Plug in your external adapter and run:
```bash
iw dev
```

Look for an interface under the Interface field.

Example from my system:
```
Interface wlxc025e92d5b09
```

Your name will differ. Use your interface name in the script.

### **Step 4 — Run the initialize.sh script**

In the same directory as the cloned repository, run:
```bash
./initialize.sh
```

This script performs the following tasks:
- Kills conflicting network processes
- Puts your external Wi-Fi adapter into monitor mode
- Forces the card to 802.11b mode

After running this script, your adapter is prepared to act as the transmitter for Backcam.

### **Step 5 — Begin transmission using Backcam**

The initialize script ensures the Wi-Fi adapter is properly configured for transmitting frames compatible with Backcam's backend.

You can now transmit using Backcam over a degraded 802.11b injection-capable card.

### **Step 6 — Restore normal Wi-Fi functionality**

When you are done transmitting, run:
```bash
./stopservice.sh
```

This script will:
- Disable monitor mode
- Restore managed Wi-Fi mode
- Restart any network services that were stopped
- Re-enable normal wireless connectivity

### **Additional Notes**

- Always confirm your interface name before running either script.
- These scripts must be run from within the same directory as the cloned repository so the venv environment and test-injection.py file can be used correctly.
- Some distributions may require a manual restart of NetworkManager after stopping services.