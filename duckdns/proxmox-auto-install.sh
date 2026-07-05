#!/usr/bin/env bash

# Script de instalación automática de DuckDNS en Proxmox
# Se ejecuta desde el host Proxmox y crea todo automáticamente
# Automatic DuckDNS installer for Proxmox - Creates LXC container automatically

# Silenciar warnings de locale
export LC_ALL=C
export LANG=C

# Colores / Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════
# SELECCIÓN DE IDIOMA / LANGUAGE SELECTION
# ═══════════════════════════════════════════════════════════════

clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   🦆  DUCKDNS INSTALLER FOR PROXMOX  🦆                       ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${WHITE}Select language / Selecciona idioma:${NC}"
echo ""
echo -e "   ${CYAN}1)${NC} English"
echo -e "   ${CYAN}2)${NC} Español"
echo ""
echo -ne "   ${GREEN}▶${NC} Option / Opción ${CYAN}[1]${NC}: "
read LANG_CHOICE
LANG_CHOICE=${LANG_CHOICE:-1}

if [[ "$LANG_CHOICE" == "2" ]]; then
    LANG="es"
else
    LANG="en"
fi

# ═══════════════════════════════════════════════════════════════
# TEXTOS EN AMBOS IDIOMAS / TEXTS IN BOTH LANGUAGES
# ═══════════════════════════════════════════════════════════════

if [[ "$LANG" == "es" ]]; then
    # Español
    TXT_HEADER_TITLE="INSTALADOR AUTOMÁTICO DUCKDNS PARA PROXMOX"
    TXT_HEADER_DESC="Crea un contenedor LXC y configura DuckDNS automáticamente"
    TXT_PROXMOX_OK="Proxmox VE detectado correctamente"
    TXT_PROXMOX_ERROR="Este script debe ejecutarse en un servidor Proxmox VE"
    TXT_PROXMOX_HINT="Usa este comando desde el host Proxmox, no desde un contenedor"
    TXT_STEP1="PASO 1/4: Configuración de DuckDNS"
    TXT_STEP2="PASO 2/4: Configuración del Contenedor"
    TXT_STEP3="PASO 3/4: Almacenamiento y Red"
    TXT_STEP4="PASO 4/4: Confirmar Instalación"
    TXT_NEED_TOKEN="Necesitas tu token y subdominio de DuckDNS."
    TXT_REGISTER="Si no los tienes, regístrate en:"
    TXT_TOKEN="Token de DuckDNS"
    TXT_SUBDOMAIN="Subdominio (sin .duckdns.org)"
    TXT_NEXT_ID="El siguiente ID disponible es:"
    TXT_CONTAINER_ID="ID del contenedor"
    TXT_CONTAINER_NAME="Nombre del contenedor"
    TXT_ROOT_PASSWORD="Contraseña root"
    TXT_PASSWORD_SHORT="La contraseña debe tener al menos 5 caracteres"
    TXT_ID_EXISTS="El contenedor ID ya existe"
    TXT_CHOOSE_OTHER="Elige otro ID"
    TXT_STORAGE_AVAILABLE="Almacenamientos disponibles:"
    TXT_STORAGE="Almacenamiento para el contenedor"
    TXT_BRIDGES="Bridges de red disponibles:"
    TXT_BRIDGE="Bridge de red"
    TXT_CONFIRM_CONFIG="Se creará el contenedor con esta configuración:"
    TXT_DOMAIN="Dominio"
    TXT_CONTAINER="Contenedor"
    TXT_MEMORY="Memoria"
    TXT_DISK="Disco"
    TXT_INFRASTRUCTURE="Infraestructura"
    TXT_CONTINUE="¿Continuar con la instalación?"
    TXT_CANCELLED="Instalación cancelada"
    TXT_STARTING="Iniciando instalación..."
    TXT_PROGRESS="INSTALACIÓN EN PROGRESO"
    TXT_TEMPLATES="Templates disponibles:"
    TXT_STEP_TEMPLATES="Paso 1/8: Buscando templates disponibles..."
    TXT_STEP_CREATE="Paso 2/8: Creando contenedor LXC..."
    TXT_STEP_WAIT="Paso 3/8: Esperando a que el contenedor esté listo..."
    TXT_STEP_UPDATE="Paso 4/8: Actualizando sistema en el contenedor..."
    TXT_STEP_DEPS="Paso 5/8: Instalando dependencias..."
    TXT_STEP_DUCK="Paso 6/8: Configurando DuckDNS..."
    TXT_STEP_AUTO="Paso 7/8: Configurando autologin para la consola..."
    TXT_STEP_RESTART="Paso 8/8: Reiniciando contenedor para aplicar configuración..."
    TXT_USING_UBUNTU="Usando template de Ubuntu 22.04:"
    TXT_USING_DEBIAN="Usando template de Debian:"
    TXT_DEBIAN_NOTE="Nota: Se está usando Debian porque Ubuntu 22.04 no está disponible"
    TXT_USING_OTHER="Usando template disponible:"
    TXT_OTHER_NOTE="Nota: Se está usando el template más reciente disponible"
    TXT_DOWNLOADING="No se encontraron templates. Descargando Ubuntu 22.04..."
    TXT_DOWNLOADED="Template descargado:"
    TXT_TEMPLATE_FOUND="Template encontrado:"
    TXT_CREATED="Contenedor creado exitosamente"
    TXT_CREATE_FAILED="Error al crear el contenedor. Verifica los parámetros."
    TXT_STARTING_CONTAINER="Iniciando contenedor..."
    TXT_CRON="Configurando cron para actualización automática..."
    TXT_FIRST_UPDATE="Probando primera actualización..."
    TXT_UPDATE_OK="Primera actualización exitosa:"
    TXT_UPDATE_ERR="Posible error en la actualización:"
    TXT_CLEANING="Limpiando sistema..."
    TXT_COMPLETE="¡INSTALACIÓN COMPLETADA EXITOSAMENTE!"
    TXT_SUMMARY="RESUMEN DE LA INSTALACIÓN"
    TXT_FEATURES="Características"
    TXT_AUTOBOOT="Autoboot habilitado"
    TXT_AUTOLOGIN="Autologin en consola"
    TXT_CRON_5MIN="Cron cada 5 minutos"
    TXT_WELCOME="Pantalla de bienvenida"
    TXT_USEFUL_CMD="COMANDOS ÚTILES"
    TXT_ACCESS_CONTAINER="Acceder al contenedor (sin contraseña)"
    TXT_VIEW_INFO="Ver información de DuckDNS"
    TXT_CONTROL="Control del contenedor"
    TXT_VERIFY="VERIFICAR FUNCIONAMIENTO"
    TXT_VERIFY_DNS="Verificar resolución DNS"
    TXT_YOUR_IP="Tu IP pública actual"
    TXT_AUTOLOGIN_TIP="Si el autologin no funciona:"
    TXT_FOOTER="Desarrollado en Puerto Rico con cafe para la comunidad Proxmox"
    TXT_REQUIRED="Este campo es obligatorio"
