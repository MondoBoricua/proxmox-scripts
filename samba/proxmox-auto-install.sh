#!/bin/bash

# Instalador Automatico de Samba para Proxmox LXC
# Desarrollado por MondoBoricua para la comunidad de Proxmox
# Version: 2.0 - Bilingual Edition

set -e  # Salir si hay algun error

# Silenciar warnings de locale
export LC_ALL=C
export LANG=C

# Colores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# SELECCION DE IDIOMA / LANGUAGE SELECTION
# =============================================================================
select_language() {
    echo ""
    echo "Select language / Selecciona idioma:"
    echo "   1) English"
    echo "   2) Espanol"
    echo ""
    read -p "Option / Opcion [1]: " LANG_CHOICE
    LANG_CHOICE=${LANG_CHOICE:-1}

    if [[ "$LANG_CHOICE" == "2" ]]; then
        SCRIPT_LANG="es"
    else
        SCRIPT_LANG="en"
    fi
}

# =============================================================================
# TEXTOS EN AMBOS IDIOMAS / BILINGUAL TEXTS
# =============================================================================
set_language_texts() {
    if [[ "$SCRIPT_LANG" == "es" ]]; then
        # Espanol
        TXT_STEP1="PASO 1/5: Configuracion del Contenedor"
        TXT_STEP2="PASO 2/5: Almacenamiento y Red"
        TXT_STEP3="PASO 3/5: Mapeo de Carpetas"
        TXT_STEP4="PASO 4/5: Confirmacion"
        TXT_STEP5="PASO 5/5: Instalacion"
        TXT_REQUIRED="Este campo es obligatorio"
        TXT_CONTAINER_ID="ID del contenedor"
        TXT_HOSTNAME="Nombre del contenedor"
        TXT_PASSWORD="Contrasena root"
        TXT_PASSWORD_SHORT="La contrasena debe tener al menos 5 caracteres"
        TXT_STORAGE="Almacenamiento"
        TXT_DISK_SIZE="Tamano del disco"
        TXT_MEMORY="Memoria RAM (MB)"
        TXT_CORES="Nucleos CPU"
        TXT_BRIDGE="Bridge de red"
        TXT_STATIC_IP="Usar IP estatica? (s/n)"
        TXT_IP_ADDRESS="IP estatica (ej: 192.168.1.100/24)"
        TXT_GATEWAY="Gateway"
        TXT_MAP_FOLDER="Mapear carpeta del host? (s/n)"
        TXT_HOST_PATH="Ruta en el host (ej: /mnt/storage)"
        TXT_MOUNT_POINT="Punto de montaje en contenedor"
        TXT_CREATE_FOLDER="Crear carpeta?"
        TXT_FOLDER_CREATED="Carpeta creada"
        TXT_FOLDER_NOT_EXIST="La carpeta no existe en el host"
        TXT_CONTINUE="Continuar? (S/n)"
        TXT_CANCELLED="Instalacion cancelada"
        TXT_PROXMOX_DETECTED="Proxmox VE detectado"
        TXT_PROXMOX_ERROR="Este script debe ejecutarse en Proxmox VE"
        TXT_TEMPLATE_FOUND="Template encontrado"
        TXT_TEMPLATE_DOWNLOADING="Descargando template"
        TXT_TEMPLATE_LOCAL="Template ya disponible localmente"
        TXT_TEMPLATE_ERROR="No se encontro ningun template de Ubuntu o Debian"
        TXT_STORAGE_VERIFIED="Storage verificado"
        TXT_STORAGE_NOT_FOUND="Storage no encontrado"
        TXT_BRIDGE_VERIFIED="Bridge de red verificado"
        TXT_BRIDGE_NOT_FOUND="Bridge de red no encontrado"
        TXT_CTID_AVAILABLE="ID de contenedor disponible"
        TXT_CTID_EXISTS="El contenedor ID ya existe"
        TXT_CREATING_CONTAINER="Creando contenedor"
        TXT_CONTAINER_CREATED="Contenedor creado exitosamente"
        TXT_CONTAINER_RUNNING="Contenedor corriendo"
        TXT_CONTAINER_ERROR="Error al crear el contenedor"
        TXT_WAITING_CONTAINER="Esperando que el contenedor este listo..."
        TXT_AUTOLOGIN_CONFIG="Configurando autologin"
        TXT_AUTOLOGIN_DONE="Autologin configurado"
        TXT_MAPPING_CONFIG="Configurando mapeo de carpetas"
        TXT_MAPPING_DONE="Mapeo configurado"
        TXT_SAMBA_INSTALL="Instalando Samba"
        TXT_SAMBA_DONE="Samba instalado y configurado"
        TXT_GETTING_IP="Obteniendo IP del contenedor..."
        TXT_IP_FOUND="IP del contenedor"
        TXT_IP_NOT_FOUND="No se pudo obtener la IP automaticamente"
        TXT_INSTALLATION_COMPLETE="INSTALACION COMPLETADA"
        TXT_SERVER_CREATED="Servidor Samba creado exitosamente"
        TXT_CONTAINER_INFO="INFORMACION DEL CONTENEDOR"
        TXT_HOW_TO_CONNECT="COMO CONECTARSE"
        TXT_FROM_WINDOWS="Desde Windows"
        TXT_FROM_LINUX="Desde Linux"
        TXT_FROM_MOBILE="Desde movil"
        TXT_SHARED_RESOURCES="RECURSOS COMPARTIDOS"
        TXT_PUBLIC_ACCESS="Acceso publico sin autenticacion"
        TXT_HOST_DATA="Datos del host Proxmox"
        TXT_CONTAINER_MANAGEMENT="GESTION DEL CONTENEDOR"
        TXT_ACCESS_CONSOLE="Acceder a consola"
        TXT_RESTART="Reiniciar"
        TXT_STOP="Detener"
        TXT_START="Iniciar"
        TXT_STATUS="Ver estado"
        TXT_TOOLS_CONTAINER="HERRAMIENTAS EN EL CONTENEDOR"
        TXT_VIEW_INFO="Ver informacion"
        TXT_MANAGE_SAMBA="Gestionar Samba"
        TXT_CREATE_BACKUP="Crear backup"
        TXT_READY="Listo! Tu servidor Samba esta funcionando."
        TXT_ACCESS_NOW="Acceder al contenedor ahora? (s/n)"
        TXT_ACCESSING="Accediendo al contenedor..."
        TXT_EXIT_MSG="Usa 'exit' para salir del contenedor"
        TXT_AVAILABLE_STORAGES="Almacenamientos disponibles:"
        TXT_AVAILABLE_BRIDGES="Bridges de red disponibles:"
        TXT_YES_OPTS="SsYy"
    else
        # English
        TXT_STEP1="STEP 1/5: Container Configuration"
        TXT_STEP2="STEP 2/5: Storage and Network"
        TXT_STEP3="STEP 3/5: Folder Mapping"
        TXT_STEP4="STEP 4/5: Confirmation"
        TXT_STEP5="STEP 5/5: Installation"
        TXT_REQUIRED="This field is required"
        TXT_CONTAINER_ID="Container ID"
        TXT_HOSTNAME="Container name"
        TXT_PASSWORD="Root password"
        TXT_PASSWORD_SHORT="Password must be at least 5 characters"
        TXT_STORAGE="Storage"
        TXT_DISK_SIZE="Disk size"
        TXT_MEMORY="RAM Memory (MB)"
        TXT_CORES="CPU Cores"
        TXT_BRIDGE="Network bridge"
        TXT_STATIC_IP="Use static IP? (y/n)"
        TXT_IP_ADDRESS="Static IP (e.g.: 192.168.1.100/24)"
        TXT_GATEWAY="Gateway"
        TXT_MAP_FOLDER="Map host folder? (y/n)"
        TXT_HOST_PATH="Host path (e.g.: /mnt/storage)"
        TXT_MOUNT_POINT="Mount point in container"
        TXT_CREATE_FOLDER="Create folder?"
        TXT_FOLDER_CREATED="Folder created"
        TXT_FOLDER_NOT_EXIST="Folder does not exist on host"
        TXT_CONTINUE="Continue? (Y/n)"
        TXT_CANCELLED="Installation cancelled"
        TXT_PROXMOX_DETECTED="Proxmox VE detected"
        TXT_PROXMOX_ERROR="This script must run on Proxmox VE"
        TXT_TEMPLATE_FOUND="Template found"
        TXT_TEMPLATE_DOWNLOADING="Downloading template"
        TXT_TEMPLATE_LOCAL="Template already available locally"
        TXT_TEMPLATE_ERROR="No Ubuntu or Debian template found"
        TXT_STORAGE_VERIFIED="Storage verified"
        TXT_STORAGE_NOT_FOUND="Storage not found"
        TXT_BRIDGE_VERIFIED="Network bridge verified"
        TXT_BRIDGE_NOT_FOUND="Network bridge not found"
        TXT_CTID_AVAILABLE="Container ID available"
        TXT_CTID_EXISTS="Container ID already exists"
        TXT_CREATING_CONTAINER="Creating container"
        TXT_CONTAINER_CREATED="Container created successfully"
        TXT_CONTAINER_RUNNING="Container running"
        TXT_CONTAINER_ERROR="Error creating container"
        TXT_WAITING_CONTAINER="Waiting for container to be ready..."
        TXT_AUTOLOGIN_CONFIG="Configuring autologin"
        TXT_AUTOLOGIN_DONE="Autologin configured"
        TXT_MAPPING_CONFIG="Configuring folder mapping"
        TXT_MAPPING_DONE="Folder mapping configured"
        TXT_SAMBA_INSTALL="Installing Samba"
        TXT_SAMBA_DONE="Samba installed and configured"
        TXT_GETTING_IP="Getting container IP..."
        TXT_IP_FOUND="Container IP"
        TXT_IP_NOT_FOUND="Could not get IP automatically"
        TXT_INSTALLATION_COMPLETE="INSTALLATION COMPLETE"
        TXT_SERVER_CREATED="Samba server created successfully"
        TXT_CONTAINER_INFO="CONTAINER INFORMATION"
        TXT_HOW_TO_CONNECT="HOW TO CONNECT"
        TXT_FROM_WINDOWS="From Windows"
        TXT_FROM_LINUX="From Linux"
        TXT_FROM_MOBILE="From mobile"
        TXT_SHARED_RESOURCES="SHARED RESOURCES"
        TXT_PUBLIC_ACCESS="Public access without authentication"
        TXT_HOST_DATA="Proxmox host data"
        TXT_CONTAINER_MANAGEMENT="CONTAINER MANAGEMENT"
        TXT_ACCESS_CONSOLE="Access console"
        TXT_RESTART="Restart"
        TXT_STOP="Stop"
        TXT_START="Start"
        TXT_STATUS="View status"
        TXT_TOOLS_CONTAINER="TOOLS IN CONTAINER"
        TXT_VIEW_INFO="View info"
        TXT_MANAGE_SAMBA="Manage Samba"
        TXT_CREATE_BACKUP="Create backup"
        TXT_READY="Ready! Your Samba server is running."
        TXT_ACCESS_NOW="Access container now? (y/n)"
        TXT_ACCESSING="Accessing container..."
        TXT_EXIT_MSG="Use 'exit' to leave the container"
        TXT_AVAILABLE_STORAGES="Available storages:"
        TXT_AVAILABLE_BRIDGES="Available network bridges:"
        TXT_YES_OPTS="YySs"
    fi
}

