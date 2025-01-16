#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color (reset color)

# Check if curl is installed, and install it if it's missing
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Display the logo
curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/main/evenorlogo.sh | bash
 
# Menu
echo -e "${YELLOW}Choose an action:${NC}"
echo -e "${CYAN}1) Install ${NC}"
echo -e "${CYAN}2) Update ${NC}"
echo -e "${CYAN}3) Set fee${NC}"
echo -e "${CYAN}4) Remove node${NC}"
echo -e "${CYAN}5) Check logs (exit logs with CTRL+C)${NC}"

echo -e "${YELLOW}Enter a number:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Installing Hemi node...${NC}"

        # Update and install required packages
        sudo apt update && sudo apt upgrade -y
        sleep 1

        # Check if tar is installed, and install it if it's missing
        if ! command -v tar &> /dev/null; then
            sudo apt install tar -y
        fi

        # Download the binary
        echo -e "${BLUE}Downloading Hemi binary...${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.10.0/heminetwork_v0.10.0_linux_amd64.tar.gz

        # Create a directory and extract the binary
        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.10.0_linux_amd64.tar.gz -C hemi
        cd hemi

        # Create a tBTC wallet
        ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

        # Display the contents of the popm-address.json file
        echo -e "${RED}Save this data in a secure place:${NC}"
        cat ~/popm-address.json
        echo -e "${PURPLE}Your pubkey_hash is your tBTC address. Use it to request test tokens in the project's Discord.${NC}"

        echo -e "${YELLOW}Enter your wallet private key:${NC} "
        read PRIV_KEY
        echo -e "${YELLOW}Enter the desired fee size (minimum 50):${NC} "
        read FEE

        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env
        sleep 1

        # Determine the current user's name and their home directory
USERNAME=$(whoami)

if [ "$USERNAME" == "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$USERNAME"
fi

# Create or update the service file using the determined username and home directory
cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

        # Update services and enable hemi
        sudo systemctl daemon-reload
        sudo systemctl enable hemi
        sleep 1

        # Start the node
        sudo systemctl start hemi

        # Final output
        echo -e "${GREEN}Installation completed and node is running!${NC}"

        # Concluding output
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}" 
        echo "sudo journalctl -u hemi -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Evenor.eth - your crypto guide${NC}${NC}"
        echo -e "${CYAN}Author's tg - https://t.me/threedotcrypto"
        ;;
    2)
        echo -e "${BLUE}Updating Hemi node...${NC}"

        # Find all screen sessions containing "hemi"
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        # If sessions are found, terminate them
        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Closing screen sessions with IDs: $SESSION_IDS${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}No screen sessions for the Hemi node found, starting update${NC}"
        fi

        # Check if the service exists
        if systemctl list-units --type=service | grep -q "hemi.service"; then
            sudo systemctl stop hemi.service
            sudo systemctl disable hemi.service
            sudo rm /etc/systemd/system/hemi.service
            sudo systemctl daemon-reload
        else
            echo -e "${BLUE}The hemi.service was not found, continuing with the update.${NC}"
        fi
        sleep 1

        # Remove the folder containing binaries with "hemi" in the name
        echo -e "${BLUE}Removing old node files...${NC}"
        rm -rf *hemi*
        
        # Update and install required packages
        sudo apt update && sudo apt upgrade -y

        # Download the binary
        echo -e "${BLUE}Downloading Hemi binary...${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.10.0/heminetwork_v0.10.0_linux_amd64.tar.gz

        # Create a directory and extract the binary
        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.10.0_linux_amd64.tar.gz -C hemi
        cd hemi

        # Request private key and fee
        echo -e "${YELLOW}Enter your wallet private key:${NC} "
        read PRIV_KEY
        echo -e "${YELLOW}Enter the desired fee size (minimum 50):${NC} "
        read FEE

        # Create the popmd.env file
        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env
        sleep 1

        # Determine the current user's name and their home directory
USERNAME=$(whoami)

if [ "$USERNAME" == "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$USERNAME"
fi

# Create or update the service file using the determined username and home directory
cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

        # Update services and enable hemi
        sudo systemctl daemon-reload
        sudo systemctl enable hemi
        sleep 1

        # Start the node
        sudo systemctl start hemi

        # Final output
        echo -e "${GREEN}Node updated and running!${NC}"

        # Concluding output
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}" 
        echo "sudo journalctl -u hemi -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Evenor.eth - your crypto guide!${NC}"
        echo -e "${CYAN}Author's tg - https://t.me/threedotcrypto"
        ;;
    3)
        echo -e "${YELLOW}Enter a new fee value (minimum 50):${NC}"
        read NEW_FEE

        # Check that the entered value is not less than 50
        if [ "$NEW_FEE" -ge 50 ]; then
            # Update the fee value in the popmd.env file
            sed -i "s/^POPM_STATIC_FEE=.*/POPM_STATIC_FEE=$NEW_FEE/" $HOME/hemi/popmd.env
            sleep 1

            # Restart the Hemi service
            sudo systemctl restart hemi

            echo -e "${GREEN}Fee value successfully updated!${NC}"

            # Concluding output
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Command to check logs:${NC}" 
            echo "sudo journalctl -u hemi -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}Evenor.eth - your crypto guide!${NC}"
            echo -e "${CYAN}Author's tg - https://t.me/threedotcrypto"
        else
            echo -e "${RED}Error: Fee must be at least 50!${NC}"
        fi
        ;;

    4)
        echo -e "${BLUE}Removing Hemi node...${NC}"

        # Find all screen sessions containing "hemi"
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        # If sessions are found, terminate them
        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Closing screen sessions with IDs: $SESSION_IDS${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}No screen sessions for the Hemi node found, continuing removal${NC}"
        fi

        # Stop and remove the Hemi service
        sudo systemctl stop hemi.service
        sudo systemctl disable hemi.service
        sudo rm /etc/systemd/system/hemi.service
        sudo systemctl daemon-reload
        sleep 1

        # Remove the folder containing files named "hemi"
        echo -e "${BLUE}Removing Hemi node files...${NC}"
        rm -rf *hemi*
        
        echo -e "${GREEN}Hemi node successfully removed!${NC}"

        # Concluding output
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}" 
        echo "sudo journalctl -u hemi -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Evenor.eth - your crypto guide${NC}"
        echo -e "${CYAN}Author's tg - https://t.me/threedotcrypto"
        ;;
    5)
        sudo journalctl -u hemi -f
        ;;
        
esac