else
    # English
    TXT_HEADER_TITLE="AUTOMATIC DUCKDNS INSTALLER FOR PROXMOX"
    TXT_HEADER_DESC="Creates an LXC container and configures DuckDNS automatically"
    TXT_PROXMOX_OK="Proxmox VE detected successfully"
    TXT_PROXMOX_ERROR="This script must be run on a Proxmox VE server"
    TXT_PROXMOX_HINT="Run this command from the Proxmox host, not from a container"
    TXT_STEP1="STEP 1/4: DuckDNS Configuration"
    TXT_STEP2="STEP 2/4: Container Configuration"
    TXT_STEP3="STEP 3/4: Storage and Network"
    TXT_STEP4="STEP 4/4: Confirm Installation"
    TXT_NEED_TOKEN="You need your DuckDNS token and subdomain."
    TXT_REGISTER="If you don't have them, register at:"
    TXT_TOKEN="DuckDNS Token"
    TXT_SUBDOMAIN="Subdomain (without .duckdns.org)"
    TXT_NEXT_ID="Next available ID is:"
    TXT_CONTAINER_ID="Container ID"
    TXT_CONTAINER_NAME="Container name"
    TXT_ROOT_PASSWORD="Root password"
    TXT_PASSWORD_SHORT="Password must be at least 5 characters"
    TXT_ID_EXISTS="Container ID already exists"
    TXT_CHOOSE_OTHER="Choose another ID"
    TXT_STORAGE_AVAILABLE="Available storage:"
    TXT_STORAGE="Storage for container"
    TXT_BRIDGES="Available network bridges:"
    TXT_BRIDGE="Network bridge"
    TXT_CONFIRM_CONFIG="Container will be created with this configuration:"
    TXT_DOMAIN="Domain"
    TXT_CONTAINER="Container"
    TXT_MEMORY="Memory"
    TXT_DISK="Disk"
    TXT_INFRASTRUCTURE="Infrastructure"
    TXT_CONTINUE="Continue with installation?"
    TXT_CANCELLED="Installation cancelled"
    TXT_STARTING="Starting installation..."
    TXT_PROGRESS="INSTALLATION IN PROGRESS"
    TXT_TEMPLATES="Available templates:"
    TXT_STEP_TEMPLATES="Step 1/8: Searching for available templates..."
    TXT_STEP_CREATE="Step 2/8: Creating LXC container..."
    TXT_STEP_WAIT="Step 3/8: Waiting for container to be ready..."
    TXT_STEP_UPDATE="Step 4/8: Updating system in container..."
    TXT_STEP_DEPS="Step 5/8: Installing dependencies..."
    TXT_STEP_DUCK="Step 6/8: Configuring DuckDNS..."
    TXT_STEP_AUTO="Step 7/8: Configuring console autologin..."
    TXT_STEP_RESTART="Step 8/8: Restarting container to apply configuration..."
    TXT_USING_UBUNTU="Using Ubuntu 22.04 template:"
    TXT_USING_DEBIAN="Using Debian template:"
    TXT_DEBIAN_NOTE="Note: Using Debian because Ubuntu 22.04 is not available"
    TXT_USING_OTHER="Using available template:"
    TXT_OTHER_NOTE="Note: Using the most recent available template"
    TXT_DOWNLOADING="No templates found. Downloading Ubuntu 22.04..."
    TXT_DOWNLOADED="Template downloaded:"
    TXT_TEMPLATE_FOUND="Template found:"
    TXT_CREATED="Container created successfully"
    TXT_CREATE_FAILED="Failed to create container. Check parameters."
    TXT_STARTING_CONTAINER="Starting container..."
    TXT_CRON="Configuring cron for automatic updates..."
    TXT_FIRST_UPDATE="Testing first update..."
    TXT_UPDATE_OK="First update successful:"
    TXT_UPDATE_ERR="Possible update error:"
    TXT_CLEANING="Cleaning system..."
    TXT_COMPLETE="INSTALLATION COMPLETED SUCCESSFULLY!"
    TXT_SUMMARY="INSTALLATION SUMMARY"
    TXT_FEATURES="Features"
    TXT_AUTOBOOT="Autoboot enabled"
    TXT_AUTOLOGIN="Console autologin"
    TXT_CRON_5MIN="Cron every 5 minutes"
    TXT_WELCOME="Welcome screen"
    TXT_USEFUL_CMD="USEFUL COMMANDS"
    TXT_ACCESS_CONTAINER="Access container (no password)"
    TXT_VIEW_INFO="View DuckDNS info"
    TXT_CONTROL="Container control"
    TXT_VERIFY="VERIFY FUNCTIONALITY"
    TXT_VERIFY_DNS="Verify DNS resolution"
    TXT_YOUR_IP="Your current public IP"
    TXT_AUTOLOGIN_TIP="If autologin doesn't work:"
    TXT_FOOTER="Developed in Puerto Rico with coffee for the Proxmox community"
    TXT_REQUIRED="This field is required"