# =============================================================================
# VARIABLES POR DEFECTO / DEFAULT VARIABLES
# =============================================================================
DEFAULT_HOSTNAME="samba-server"
DEFAULT_PASSWORD="samba123"
DEFAULT_STORAGE="local-lvm"
DEFAULT_DISK_SIZE="4G"
DEFAULT_MEMORY=1024
DEFAULT_CORES=2
DEFAULT_BRIDGE="vmbr0"

# =============================================================================
# FUNCIONES DE UTILIDAD / UTILITY FUNCTIONS
# =============================================================================

# Funciones de mensajes con estilo
show_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
show_success() { echo -e "${GREEN}[OK]${NC} $1"; }
show_error() { echo -e "${RED}[ERROR]${NC} $1"; }
show_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Compatibilidad con nombres antiguos
print_message() { show_info "$1"; }
print_warning() { show_warning "$1"; }
print_error() { show_error "$1"; }
print_success() { show_success "$1"; }

# Header visual mejorado
show_header() {
    clear
    echo -e "${CYAN}"
    echo "+=================================================================+"
    echo "|                                                                 |"
    echo "|   SAMBA SERVER - PROXMOX LXC INSTALLER                          |"
    echo "|   Developed by MondoBoricua                                     |"
    echo "|                                                                 |"
    echo "+=================================================================+"
    echo -e "${NC}"
}