fi

# Función para mostrar mensajes con colores
show_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║   🦆  $TXT_HEADER_TITLE  🦆"
    echo "║                                                               ║"
    echo "║   $TXT_HEADER_DESC  "
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_step() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Función para leer input con valor por defecto
read_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local required="$4"

    if [ -n "$default" ]; then
        echo -ne "${GREEN}▶${NC} $prompt ${CYAN}[$default]${NC}: "
    else
        echo -ne "${GREEN}▶${NC} $prompt: "
    fi

    read user_input

    if [ -z "$user_input" ] && [ -n "$default" ]; then
        eval "$var_name='$default'"
    elif [ -z "$user_input" ] && [ "$required" = "true" ]; then
        show_error "$TXT_REQUIRED"
        read_input "$prompt" "$default" "$var_name" "$required"
    else
        eval "$var_name='$user_input'"
    fi
}

# Función para seleccionar de una lista
select_option() {
    local prompt="$1"
    shift
    local options=("$@")

    echo -e "${GREEN}▶${NC} $prompt"
    echo ""

    local i=1
    for opt in "${options[@]}"; do
        echo -e "   ${CYAN}$i)${NC} $opt"
        ((i++))
    done
    echo ""
    echo -ne "   Selecciona una opción ${CYAN}[1]${NC}: "
    read selection

    selection=${selection:-1}

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#options[@]} ]; then
        selection=1
    fi

    echo "$selection"
}

# Función para obtener el siguiente ID disponible
get_next_available_id() {
    # Obtener IDs de contenedores LXC y VMs
    local lxc_ids=$(pct list 2>/dev/null | tail -n +2 | awk '{print $1}')
    local vm_ids=$(qm list 2>/dev/null | tail -n +2 | awk '{print $1}')

    # Combinar y encontrar el máximo
    local max_id=$(echo -e "$lxc_ids\n$vm_ids" | grep -E '^[0-9]+$' | sort -n | tail -1)

    if [ -z "$max_id" ]; then
        echo 100
    else
        echo $((max_id + 1))
    fi
}

show_header

# Verificar que estamos en Proxmox
if ! command -v pct &> /dev/null; then
    show_error "$TXT_PROXMOX_ERROR"
    echo ""
    echo "$TXT_PROXMOX_HINT"
    exit 1
fi

show_success "$TXT_PROXMOX_OK"
echo ""

# ═══════════════════════════════════════════════════════════════
# PASO 1: Configuración de DuckDNS
# ═══════════════════════════════════════════════════════════════
show_step "$TXT_STEP1"

echo -e "${WHITE}$TXT_NEED_TOKEN${NC}"
echo -e "$TXT_REGISTER ${CYAN}https://www.duckdns.org${NC}"
echo ""

read_input "$TXT_TOKEN" "" "DUCKDNS_TOKEN" "true"
read_input "$TXT_SUBDOMAIN" "" "DUCKDNS_DOMAIN" "true"

# ═══════════════════════════════════════════════════════════════
# PASO 2: Configuración del Contenedor
# ═══════════════════════════════════════════════════════════════
show_step "$TXT_STEP2"

NEXT_ID=$(get_next_available_id)
echo -e "${WHITE}$TXT_NEXT_ID ${CYAN}$NEXT_ID${NC}"
echo ""

read_input "$TXT_CONTAINER_ID" "$NEXT_ID" "CONTAINER_ID" "true"
read_input "$TXT_CONTAINER_NAME" "duckdns" "CONTAINER_HOSTNAME" "false"
read_input "$TXT_ROOT_PASSWORD" "duckdns" "CONTAINER_PASSWORD" "false"