# Mostrar paso del proceso
show_step() {
    echo ""
    echo -e "${YELLOW}=================================================================${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${YELLOW}=================================================================${NC}"
    echo ""
}

# Leer input con valor por defecto
read_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local required="$4"

    if [ -n "$default" ]; then
        echo -ne "${GREEN}>${NC} $prompt ${CYAN}[$default]${NC}: "
    else
        echo -ne "${GREEN}>${NC} $prompt: "
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

# Auto-detectar siguiente ID disponible
get_next_available_id() {
    local lxc_ids=$(pct list 2>/dev/null | tail -n +2 | awk '{print $1}')
    local vm_ids=$(qm list 2>/dev/null | tail -n +2 | awk '{print $1}')

    local max_id=$(echo -e "$lxc_ids\n$vm_ids" | grep -E '^[0-9]+$' | sort -n | tail -1)

    if [ -z "$max_id" ]; then
        echo 100
    else
        echo $((max_id + 1))
    fi
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Verificar que estamos en Proxmox
check_proxmox() {
    if ! command -v pct &> /dev/null; then
        show_error "$TXT_PROXMOX_ERROR"
        show_error "Command 'pct' not found"
        exit 1
    fi

    if ! command -v pvesm &> /dev/null; then
        show_error "$TXT_PROXMOX_ERROR"
        show_error "Command 'pvesm' not found"
        exit 1
    fi

    show_success "$TXT_PROXMOX_DETECTED"
}

# Verificar que el script se ejecute como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        show_error "This script must run as root / Este script debe ejecutarse como root"
        exit 1
    fi
}