# Validar longitud mínima de contraseña (Proxmox requiere mínimo 5 caracteres)
while [ ${#CONTAINER_PASSWORD} -lt 5 ]; do
    show_error "$TXT_PASSWORD_SHORT"
    read_input "$TXT_ROOT_PASSWORD" "duckdns" "CONTAINER_PASSWORD" "false"
done

# Verificar que el ID no exista
if pct status $CONTAINER_ID &> /dev/null; then
    show_error "$TXT_ID_EXISTS: $CONTAINER_ID"
    echo ""
    read_input "$TXT_CHOOSE_OTHER" "$NEXT_ID" "CONTAINER_ID" "true"
fi

# ═══════════════════════════════════════════════════════════════
# PASO 3: Configuración de Almacenamiento y Red
# ═══════════════════════════════════════════════════════════════
show_step "$TXT_STEP3"

# Obtener lista de storages disponibles
echo -e "${WHITE}$TXT_STORAGE_AVAILABLE${NC}"
pvesm status | grep -E "active" | awk '{print "   • " $1}'
echo ""

read_input "$TXT_STORAGE" "local-lvm" "STORAGE" "false"

# Obtener bridges disponibles
echo ""
echo -e "${WHITE}$TXT_BRIDGES${NC}"
ip link show type bridge 2>/dev/null | grep -E "^[0-9]" | awk -F: '{print "   • " $2}' | tr -d ' '
echo ""

read_input "$TXT_BRIDGE" "vmbr0" "NETWORK_BRIDGE" "false"

# ═══════════════════════════════════════════════════════════════
# PASO 4: Confirmación
# ═══════════════════════════════════════════════════════════════
show_step "$TXT_STEP4"

echo -e "${WHITE}$TXT_CONFIRM_CONFIG${NC}"
echo ""
echo -e "   ${CYAN}DuckDNS${NC}"
echo -e "   ├─ $TXT_DOMAIN: ${GREEN}$DUCKDNS_DOMAIN.duckdns.org${NC}"
echo -e "   └─ Token: ${GREEN}${DUCKDNS_TOKEN:0:8}...${NC}"
echo ""
echo -e "   ${CYAN}$TXT_CONTAINER${NC}"
echo -e "   ├─ ID: ${GREEN}$CONTAINER_ID${NC}"
echo -e "   ├─ $TXT_CONTAINER_NAME: ${GREEN}$CONTAINER_HOSTNAME${NC}"
echo -e "   ├─ Password: ${GREEN}$CONTAINER_PASSWORD${NC}"
echo -e "   ├─ $TXT_MEMORY: ${GREEN}512MB${NC}"
echo -e "   └─ $TXT_DISK: ${GREEN}2GB${NC}"
echo ""
echo -e "   ${CYAN}$TXT_INFRASTRUCTURE${NC}"
echo -e "   ├─ Storage: ${GREEN}$STORAGE${NC}"
echo -e "   └─ Network: ${GREEN}$NETWORK_BRIDGE${NC}"
echo ""

echo -ne "${YELLOW}$TXT_CONTINUE [Y/n]:${NC} "
read confirm
confirm=${confirm:-Y}

if [[ ! "$confirm" =~ ^[SsYy]$ ]]; then
    echo ""
    show_info "$TXT_CANCELLED"
    exit 0
fi

echo ""
show_info "$TXT_STARTING"
echo ""

# Configuración por defecto
CONTAINER_MEMORY=${CONTAINER_MEMORY:-512}
CONTAINER_DISK=${CONTAINER_DISK:-2}
CONTAINER_CORES=${CONTAINER_CORES:-1}
TEMPLATE_NAME="ubuntu-22.04-standard"

# ═══════════════════════════════════════════════════════════════
# INSTALACIÓN EN PROGRESO
# ═══════════════════════════════════════════════════════════════

show_progress() {
    local current=$1
    local total=$2
    local task=$3
    local pct=$((current * 100 / total))
    local filled=$((pct / 5))
    local empty=$((20 - filled))

    printf "\r${CYAN}[${NC}"
    printf "%0.s█" $(seq 1 $filled 2>/dev/null) 2>/dev/null || printf "█%.0s" {1..$filled}
    printf "%0.s░" $(seq 1 $empty 2>/dev/null) 2>/dev/null || printf "░%.0s" {1..$empty}
    printf "${CYAN}]${NC} ${WHITE}%3d%%${NC} - %s" "$pct" "$task"
}

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${WHITE}$TXT_PROGRESS${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

show_info "$TXT_STEP_TEMPLATES"
echo ""
echo -e "${WHITE}$TXT_TEMPLATES${NC}"
pveam list local 2>/dev/null | tail -n +2

# Buscar templates disponibles en orden de preferencia
TEMPLATE=""

# Primero intentar Ubuntu 22.04
TEMPLATE=$(pveam list local 2>/dev/null | grep -i ubuntu | grep -E "(22\.04|22-04)" | head -1 | awk '{print $1}' | sed 's|local:vztmpl/||')
if [ -n "$TEMPLATE" ]; then
    show_success "$TXT_USING_UBUNTU $TEMPLATE"
else
    # Si no hay Ubuntu, buscar Debian 12 o 13
    TEMPLATE=$(pveam list local 2>/dev/null | grep -i debian | grep -E "(1[23]|1[23]\.)" | head -1 | awk '{print $1}' | sed 's|local:vztmpl/||')
    if [ -n "$TEMPLATE" ]; then
        show_success "$TXT_USING_DEBIAN $TEMPLATE"
        show_info "$TXT_DEBIAN_NOTE"
    else
        # Buscar cualquier template de Ubuntu o Debian reciente
        TEMPLATE=$(pveam list local 2>/dev/null | grep -iE "(ubuntu|debian)" | head -1 | awk '{print $1}' | sed 's|local:vztmpl/||')
        if [ -n "$TEMPLATE" ]; then
            show_success "$TXT_USING_OTHER $TEMPLATE"
            show_info "$TXT_OTHER_NOTE"
        else
            # Si no hay ninguno, descargar Ubuntu 22.04
            show_info "$TXT_DOWNLOADING"
            pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
            TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
            show_success "$TXT_DOWNLOADED $TEMPLATE"
        fi
    fi
fi

show_success "$TXT_TEMPLATE_FOUND $TEMPLATE"

# Verificar que el ID del contenedor no exista
if pct status $CONTAINER_ID &> /dev/null; then
    show_error "$TXT_ID_EXISTS: $CONTAINER_ID"
    exit 1
fi

show_info "$TXT_STEP_CREATE"
# Crear el contenedor LXC con autoboot habilitado
if ! pct create $CONTAINER_ID local:vztmpl/$TEMPLATE \
    --hostname $CONTAINER_HOSTNAME \
    --memory $CONTAINER_MEMORY \
    --cores $CONTAINER_CORES \
    --rootfs $STORAGE:$CONTAINER_DISK \
    --net0 name=eth0,bridge=$NETWORK_BRIDGE,ip=dhcp \
    --password "$CONTAINER_PASSWORD" \
    --start 1 \
    --onboot 1 \
    --unprivileged 1 \
    --features nesting=1; then
    show_error "$TXT_CREATE_FAILED"
    exit 1
fi

show_success "$TXT_CREATED: $CONTAINER_ID"

# Esperar a que el contenedor esté listo
show_info "$TXT_STEP_WAIT"
sleep 15

# Verificar que el contenedor está corriendo
if ! pct status $CONTAINER_ID 2>/dev/null | grep -q "running"; then
    show_info "$TXT_STARTING_CONTAINER"
    pct start $CONTAINER_ID
    sleep 10
fi

# Función para ejecutar comandos en el contenedor
run_in_container() {
    pct exec $CONTAINER_ID -- bash -c "$1"
}

show_info "$TXT_STEP_UPDATE"
# Actualizar el sistema
run_in_container "apt update && apt upgrade -y"

show_info "$TXT_STEP_DEPS"
# Instalar dependencias
run_in_container "apt install -y curl cron wget"

show_info "$TXT_STEP_DUCK"
# Crear directorio para DuckDNS
run_in_container "mkdir -p /opt/duckdns"

# Crear el script de actualización de DuckDNS mejorado
run_in_container "cat > /opt/duckdns/duck.sh << 'EOF'
#!/bin/bash
# Script de actualización de DuckDNS - se ejecuta cada 5 minutos
# Mantiene la IP actualizada automáticamente, ¡qué brutal!

# Obtener IP actual
CURRENT_IP=\$(curl -s ifconfig.me 2>/dev/null)
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

# Crear directorio de logs si no existe
mkdir -p /var/log/duckdns

# Actualizar DuckDNS
RESULT=\$(echo url=\"https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=\" | curl -k -s -K -)

# Guardar resultado en log principal
echo \"\$RESULT\" > ~/duckdns.log

# Guardar log detallado
echo \"[\$TIMESTAMP] IP: \$CURRENT_IP - Resultado: \$RESULT\" >> /var/log/duckdns/detailed.log

# Mantener solo las últimas 100 líneas del log detallado
tail -n 100 /var/log/duckdns/detailed.log > /var/log/duckdns/detailed.log.tmp
mv /var/log/duckdns/detailed.log.tmp /var/log/duckdns/detailed.log
EOF"

# Dar permisos al script
run_in_container "chmod 700 /opt/duckdns/duck.sh"

show_info "$TXT_CRON"
# Configurar cron para ejecutar cada 5 minutos
run_in_container "cat > /etc/cron.d/duckdns << 'EOF'
*/5 * * * * root /opt/duckdns/duck.sh >/dev/null 2>&1
EOF"

# Configurar permisos de cron
run_in_container "chmod 644 /etc/cron.d/duckdns"

# Reiniciar cron
run_in_container "systemctl restart cron"

show_info "$TXT_FIRST_UPDATE"
# Ejecutar una primera actualización
run_in_container "/opt/duckdns/duck.sh"

# Verificar el resultado
RESULT=$(run_in_container "cat ~/duckdns.log 2>/dev/null || echo 'No log found'")
if [[ "$RESULT" == *"OK"* ]]; then
    show_success "$TXT_UPDATE_OK $RESULT"
else
    show_error "$TXT_UPDATE_ERR $RESULT"
fi

show_info "$TXT_CLEANING"
# Limpiar sistema
run_in_container "apt autoremove -y && apt autoclean"

# Crear script de información avanzado dentro del contenedor
run_in_container "cat > /root/duckdns-info.sh << 'EOF'
#!/bin/bash
echo \"===== DUCKDNS INFO =====\"
echo \"Domain: $DUCKDNS_DOMAIN.duckdns.org\"
echo \"Cron service status:\"
systemctl status cron --no-pager -l
echo \"\"
echo \"Last update:\"
cat ~/duckdns.log 2>/dev/null || echo \"No log available\"
echo \"\"
echo \"View logs: tail -f ~/duckdns.log\"
echo \"Manual update: /opt/duckdns/duck.sh\"
EOF"

run_in_container "chmod +x /root/duckdns-info.sh"

# Crear script de bienvenida que se ejecuta al hacer login
run_in_container "cat > /opt/duckdns/welcome.sh << 'EOF'
#!/bin/bash

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo \"\"
echo -e \"\${CYAN}============================================\${NC}\"
echo -e \"\${CYAN}       DUCKDNS LXC CONTAINER\${NC}\"
echo -e \"\${CYAN}============================================\${NC}\"
echo \"\"

# Información del dominio
echo -e \"\${GREEN}[Domain]\${NC} $DUCKDNS_DOMAIN.duckdns.org\"

# Obtener IP actual del servidor
CURRENT_IP=\$(curl -s ifconfig.me 2>/dev/null || echo \"Unavailable\")
echo -e \"\${GREEN}[Server IP]\${NC} \$CURRENT_IP\"

# Verificar última actualización
if [ -f ~/duckdns.log ]; then
    LAST_UPDATE=\$(stat -c %y ~/duckdns.log 2>/dev/null | cut -d. -f1)
    LAST_RESULT=\$(cat ~/duckdns.log 2>/dev/null)

    echo -e \"\${GREEN}[Last Update]\${NC} \$LAST_UPDATE\"

    if [[ \"\$LAST_RESULT\" == *\"OK\"* ]]; then
        echo -e \"\${GREEN}[Status]\${NC} OK - Update successful\"
    elif [[ \"\$LAST_RESULT\" == *\"KO\"* ]]; then
        echo -e \"\${RED}[Status]\${NC} ERROR - Update failed\"
    else
        echo -e \"\${YELLOW}[Status]\${NC} Unknown: \$LAST_RESULT\"
    fi

    # Mostrar historial de las últimas 3 actualizaciones
    if [ -f /var/log/duckdns/detailed.log ]; then
        echo \"\"
        echo -e \"\${BLUE}[Recent Updates]\${NC}\"
        tail -n 3 /var/log/duckdns/detailed.log | while read line; do
            if [[ \"\$line\" == *\"OK\"* ]]; then
                echo -e \"  \${GREEN}+\${NC} \$line\"
            elif [[ \"\$line\" == *\"KO\"* ]]; then
                echo -e \"  \${RED}x\${NC} \$line\"
            else
                echo -e \"  \${YELLOW}?\${NC} \$line\"
            fi
        done
    fi
else
    echo -e \"\${YELLOW}[Status]\${NC} No updates recorded yet\"
fi

echo \"\"

# Verificar si cron está funcionando
if systemctl is-active --quiet cron; then
    echo -e \"\${GREEN}[Cron]\${NC} Active (updates every 5 min)\"
else
    echo -e \"\${RED}[Cron]\${NC} Inactive\"
fi

# Verificar resolución DNS
DNS_IP=\$(nslookup $DUCKDNS_DOMAIN.duckdns.org 2>/dev/null | grep -A1 \"Name:\" | grep \"Address:\" | awk '{print \$2}' | head -1)
if [ -n \"\$DNS_IP\" ]; then
    echo -e \"\${GREEN}[DNS]\${NC} Resolves to: \$DNS_IP\"
    if [ \"\$DNS_IP\" = \"\$CURRENT_IP\" ]; then
        echo -e \"\${GREEN}[Sync]\${NC} OK - IPs match\"
    else
        echo -e \"\${YELLOW}[Sync]\${NC} Warning - IPs differ\"
    fi
else
    echo -e \"\${RED}[DNS]\${NC} Could not resolve domain\"
fi

echo \"\"
echo -e \"\${CYAN}--------------------------------------------\${NC}\"
echo -e \"\${BOLD}Commands:\${NC}\"
echo \"  duckdns              - Show this info\"
echo \"  /opt/duckdns/duck.sh - Manual update\"
echo \"  tail -f ~/duckdns.log - Live logs\"
echo -e \"\${CYAN}--------------------------------------------\${NC}\"
echo \"\"
EOF"

run_in_container "chmod +x /opt/duckdns/welcome.sh"

# Agregar el script de bienvenida al .bashrc para que se ejecute al hacer login
run_in_container "echo '' >> /root/.bashrc"
run_in_container "echo '# Mostrar información de DuckDNS al hacer login' >> /root/.bashrc"
run_in_container "echo '/opt/duckdns/welcome.sh' >> /root/.bashrc"

# También crear un alias para mostrar la info rápidamente
run_in_container "echo 'alias duckdns=\"/opt/duckdns/welcome.sh\"' >> /root/.bashrc"

show_info "$TXT_STEP_AUTO"
# Configurar autologin en la consola del contenedor
run_in_container "mkdir -p /etc/systemd/system/console-getty.service.d"
run_in_container "cat > /etc/systemd/system/console-getty.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# También configurar autologin para tty1 (consola principal)
run_in_container "mkdir -p /etc/systemd/system/getty@tty1.service.d"
run_in_container "cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# Configurar autologin para container-getty (específico para contenedores LXC)
run_in_container "mkdir -p /etc/systemd/system/container-getty@1.service.d"
run_in_container "cat > /etc/systemd/system/container-getty@1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud pts/%I 115200,38400,9600 vt220
EOF"

# Habilitar los servicios de autologin
run_in_container "systemctl daemon-reload"
run_in_container "systemctl enable console-getty.service"
run_in_container "systemctl enable container-getty@1.service"

show_info "$TXT_STEP_RESTART"
# Reiniciar el contenedor para que el autologin surta efecto
pct stop $CONTAINER_ID
sleep 2
pct start $CONTAINER_ID

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   🎉  $TXT_COMPLETE  🎉"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${WHITE}📦 $TXT_SUMMARY${NC}"
echo ""
echo -e "   ${CYAN}$TXT_CONTAINER${NC}"
echo -e "   ├─ ID: ${GREEN}$CONTAINER_ID${NC}"
echo -e "   ├─ Hostname: ${GREEN}$CONTAINER_HOSTNAME${NC}"
echo -e "   ├─ Password: ${GREEN}$CONTAINER_PASSWORD${NC}"
echo -e "   ├─ Storage: ${GREEN}$STORAGE${NC}"
echo -e "   └─ Network: ${GREEN}$NETWORK_BRIDGE${NC}"
echo ""
echo -e "   ${CYAN}DuckDNS${NC}"
echo -e "   └─ $TXT_DOMAIN: ${GREEN}$DUCKDNS_DOMAIN.duckdns.org${NC}"
echo ""
echo -e "   ${CYAN}$TXT_FEATURES${NC}"
echo -e "   ├─ ✅ $TXT_AUTOBOOT"
echo -e "   ├─ ✅ $TXT_AUTOLOGIN"
echo -e "   ├─ ✅ $TXT_CRON_5MIN"
echo -e "   └─ ✅ $TXT_WELCOME"
echo ""

echo -e "${WHITE}📋 $TXT_USEFUL_CMD${NC}"
echo ""
echo -e "   ${CYAN}# $TXT_ACCESS_CONTAINER${NC}"
echo -e "   pct enter $CONTAINER_ID"
echo ""
echo -e "   ${CYAN}# $TXT_VIEW_INFO${NC}"
echo -e "   pct exec $CONTAINER_ID -- duckdns"
echo ""
echo -e "   ${CYAN}# $TXT_CONTROL${NC}"
echo -e "   pct stop $CONTAINER_ID"
echo -e "   pct start $CONTAINER_ID"
echo -e "   pct reboot $CONTAINER_ID"
echo ""

echo -e "${WHITE}🔍 $TXT_VERIFY${NC}"
echo ""
echo -e "   ${CYAN}# $TXT_VERIFY_DNS${NC}"
echo -e "   nslookup $DUCKDNS_DOMAIN.duckdns.org"
echo ""
echo -e "   ${CYAN}# $TXT_YOUR_IP${NC}"
echo -e "   curl -s ifconfig.me"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}  💡 $TXT_AUTOLOGIN_TIP ${CYAN}pct reboot $CONTAINER_ID${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "🚀 ${GREEN}$TXT_FOOTER${NC}"
echo "" 