# Buscar el mejor template disponible
find_best_template() {
    show_info "Searching for available templates..."

    # Buscar templates de Ubuntu y Debian
    TEMPLATE=""

    # Prioridad: Ubuntu 22.04, Ubuntu 20.04, Debian 12, Debian 11
    for template_pattern in "ubuntu-22.04" "ubuntu-20.04" "debian-12" "debian-11"; do
        found_template=$(pveam available --section system | grep "$template_pattern" | head -1 | awk '{print $2}' || true)
        if [ -n "$found_template" ]; then
            TEMPLATE="$found_template"
            show_info "$TXT_TEMPLATE_FOUND: $TEMPLATE"
            break
        fi
    done

    # Si no encontramos ninguno, buscar cualquier Ubuntu o Debian
    if [ -z "$TEMPLATE" ]; then
        for template_pattern in "ubuntu" "debian"; do
            found_template=$(pveam available --section system | grep "$template_pattern" | head -1 | awk '{print $2}' || true)
            if [ -n "$found_template" ]; then
                TEMPLATE="$found_template"
                show_info "$TXT_TEMPLATE_FOUND: $TEMPLATE"
                break
            fi
        done
    fi

    if [ -z "$TEMPLATE" ]; then
        show_error "$TXT_TEMPLATE_ERROR"
        show_error "Run 'pveam available --section system' to see available templates"
        exit 1
    fi

    # Verificar si el template ya está descargado
    if ! pveam list local | grep -q "$TEMPLATE"; then
        show_info "$TXT_TEMPLATE_DOWNLOADING: $TEMPLATE"
        pveam download local "$TEMPLATE"
        show_success "Template downloaded"
    else
        show_info "$TXT_TEMPLATE_LOCAL: $TEMPLATE"
    fi
}

# Verificar que el storage existe
check_storage() {
    if ! pvesm status | grep -q "^$STORAGE "; then
        show_error "$TXT_STORAGE_NOT_FOUND: '$STORAGE'"
        show_info "$TXT_AVAILABLE_STORAGES"
        pvesm status
        exit 1
    fi
    show_success "$TXT_STORAGE_VERIFIED: '$STORAGE'"
}

# Verificar que el bridge de red existe
check_bridge() {
    if ! ip link show "$BRIDGE" &>/dev/null; then
        show_error "$TXT_BRIDGE_NOT_FOUND: '$BRIDGE'"
        show_info "$TXT_AVAILABLE_BRIDGES"
        ip link show | grep "^[0-9]" | grep "vmbr\|br"
        exit 1
    fi
    show_success "$TXT_BRIDGE_VERIFIED: '$BRIDGE'"
}

# Verificar que el CTID no esté en uso
check_ctid() {
    if pct list | grep -q "^$CTID "; then
        show_error "$TXT_CTID_EXISTS: $CTID"
        show_info "Existing containers:"
        pct list
        exit 1
    fi
    show_success "$TXT_CTID_AVAILABLE: $CTID"
}

# Solicitar configuración al usuario
get_user_input() {
    # =========================================================================
    # PASO 1: Configuración básica del contenedor
    # =========================================================================
    show_step "$TXT_STEP1"

    # Auto-detectar siguiente ID disponible
    DEFAULT_CTID=$(get_next_available_id)

    read_input "$TXT_CONTAINER_ID" "$DEFAULT_CTID" "CTID" "true"
    read_input "$TXT_HOSTNAME" "$DEFAULT_HOSTNAME" "HOSTNAME" "true"

    # Contraseña con validación
    read_input "$TXT_PASSWORD" "$DEFAULT_PASSWORD" "PASSWORD" "false"

    # Validar longitud mínima de contraseña (Proxmox requiere 5 caracteres)
    while [ ${#PASSWORD} -lt 5 ]; do
        show_error "$TXT_PASSWORD_SHORT"
        read_input "$TXT_PASSWORD" "$DEFAULT_PASSWORD" "PASSWORD" "false"
    done

    # =========================================================================
    # PASO 2: Storage y Red
    # =========================================================================
    show_step "$TXT_STEP2"

    echo "$TXT_AVAILABLE_STORAGES"
    pvesm status | grep -E "active" | awk '{print "   - " $1 " (" $2 ")"}'
    echo ""
    read_input "$TXT_STORAGE" "$DEFAULT_STORAGE" "STORAGE" "true"

    read_input "$TXT_DISK_SIZE" "$DEFAULT_DISK_SIZE" "DISK_SIZE" "false"
    read_input "$TXT_MEMORY" "$DEFAULT_MEMORY" "MEMORY" "false"
    read_input "$TXT_CORES" "$DEFAULT_CORES" "CORES" "false"

    echo ""
    echo "$TXT_AVAILABLE_BRIDGES"
    ip link show type bridge 2>/dev/null | grep -E "^[0-9]" | awk -F: '{print "   - " $2}' | tr -d ' '
    echo ""
    read_input "$TXT_BRIDGE" "$DEFAULT_BRIDGE" "BRIDGE" "true"

    # Configuración de red
    read_input "$TXT_STATIC_IP" "n" "USE_STATIC_IP" "false"

    if [[ "$USE_STATIC_IP" =~ ^[$TXT_YES_OPTS]$ ]]; then
        read_input "$TXT_IP_ADDRESS" "" "STATIC_IP" "true"
        read_input "$TXT_GATEWAY" "" "GATEWAY" "true"
        NET_CONFIG="ip=$STATIC_IP,gw=$GATEWAY"
    else
        NET_CONFIG="ip=dhcp"
    fi

    # =========================================================================
    # PASO 3: Mapeo de carpetas
    # =========================================================================
    show_step "$TXT_STEP3"

    read_input "$TXT_MAP_FOLDER" "n" "MAP_HOST_FOLDER" "false"

    if [[ "$MAP_HOST_FOLDER" =~ ^[$TXT_YES_OPTS]$ ]]; then
        read_input "$TXT_HOST_PATH" "" "HOST_PATH" "true"
        read_input "$TXT_MOUNT_POINT" "/srv/samba/host-data" "MOUNT_POINT" "false"

        # Verificar que la carpeta del host existe
        if [ ! -d "$HOST_PATH" ]; then
            show_warning "$TXT_FOLDER_NOT_EXIST: $HOST_PATH"
            read_input "$TXT_CREATE_FOLDER (y/n)" "y" "CREATE_HOST_FOLDER" "false"

            if [[ "$CREATE_HOST_FOLDER" =~ ^[$TXT_YES_OPTS]$ ]]; then
                mkdir -p "$HOST_PATH"
                show_success "$TXT_FOLDER_CREATED: $HOST_PATH"
            fi
        fi
    fi

    show_success "Configuration collected"
}

# Mostrar resumen de configuración
show_configuration_summary() {
    show_step "$TXT_STEP4"

    echo -e "${CYAN}$TXT_CONTAINER_INFO${NC}"
    echo ""
    echo "   Container"
    echo "   |-- ID: ${GREEN}$CTID${NC}"
    echo "   |-- Hostname: ${GREEN}$HOSTNAME${NC}"
    echo "   |-- Password: ${GREEN}$PASSWORD${NC}"
    echo "   |-- Template: ${GREEN}$TEMPLATE${NC}"
    echo "   \`-- Storage: ${GREEN}$STORAGE${NC}"
    echo ""
    echo "   Resources"
    echo "   |-- Disk: ${GREEN}$DISK_SIZE${NC}"
    echo "   |-- Memory: ${GREEN}$MEMORY MB${NC}"
    echo "   \`-- CPU Cores: ${GREEN}$CORES${NC}"
    echo ""
    echo "   Network"
    echo "   |-- Bridge: ${GREEN}$BRIDGE${NC}"
    echo "   \`-- Config: ${GREEN}$NET_CONFIG${NC}"

    if [[ "$MAP_HOST_FOLDER" =~ ^[$TXT_YES_OPTS]$ ]]; then
        echo ""
        echo "   Folder Mapping"
        echo "   |-- Host: ${GREEN}$HOST_PATH${NC}"
        echo "   \`-- Mount: ${GREEN}$MOUNT_POINT${NC}"
    fi

    echo ""
    read_input "$TXT_CONTINUE" "y" "CONFIRM" "false"

    if [[ ! "$CONFIRM" =~ ^[$TXT_YES_OPTS]$ ]]; then
        show_info "$TXT_CANCELLED"
        exit 0
    fi
}

# Crear el contenedor LXC
create_container() {
    show_step "$TXT_STEP5"

    show_info "$TXT_CREATING_CONTAINER $CTID..."

    # Extraer solo el número del tamaño del disco (quitar la G si existe)
    DISK_SIZE_NUM=$(echo "$DISK_SIZE" | sed 's/[^0-9]//g')

    CREATE_CMD="pct create $CTID /var/lib/vz/template/cache/$TEMPLATE \
        --hostname $HOSTNAME \
        --storage $STORAGE \
        --rootfs $STORAGE:$DISK_SIZE_NUM \
        --password $PASSWORD \
        --net0 name=eth0,bridge=$BRIDGE,$NET_CONFIG \
        --memory $MEMORY \
        --cores $CORES \
        --features nesting=1 \
        --unprivileged 1 \
        --onboot 1 \
        --start 1"

    # Ejecutar el comando
    if eval $CREATE_CMD; then
        show_success "$TXT_CONTAINER_CREATED: $CTID"
    else
        show_error "$TXT_CONTAINER_ERROR"
        exit 1
    fi

    # Esperar a que el contenedor esté completamente iniciado
    show_info "$TXT_WAITING_CONTAINER"
    sleep 10

    # Verificar que el contenedor está corriendo
    if pct status $CTID | grep -q "running"; then
        show_success "$TXT_CONTAINER_RUNNING: $CTID"
    else
        show_error "$TXT_CONTAINER_ERROR"
        pct status $CTID
        exit 1
    fi
}

# Configurar mapeo de carpetas si se solicitó
configure_host_mapping() {
    if [[ "$MAP_HOST_FOLDER" =~ ^[$TXT_YES_OPTS]$ ]]; then
        show_info "$TXT_MAPPING_CONFIG: $HOST_PATH -> $MOUNT_POINT"

        # Detener el contenedor temporalmente
        pct stop $CTID

        # Agregar el punto de montaje
        pct set $CTID -mp0 "$HOST_PATH,mp=$MOUNT_POINT"

        # Reiniciar el contenedor
        pct start $CTID

        # Esperar a que esté listo
        sleep 10

        show_success "$TXT_MAPPING_DONE"
    fi
}

# Configurar autologin
configure_autologin() {
    show_info "$TXT_AUTOLOGIN_CONFIG..."

    # Configurar autologin en el contenedor
    pct exec $CTID -- bash -c "
        # Configurar autologin para consola
        mkdir -p /etc/systemd/system/console-getty.service.d/
        cat > /etc/systemd/system/console-getty.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

        # Configurar autologin para tty1
        mkdir -p /etc/systemd/system/getty@tty1.service.d/
        cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

        # Recargar systemd
        systemctl daemon-reload
    "

    show_success "$TXT_AUTOLOGIN_DONE"
}

# Instalar y configurar Samba
install_samba() {
    show_info "$TXT_SAMBA_INSTALL..."

    # Descargar el script de Samba al contenedor
    pct exec $CTID -- bash -c "
        curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/samba.sh -o /tmp/samba.sh ||
        wget -O /tmp/samba.sh https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/samba.sh
    " 2>/dev/null || {
        show_warning "Could not download from GitHub, using local version..."

        # Si no se puede descargar, crear el script localmente
        create_local_samba_script
    }

    # Hacer el script ejecutable
    pct exec $CTID -- chmod +x /tmp/samba.sh

    show_info "Running automated Samba installation..."

    # Ejecutar el script de Samba con configuración automática
    pct exec $CTID -- bash -c "
        export DEBIAN_FRONTEND=noninteractive

        # Ejecutar en modo automático
        /tmp/samba.sh --auto || {
            echo 'Error installing Samba'
            exit 1
        }
    "

    show_success "$TXT_SAMBA_DONE"
}

# Crear script local de Samba si no se puede descargar
create_local_samba_script() {
    show_info "Creating local Samba script..."

    # Copiar el contenido del script principal al contenedor
    pct exec $CTID -- bash -c "
        cat > /tmp/samba.sh << 'SAMBA_SCRIPT_EOF'
#!/bin/bash
# Basic Samba installation script
set -e

echo '[INFO] Installing Samba...'
apt update
apt install -y samba samba-common-bin

echo '[INFO] Configuring Samba...'
cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

cat > /etc/samba/smb.conf << 'SMB_CONF_EOF'
[global]
    workgroup = WORKGROUP
    server string = Samba Server LXC
    security = user
    map to guest = never
    log file = /var/log/samba/log.%m
    max log size = 1000

[public]
    path = /srv/samba/public
    browsable = yes
    writable = yes
    guest ok = yes
    read only = no
    public = yes
    create mask = 0666
    directory mask = 0777

SMB_CONF_EOF

# Create directories
mkdir -p /srv/samba/public
chmod 777 /srv/samba/public

# Start services
systemctl enable smbd nmbd
systemctl start smbd nmbd

echo '[OK] Samba installed successfully'
SAMBA_SCRIPT_EOF
    "
}

# Configurar recursos compartidos adicionales
configure_additional_shares() {
    if [[ "$MAP_HOST_FOLDER" =~ ^[$TXT_YES_OPTS]$ ]]; then
        show_info "Adding shared resource for $MOUNT_POINT..."

        # Agregar configuración del recurso compartido del host
        pct exec $CTID -- bash -c "
            cat >> /etc/samba/smb.conf << 'EOF'

[host-data]
    comment = Proxmox Host Data
    path = $MOUNT_POINT
    browsable = yes
    writable = yes
    guest ok = yes
    read only = no
    public = yes
    create mask = 0666
    directory mask = 0777

EOF

            # Reiniciar Samba para aplicar cambios
            systemctl restart smbd nmbd
        "

        show_success "Host shared resource configured"
    fi
}

# Obtener información del contenedor
get_container_info() {
    show_info "$TXT_GETTING_IP"

    # Obtener IP del contenedor
    CONTAINER_IP=""
    for i in {1..30}; do
        CONTAINER_IP=$(pct exec $CTID -- hostname -I 2>/dev/null | awk '{print $1}' || true)
        if [ -n "$CONTAINER_IP" ]; then
            break
        fi
        show_info "Waiting for container IP... ($i/30)"
        sleep 2
    done

    if [ -z "$CONTAINER_IP" ]; then
        show_warning "$TXT_IP_NOT_FOUND"
        CONTAINER_IP="[CONTAINER_IP]"
    fi

    show_success "$TXT_IP_FOUND: $CONTAINER_IP"
}

# Mostrar información final
show_final_info() {
    echo ""
    echo -e "${GREEN}=================================================================${NC}"
    echo -e "${GREEN}  $TXT_INSTALLATION_COMPLETE${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    echo ""

    echo -e "${GREEN}[OK] $TXT_SERVER_CREATED${NC}"
    echo ""

    echo -e "${CYAN}$TXT_CONTAINER_INFO${NC}"
    echo ""
    echo "   Container"
    echo "   |-- ID: ${GREEN}$CTID${NC}"
    echo "   |-- Hostname: ${GREEN}$HOSTNAME${NC}"
    echo "   |-- IP: ${GREEN}$CONTAINER_IP${NC}"
    echo "   \`-- Password: ${YELLOW}$PASSWORD${NC}"
    echo ""

    echo -e "${CYAN}$TXT_HOW_TO_CONNECT${NC}"
    echo ""
    echo "   |-- $TXT_FROM_WINDOWS: ${GREEN}\\\\$CONTAINER_IP${NC}"
    echo "   |-- $TXT_FROM_LINUX: ${GREEN}smb://$CONTAINER_IP${NC}"
    echo "   \`-- $TXT_FROM_MOBILE: ${GREEN}smb://$CONTAINER_IP${NC}"
    echo ""

    echo -e "${CYAN}$TXT_SHARED_RESOURCES${NC}"
    echo ""
    echo "   |-- ${GREEN}public${NC} - $TXT_PUBLIC_ACCESS"
    if [[ "$MAP_HOST_FOLDER" =~ ^[$TXT_YES_OPTS]$ ]]; then
        echo "   \`-- ${GREEN}host-data${NC} - $TXT_HOST_DATA ($HOST_PATH)"
    fi
    echo ""

    echo -e "${CYAN}$TXT_CONTAINER_MANAGEMENT${NC}"
    echo ""
    echo "   |-- $TXT_ACCESS_CONSOLE: ${GREEN}pct enter $CTID${NC}"
    echo "   |-- $TXT_RESTART: ${GREEN}pct reboot $CTID${NC}"
    echo "   |-- $TXT_STOP: ${GREEN}pct stop $CTID${NC}"
    echo "   |-- $TXT_START: ${GREEN}pct start $CTID${NC}"
    echo "   \`-- $TXT_STATUS: ${GREEN}pct status $CTID${NC}"
    echo ""

    echo -e "${CYAN}$TXT_TOOLS_CONTAINER${NC}"
    echo ""
    echo "   |-- $TXT_VIEW_INFO: ${GREEN}samba-info${NC}"
    echo "   |-- $TXT_MANAGE_SAMBA: ${GREEN}/opt/samba/samba-manager.sh${NC}"
    echo "   \`-- $TXT_CREATE_BACKUP: ${GREEN}/opt/samba/backup-config.sh${NC}"
    echo ""

    show_success "$TXT_READY"

    # Opción para acceder directamente al contenedor
    echo ""
    read_input "$TXT_ACCESS_NOW" "y" "ACCESS_CONTAINER" "false"

    if [[ "$ACCESS_CONTAINER" =~ ^[$TXT_YES_OPTS]$ ]]; then
        show_info "$TXT_ACCESSING"
        show_info "$TXT_EXIT_MSG"
        echo ""
        exec pct enter $CTID
    fi
}

# Función de limpieza en caso de error
cleanup_on_error() {
    if [ -n "$CTID" ] && pct list | grep -q "^$CTID "; then
        show_warning "Cleaning up container $CTID due to error..."
        pct stop $CTID 2>/dev/null || true
        pct destroy $CTID 2>/dev/null || true
        show_info "Container $CTID removed"
    fi
}

# Configurar trap para limpieza en caso de error
trap cleanup_on_error ERR

# Función principal
main() {
    # Selección de idioma primero (antes de limpiar pantalla)
    select_language
    set_language_texts

    # Mostrar header
    show_header

    # Verificaciones iniciales
    check_root
    check_proxmox

    # Proceso de instalación
    get_user_input
    find_best_template
    check_storage
    check_bridge
    check_ctid
    show_configuration_summary
    create_container
    configure_autologin
    configure_host_mapping
    install_samba
    configure_additional_shares
    get_container_info

    # Información final
    show_final_info
}

# Ejecutar función principal
main "$@" 