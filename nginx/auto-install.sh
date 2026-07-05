#!/bin/bash

# Nginx + PHP Web Server - Instalador Automatico para Proxmox LXC
# Desarrollado para la comunidad de Proxmox
# Hecho en Puerto Rico

# Silenciar warnings de locale
export LC_ALL=C
export LANG=C

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

SCRIPT_VERSION="3.0"
INSTALL_PHP="no"
PHP_VERSION="8.2"

# Colores para output
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
# FUNCIONES DE UTILIDAD
# =============================================================================

show_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
show_success() { echo -e "${GREEN}[OK]${NC} $1"; }
show_error() { echo -e "${RED}[ERROR]${NC} $1"; }
show_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
show_step_msg() { echo -e "${PURPLE}[STEP]${NC} $1"; }

show_step() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

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

# =============================================================================
# SELECCION DE IDIOMA
# =============================================================================

select_language() {
    clear
    echo -e "${CYAN}"
    echo "=============================================================="
    echo "       NGINX + PHP WEB SERVER - PROXMOX LXC INSTALLER         "
    echo "=============================================================="
    echo -e "${NC}"
    echo ""
    echo "Select language / Selecciona idioma:"
    echo ""
    echo "   1) English"
    echo "   2) Espanol"
    echo ""
    echo -ne "${GREEN}>${NC} Option/Opcion [1]: "
    read LANG_CHOICE
    LANG_CHOICE=${LANG_CHOICE:-1}

    if [[ "$LANG_CHOICE" == "2" ]]; then
        set_spanish
    else
        set_english
    fi
}

set_english() {
    TXT_STEP1="STEP 1/5: Verifying Environment"
    TXT_STEP2="STEP 2/5: Container Configuration"
    TXT_STEP3="STEP 3/5: Resources and Network"
    TXT_STEP4="STEP 4/5: PHP Configuration"
    TXT_STEP5="STEP 5/5: Confirmation"
    TXT_VERIFYING_PROXMOX="Verifying Proxmox environment..."
    TXT_PROXMOX_OK="Proxmox environment verified"
    TXT_NOT_PROXMOX="This script must be run on a Proxmox VE server"
    TXT_CMD_NOT_FOUND="Command not found"
    TXT_DETECTING_TEMPLATES="Detecting available LXC templates..."
    TXT_TEMPLATE_FOUND="Template found"
    TXT_DOWNLOADING_TEMPLATE="Downloading template..."
    TXT_TEMPLATE_DOWNLOADED="Template downloaded"
    TXT_NO_TEMPLATES="No compatible templates found (Ubuntu 22.04/24.04 or Debian 12/13)"
    TXT_GETTING_ID="Getting available container ID..."
    TXT_EXISTING_IDS="Existing IDs found"
    TXT_ID_ASSIGNED="Container ID assigned"
    TXT_NO_ID_AVAILABLE="No available container ID found (100-999)"
    TXT_CONTAINER_CONFIG="Container Configuration"
    TXT_CONTAINER_ID="Container ID"
    TXT_CONTAINER_NAME="Container Name"
    TXT_ROOT_PASSWORD="Root Password"
    TXT_MEMORY="Memory (MB)"
    TXT_DISK="Disk (GB)"
    TXT_CPU_CORES="CPU Cores"
    TXT_STORAGE="Storage"
    TXT_NETWORK_BRIDGE="Network Bridge"
    TXT_REQUIRED="This field is required"
    TXT_PASSWORD_SHORT="Password must be at least 5 characters (Proxmox requirement)"
    TXT_AVAILABLE_STORAGES="Available storages:"
    TXT_AVAILABLE_BRIDGES="Available network bridges:"
    TXT_CONFIRM_TITLE="Configuration Summary"
    TXT_CONFIRM_CONTINUE="Continue with installation?"
    TXT_CONFIRM_YES="Y/n"
    TXT_CANCELLED="Installation cancelled"
    TXT_CREATING_CONTAINER="Creating LXC container..."
    TXT_CONTAINER_CREATED="Container created successfully"
    TXT_CONTAINER_ERROR="Error creating container"
    TXT_WAITING_START="Waiting for container to start..."
    TXT_CONTAINER_STARTED="Container started successfully"
    TXT_CONTAINER_NOT_STARTED="Container could not start"
    TXT_INSTALLING_NGINX="Installing and configuring Nginx..."
    TXT_NGINX_INSTALLED="Nginx installed and configured"
    TXT_NGINX_ERROR="Error during Nginx installation"
    TXT_INSTALLING_TOOLS="Installing management tools..."
    TXT_TOOLS_INSTALLED="Management tools installed"
    TXT_TOOLS_ERROR="Error installing tools, installing basic version..."
    TXT_GETTING_INFO="Getting container information..."
    TXT_INFO_OBTAINED="Container information obtained"
    TXT_IP_NOT_FOUND="Could not get container IP"
    TXT_INSTALL_COMPLETE="INSTALLATION COMPLETED!"
    TXT_SUMMARY="Installation Summary"
    TXT_WEB_ACCESS="Web Server Access"
    TXT_CONTAINER_ACCESS="Container Access"
    TXT_PROXMOX_CONSOLE="Proxmox Console"
    TXT_NEXT_STEPS="Next Steps"
    TXT_DOCUMENTATION="Documentation"
    TXT_THANKS="Thank you for using nginx-server!"
    TXT_DEVELOPED="Developed for the Proxmox community"
    TXT_MADE_IN="Made in Puerto Rico"
    TXT_FEATURES="Features"
    TXT_AUTOBOOT="Autoboot enabled"
    TXT_AUTOLOGIN="Autologin configured"
    TXT_SERVICE_RUNNING="Service running"
    # PHP texts
    TXT_PHP_CONFIG="PHP Configuration"
    TXT_INSTALL_PHP="Install PHP?"
    TXT_PHP_YES_NO="y/N"
    TXT_PHP_VERSION="PHP Version"
    TXT_PHP_AVAILABLE_VERSIONS="Available PHP versions:"
    TXT_INSTALLING_PHP="Installing and configuring PHP-FPM..."
    TXT_PHP_INSTALLED="PHP-FPM installed and configured"
    TXT_PHP_ERROR="Error during PHP installation"
    TXT_PHP_MODULES="PHP Modules"
    TXT_PHP_TEST_PAGE="PHP Test Page"
    TXT_PHP_COMMANDS="PHP Commands"
    TXT_PHP_NOT_INSTALLED="PHP not installed (Nginx only)"
    TXT_PHP_RECOMMENDED="Recommended for most web applications"
    TXT_INSTALLING_COMPOSER="Installing Composer..."
    TXT_COMPOSER_INSTALLED="Composer installed"
}

set_spanish() {
    TXT_STEP1="PASO 1/5: Verificando Entorno"
    TXT_STEP2="PASO 2/5: Configuracion del Contenedor"
    TXT_STEP3="PASO 3/5: Recursos y Red"
    TXT_STEP4="PASO 4/5: Configuracion de PHP"
    TXT_STEP5="PASO 5/5: Confirmacion"
    TXT_VERIFYING_PROXMOX="Verificando entorno Proxmox..."
    TXT_PROXMOX_OK="Entorno Proxmox verificado"
    TXT_NOT_PROXMOX="Este script debe ejecutarse en un servidor Proxmox VE"
    TXT_CMD_NOT_FOUND="Comando no encontrado"
    TXT_DETECTING_TEMPLATES="Detectando templates LXC disponibles..."
    TXT_TEMPLATE_FOUND="Template encontrado"
    TXT_DOWNLOADING_TEMPLATE="Descargando template..."
    TXT_TEMPLATE_DOWNLOADED="Template descargado"
    TXT_NO_TEMPLATES="No se encontraron templates compatibles (Ubuntu 22.04/24.04 o Debian 12/13)"
    TXT_GETTING_ID="Obteniendo ID de contenedor disponible..."
    TXT_EXISTING_IDS="IDs existentes encontrados"
    TXT_ID_ASSIGNED="ID de contenedor asignado"
    TXT_NO_ID_AVAILABLE="No se encontro ID de contenedor disponible (100-999)"
    TXT_CONTAINER_CONFIG="Configuracion del Contenedor"
    TXT_CONTAINER_ID="ID del Contenedor"
    TXT_CONTAINER_NAME="Nombre del Contenedor"
    TXT_ROOT_PASSWORD="Contrasena Root"
    TXT_MEMORY="Memoria (MB)"
    TXT_DISK="Disco (GB)"
    TXT_CPU_CORES="Nucleos CPU"
    TXT_STORAGE="Almacenamiento"
    TXT_NETWORK_BRIDGE="Bridge de Red"
    TXT_REQUIRED="Este campo es obligatorio"
    TXT_PASSWORD_SHORT="La contrasena debe tener al menos 5 caracteres (requisito de Proxmox)"
    TXT_AVAILABLE_STORAGES="Almacenamientos disponibles:"
    TXT_AVAILABLE_BRIDGES="Bridges de red disponibles:"
    TXT_CONFIRM_TITLE="Resumen de Configuracion"
    TXT_CONFIRM_CONTINUE="Continuar con la instalacion?"
    TXT_CONFIRM_YES="S/n"
    TXT_CANCELLED="Instalacion cancelada"
    TXT_CREATING_CONTAINER="Creando contenedor LXC..."
    TXT_CONTAINER_CREATED="Contenedor creado exitosamente"
    TXT_CONTAINER_ERROR="Error al crear el contenedor"
    TXT_WAITING_START="Esperando a que el contenedor inicie..."
    TXT_CONTAINER_STARTED="Contenedor iniciado correctamente"
    TXT_CONTAINER_NOT_STARTED="El contenedor no pudo iniciarse"
    TXT_INSTALLING_NGINX="Instalando y configurando Nginx..."
    TXT_NGINX_INSTALLED="Nginx instalado y configurado"
    TXT_NGINX_ERROR="Error durante la instalacion de Nginx"
    TXT_INSTALLING_TOOLS="Instalando herramientas de gestion..."
    TXT_TOOLS_INSTALLED="Herramientas de gestion instaladas"
    TXT_TOOLS_ERROR="Error instalando herramientas, instalando version basica..."
    TXT_GETTING_INFO="Obteniendo informacion del contenedor..."
    TXT_INFO_OBTAINED="Informacion del contenedor obtenida"
    TXT_IP_NOT_FOUND="No se pudo obtener la IP del contenedor"
    TXT_INSTALL_COMPLETE="INSTALACION COMPLETADA!"
    TXT_SUMMARY="Resumen de la Instalacion"
    TXT_WEB_ACCESS="Acceso al Servidor Web"
    TXT_CONTAINER_ACCESS="Acceso al Contenedor"
    TXT_PROXMOX_CONSOLE="Consola Proxmox"
    TXT_NEXT_STEPS="Proximos Pasos"
    TXT_DOCUMENTATION="Documentacion"
    TXT_THANKS="Gracias por usar nginx-server!"
    TXT_DEVELOPED="Desarrollado para la comunidad de Proxmox"
    TXT_MADE_IN="Hecho en Puerto Rico"
    TXT_FEATURES="Caracteristicas"
    TXT_AUTOBOOT="Autoarranque habilitado"
    TXT_AUTOLOGIN="Autologin configurado"
    TXT_SERVICE_RUNNING="Servicio funcionando"
    # PHP texts
    TXT_PHP_CONFIG="Configuracion de PHP"
    TXT_INSTALL_PHP="Instalar PHP?"
    TXT_PHP_YES_NO="s/N"
    TXT_PHP_VERSION="Version de PHP"
    TXT_PHP_AVAILABLE_VERSIONS="Versiones de PHP disponibles:"
    TXT_INSTALLING_PHP="Instalando y configurando PHP-FPM..."
    TXT_PHP_INSTALLED="PHP-FPM instalado y configurado"
    TXT_PHP_ERROR="Error durante la instalacion de PHP"
    TXT_PHP_MODULES="Modulos PHP"
    TXT_PHP_TEST_PAGE="Pagina de prueba PHP"
    TXT_PHP_COMMANDS="Comandos PHP"
    TXT_PHP_NOT_INSTALLED="PHP no instalado (solo Nginx)"
    TXT_PHP_RECOMMENDED="Recomendado para la mayoria de aplicaciones web"
    TXT_INSTALLING_COMPOSER="Instalando Composer..."
    TXT_COMPOSER_INSTALLED="Composer instalado"
}

# =============================================================================
# BANNER DE BIENVENIDA
# =============================================================================

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "||                                                              ||"
    echo "||          NGINX + PHP WEB SERVER - PROXMOX LXC                ||"
    echo "||                                                              ||"
    echo "||               Automatic Installer v${SCRIPT_VERSION}                    ||"
    echo "||                                                              ||"
    echo "||              $TXT_DEVELOPED              ||"
    echo "||                   $TXT_MADE_IN                    ||"
    echo "||                                                              ||"
    echo "=================================================================="
    echo -e "${NC}"
}

# =============================================================================
# VERIFICACIONES
# =============================================================================

check_proxmox() {
    show_step_msg "$TXT_VERIFYING_PROXMOX"

    if ! command -v pct &> /dev/null; then
        show_error "$TXT_NOT_PROXMOX"
        show_error "'pct' - $TXT_CMD_NOT_FOUND"
        exit 1
    fi

    if ! command -v pvesh &> /dev/null; then
        show_error "$TXT_NOT_PROXMOX"
        show_error "'pvesh' - $TXT_CMD_NOT_FOUND"
        exit 1
    fi

    show_success "$TXT_PROXMOX_OK"
}

detect_templates() {
    show_step_msg "$TXT_DETECTING_TEMPLATES"

    # Buscar templates disponibles (preferir versiones mas recientes)
    UBUNTU_24_TEMPLATE=$(pveam available | grep "ubuntu-24.04" | head -1 | awk '{print $2}')
    UBUNTU_22_TEMPLATE=$(pveam available | grep "ubuntu-22.04" | head -1 | awk '{print $2}')
    DEBIAN_13_TEMPLATE=$(pveam available | grep "debian-13" | head -1 | awk '{print $2}')
    DEBIAN_12_TEMPLATE=$(pveam available | grep "debian-12" | head -1 | awk '{print $2}')

    # Buscar templates ya descargados
    DOWNLOADED_UBUNTU_24=$(pveam list local | grep "ubuntu-24.04" | head -1 | awk '{print $1}')
    DOWNLOADED_UBUNTU_22=$(pveam list local | grep "ubuntu-22.04" | head -1 | awk '{print $1}')
    DOWNLOADED_DEBIAN_13=$(pveam list local | grep "debian-13" | head -1 | awk '{print $1}')
    DOWNLOADED_DEBIAN_12=$(pveam list local | grep "debian-12" | head -1 | awk '{print $1}')

    # Prioridad: Ubuntu 24.04 > Ubuntu 22.04 > Debian 13 > Debian 12
    if [ -n "$DOWNLOADED_UBUNTU_24" ]; then
        SELECTED_TEMPLATE="$DOWNLOADED_UBUNTU_24"
        TEMPLATE_TYPE="ubuntu"
        show_success "$TXT_TEMPLATE_FOUND: Ubuntu 24.04"
    elif [ -n "$DOWNLOADED_UBUNTU_22" ]; then
        SELECTED_TEMPLATE="$DOWNLOADED_UBUNTU_22"
        TEMPLATE_TYPE="ubuntu"
        show_success "$TXT_TEMPLATE_FOUND: Ubuntu 22.04"
    elif [ -n "$DOWNLOADED_DEBIAN_13" ]; then
        SELECTED_TEMPLATE="$DOWNLOADED_DEBIAN_13"
        TEMPLATE_TYPE="debian"
        show_success "$TXT_TEMPLATE_FOUND: Debian 13"
    elif [ -n "$DOWNLOADED_DEBIAN_12" ]; then
        SELECTED_TEMPLATE="$DOWNLOADED_DEBIAN_12"
        TEMPLATE_TYPE="debian"
        show_success "$TXT_TEMPLATE_FOUND: Debian 12"
    elif [ -n "$UBUNTU_24_TEMPLATE" ]; then
        SELECTED_TEMPLATE="$UBUNTU_24_TEMPLATE"
        TEMPLATE_TYPE="ubuntu"
        show_info "$TXT_DOWNLOADING_TEMPLATE Ubuntu 24.04..."
        pveam download local "$UBUNTU_24_TEMPLATE"
        show_success "$TXT_TEMPLATE_DOWNLOADED: Ubuntu 24.04"
    elif [ -n "$UBUNTU_22_TEMPLATE" ]; then
        SELECTED_TEMPLATE="$UBUNTU_22_TEMPLATE"
        TEMPLATE_TYPE="ubuntu"
        show_info "$TXT_DOWNLOADING_TEMPLATE Ubuntu 22.04..."
        pveam download local "$UBUNTU_22_TEMPLATE"
        show_success "$TXT_TEMPLATE_DOWNLOADED: Ubuntu 22.04"
    elif [ -n "$DEBIAN_13_TEMPLATE" ]; then
        SELECTED_TEMPLATE="$DEBIAN_13_TEMPLATE"
        TEMPLATE_TYPE="debian"
        show_info "$TXT_DOWNLOADING_TEMPLATE Debian 13..."
        pveam download local "$DEBIAN_13_TEMPLATE"
        show_success "$TXT_TEMPLATE_DOWNLOADED: Debian 13"
    elif [ -n "$DEBIAN_12_TEMPLATE" ]; then
        SELECTED_TEMPLATE="$DEBIAN_12_TEMPLATE"
        TEMPLATE_TYPE="debian"
        show_info "$TXT_DOWNLOADING_TEMPLATE Debian 12..."
        pveam download local "$DEBIAN_12_TEMPLATE"
        show_success "$TXT_TEMPLATE_DOWNLOADED: Debian 12"
    else
        show_error "$TXT_NO_TEMPLATES"
        exit 1
    fi
}

# Obtener siguiente ID disponible
get_next_vmid() {
    show_step_msg "$TXT_GETTING_ID"

    # Obtener lista de IDs existentes usando multiples metodos
    EXISTING_IDS=""

    # Metodo 1: pct list (contenedores)
    if command -v pct &> /dev/null; then
        PCT_IDS=$(pct list 2>/dev/null | awk 'NR>1 {print $1}' | grep -E '^[0-9]+$' || true)
        EXISTING_IDS="$EXISTING_IDS $PCT_IDS"
    fi

    # Metodo 2: qm list (VMs)
    if command -v qm &> /dev/null; then
        QM_IDS=$(qm list 2>/dev/null | awk 'NR>1 {print $1}' | grep -E '^[0-9]+$' || true)
        EXISTING_IDS="$EXISTING_IDS $QM_IDS"
    fi

    # Metodo 3: pvesh (si esta disponible)
    if command -v pvesh &> /dev/null; then
        PVESH_IDS=$(pvesh get /cluster/resources --type vm 2>/dev/null | awk 'NR>1 {print $2}' | grep -E '^[0-9]+$' || true)
        EXISTING_IDS="$EXISTING_IDS $PVESH_IDS"
    fi

    # Limpiar y ordenar IDs
    EXISTING_IDS=$(echo $EXISTING_IDS | tr ' ' '\n' | sort -nu | tr '\n' ' ')

    show_info "$TXT_EXISTING_IDS: $EXISTING_IDS"

    # Buscar el proximo ID disponible
    CONTAINER_ID=""
    for i in {100..999}; do
        if ! echo " $EXISTING_IDS " | grep -q " $i "; then
            CONTAINER_ID=$i
            break
        fi
    done

    if [ -z "$CONTAINER_ID" ]; then
        show_error "$TXT_NO_ID_AVAILABLE"
        show_error "IDs existentes: $EXISTING_IDS"
        exit 1
    fi

    show_success "$TXT_ID_ASSIGNED: $CONTAINER_ID"
}

# =============================================================================
# CONFIGURACION DEL CONTENEDOR
# =============================================================================

configure_container() {
    show_step "$TXT_STEP2"

    # Valores por defecto
    DEFAULT_NAME="nginx-server"
    DEFAULT_PASSWORD="nginx123"
    DEFAULT_MEMORY="1024"
    DEFAULT_DISK="8"
    DEFAULT_CORES="2"
    DEFAULT_STORAGE="local-lvm"

    # Detectar bridge de red
    DEFAULT_BRIDGE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -z "$DEFAULT_BRIDGE" ]; then
        DEFAULT_BRIDGE="vmbr0"
    fi

    echo -e "${WHITE}$TXT_CONTAINER_CONFIG${NC}"
    echo ""

    read_input "$TXT_CONTAINER_ID" "$CONTAINER_ID" "CONTAINER_ID" "true"
    read_input "$TXT_CONTAINER_NAME" "$DEFAULT_NAME" "CONTAINER_NAME" "true"
    read_input "$TXT_ROOT_PASSWORD" "$DEFAULT_PASSWORD" "CONTAINER_PASSWORD" "true"

    # Validar password minimo 5 caracteres
    while [ ${#CONTAINER_PASSWORD} -lt 5 ]; do
        show_error "$TXT_PASSWORD_SHORT"
        read_input "$TXT_ROOT_PASSWORD" "$DEFAULT_PASSWORD" "CONTAINER_PASSWORD" "true"
    done

    # Verificar que ID no existe
    if pct status $CONTAINER_ID &> /dev/null; then
        show_error "Container ID $CONTAINER_ID already exists / El ID $CONTAINER_ID ya existe"
        exit 1
    fi
}

configure_resources() {
    show_step "$TXT_STEP3"

    echo -e "${WHITE}$TXT_AVAILABLE_STORAGES${NC}"
    pvesm status 2>/dev/null | grep -E "active" | awk '{print "   - " $1}'
    echo ""

    read_input "$TXT_STORAGE" "$DEFAULT_STORAGE" "CONTAINER_STORAGE" "true"

    echo ""
    read_input "$TXT_MEMORY" "$DEFAULT_MEMORY" "CONTAINER_MEMORY" "true"
    read_input "$TXT_DISK" "$DEFAULT_DISK" "CONTAINER_DISK" "true"
    read_input "$TXT_CPU_CORES" "$DEFAULT_CORES" "CONTAINER_CORES" "true"

    echo ""
    echo -e "${WHITE}$TXT_AVAILABLE_BRIDGES${NC}"
    ip link show type bridge 2>/dev/null | grep -E "^[0-9]" | awk -F: '{print "   - " $2}' | tr -d ' '
    echo ""

    read_input "$TXT_NETWORK_BRIDGE" "$DEFAULT_BRIDGE" "NETWORK_BRIDGE" "true"
}

# =============================================================================
# CONFIGURACION DE PHP
# =============================================================================

configure_php() {
    show_step "$TXT_STEP4"

    echo -e "${WHITE}$TXT_PHP_CONFIG${NC}"
    echo ""
    echo -e "${CYAN}$TXT_PHP_RECOMMENDED${NC}"
    echo ""

    echo -ne "${GREEN}>${NC} $TXT_INSTALL_PHP [$TXT_PHP_YES_NO]: "
    read php_choice

    if [[ "$php_choice" =~ ^[SsYy]$ ]]; then
        INSTALL_PHP="yes"

        echo ""
        echo -e "${WHITE}$TXT_PHP_AVAILABLE_VERSIONS${NC}"
        echo "   1) PHP 8.1 (LTS - stable)"
        echo "   2) PHP 8.2 (recommended)"
        echo "   3) PHP 8.3 (latest)"
        echo ""

        echo -ne "${GREEN}>${NC} $TXT_PHP_VERSION [2]: "
        read php_ver_choice
        php_ver_choice=${php_ver_choice:-2}

        case "$php_ver_choice" in
            1) PHP_VERSION="8.1" ;;
            3) PHP_VERSION="8.3" ;;
            *) PHP_VERSION="8.2" ;;
        esac

        show_success "PHP $PHP_VERSION selected / seleccionado"
    else
        INSTALL_PHP="no"
        show_info "$TXT_PHP_NOT_INSTALLED"
    fi
}

# =============================================================================
# CONFIRMACION
# =============================================================================

show_confirmation() {
    show_step "$TXT_STEP5"

    echo -e "${WHITE}$TXT_CONFIRM_TITLE${NC}"
    echo ""
    echo "   Container"
    echo "   ├─ ID: $CONTAINER_ID"
    echo "   ├─ Name: $CONTAINER_NAME"
    echo "   ├─ Password: $CONTAINER_PASSWORD"
    echo "   ├─ Template: $SELECTED_TEMPLATE"
    echo "   └─ Storage: $CONTAINER_STORAGE"
    echo ""
    echo "   Resources"
    echo "   ├─ Memory: ${CONTAINER_MEMORY}MB"
    echo "   ├─ Disk: ${CONTAINER_DISK}GB"
    echo "   └─ CPU: $CONTAINER_CORES cores"
    echo ""
    echo "   Network"
    echo "   └─ Bridge: $NETWORK_BRIDGE (DHCP)"
    echo ""
    echo "   Software"
    echo "   ├─ Nginx: yes"
    if [ "$INSTALL_PHP" = "yes" ]; then
        echo "   ├─ PHP: $PHP_VERSION (PHP-FPM)"
        echo "   └─ Composer: yes"
    else
        echo "   └─ PHP: no"
    fi
    echo ""

    echo -ne "${GREEN}>${NC} $TXT_CONFIRM_CONTINUE [$TXT_CONFIRM_YES]: "
    read confirm
    confirm=${confirm:-Y}

    if [[ ! "$confirm" =~ ^[SsYy]$ ]]; then
        show_warning "$TXT_CANCELLED"
        exit 0
    fi
}

# =============================================================================
# CREACION E INSTALACION
# =============================================================================

# Crear contenedor LXC
create_container() {
    show_step_msg "$TXT_CREATING_CONTAINER"

    # Crear el contenedor
    pct create $CONTAINER_ID \
        $SELECTED_TEMPLATE \
        --hostname $CONTAINER_NAME \
        --memory $CONTAINER_MEMORY \
        --rootfs $CONTAINER_STORAGE:$CONTAINER_DISK \
        --cores $CONTAINER_CORES \
        --net0 name=eth0,bridge=$NETWORK_BRIDGE,ip=dhcp \
        --password $CONTAINER_PASSWORD \
        --unprivileged 1 \
        --onboot 1 \
        --start 1 \
        --features nesting=1 \
        --description "Servidor web Nginx + PHP automatizado - Creado por nginx-server installer v${SCRIPT_VERSION}"

    if [ $? -eq 0 ]; then
        show_success "$TXT_CONTAINER_CREATED"
    else
        show_error "$TXT_CONTAINER_ERROR"
        exit 1
    fi

    # Esperar a que el contenedor inicie
    show_info "$TXT_WAITING_START"
    sleep 10

    # Verificar que el contenedor esta corriendo
    if pct status $CONTAINER_ID | grep -q "running"; then
        show_success "$TXT_CONTAINER_STARTED"
    else
        show_error "$TXT_CONTAINER_NOT_STARTED"
        exit 1
    fi
}

# Instalar nginx en el contenedor
install_nginx() {
    show_step_msg "$TXT_INSTALLING_NGINX"

    # Determinar si se instalara PHP
    local INSTALL_PHP_FLAG="$INSTALL_PHP"
    local PHP_VER="$PHP_VERSION"

    # Crear script de instalacion temporal
    cat > /tmp/nginx-install.sh << EOFSCRIPT
#!/bin/bash

# Variables pasadas desde el host
INSTALL_PHP="$INSTALL_PHP_FLAG"
PHP_VERSION="$PHP_VER"

# Actualizar sistema
apt update && apt upgrade -y

# Instalar paquetes base necesarios
apt install -y \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    fail2ban \
    curl \
    wget \
    git \
    nano \
    htop \
    tree \
    unzip \
    logrotate \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg

# Habilitar y iniciar servicios
systemctl enable nginx
systemctl start nginx
systemctl enable fail2ban
systemctl start fail2ban

# Configurar firewall
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Crear directorios necesarios
mkdir -p /var/www/html
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
mkdir -p /var/log/nginx
mkdir -p /opt/nginx-server

# Configurar permisos
chown -R www-data:www-data /var/www/
chmod -R 755 /var/www/

echo "Instalacion de nginx completada"
EOFSCRIPT

    # Copiar script al contenedor y ejecutarlo
    pct push $CONTAINER_ID /tmp/nginx-install.sh /tmp/nginx-install.sh
    pct exec $CONTAINER_ID -- chmod +x /tmp/nginx-install.sh
    pct exec $CONTAINER_ID -- /tmp/nginx-install.sh

    if [ $? -eq 0 ]; then
        show_success "$TXT_NGINX_INSTALLED"
    else
        show_error "$TXT_NGINX_ERROR"
        exit 1
    fi

    # Limpiar archivo temporal
    rm -f /tmp/nginx-install.sh
}

# Instalar PHP en el contenedor
install_php() {
    if [ "$INSTALL_PHP" != "yes" ]; then
        return 0
    fi

    show_step_msg "$TXT_INSTALLING_PHP"

    local PHP_VER="$PHP_VERSION"

    # Crear script de instalacion de PHP
    cat > /tmp/php-install.sh << EOFPHP
#!/bin/bash

PHP_VERSION="$PHP_VER"

# Detectar distribucion
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=\$ID
fi

# Agregar repositorio de PHP si es necesario (para versiones especificas)
if [ "\$DISTRO" = "ubuntu" ]; then
    add-apt-repository -y ppa:ondrej/php
    apt update
elif [ "\$DISTRO" = "debian" ]; then
    # Para Debian, agregar repositorio sury.org
    curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    dpkg -i /tmp/debsuryorg-archive-keyring.deb
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ \$(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    apt update
fi

# Instalar PHP-FPM y modulos esenciales
apt install -y \
    php\${PHP_VERSION}-fpm \
    php\${PHP_VERSION}-cli \
    php\${PHP_VERSION}-common \
    php\${PHP_VERSION}-mysql \
    php\${PHP_VERSION}-pgsql \
    php\${PHP_VERSION}-sqlite3 \
    php\${PHP_VERSION}-curl \
    php\${PHP_VERSION}-gd \
    php\${PHP_VERSION}-mbstring \
    php\${PHP_VERSION}-xml \
    php\${PHP_VERSION}-zip \
    php\${PHP_VERSION}-bcmath \
    php\${PHP_VERSION}-intl \
    php\${PHP_VERSION}-readline \
    php\${PHP_VERSION}-opcache \
    php\${PHP_VERSION}-soap \
    php\${PHP_VERSION}-redis \
    php\${PHP_VERSION}-imagick || true

# Habilitar PHP-FPM
systemctl enable php\${PHP_VERSION}-fpm
systemctl start php\${PHP_VERSION}-fpm

# Configurar PHP para produccion
PHP_INI="/etc/php/\${PHP_VERSION}/fpm/php.ini"
if [ -f "\$PHP_INI" ]; then
    # Optimizaciones de seguridad y rendimiento
    sed -i 's/expose_php = On/expose_php = Off/' \$PHP_INI
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' \$PHP_INI
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' \$PHP_INI
    sed -i 's/post_max_size = 8M/post_max_size = 64M/' \$PHP_INI
    sed -i 's/memory_limit = 128M/memory_limit = 256M/' \$PHP_INI
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' \$PHP_INI
    sed -i 's/max_input_time = 60/max_input_time = 300/' \$PHP_INI
    sed -i 's/;date.timezone =/date.timezone = UTC/' \$PHP_INI
fi

# Configurar PHP-FPM pool
PHP_POOL="/etc/php/\${PHP_VERSION}/fpm/pool.d/www.conf"
if [ -f "\$PHP_POOL" ]; then
    sed -i 's/pm = dynamic/pm = dynamic/' \$PHP_POOL
    sed -i 's/pm.max_children = 5/pm.max_children = 20/' \$PHP_POOL
    sed -i 's/pm.start_servers = 2/pm.start_servers = 4/' \$PHP_POOL
    sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 2/' \$PHP_POOL
    sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 6/' \$PHP_POOL
fi

# Reiniciar PHP-FPM
systemctl restart php\${PHP_VERSION}-fpm

# Instalar Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configurar Nginx para PHP
cat > /etc/nginx/sites-available/default << 'NGINXCONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # PHP-FPM configuration
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;

        # Timeouts
        fastcgi_connect_timeout 60;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Deny access to .htaccess
    location ~ /\.ht {
        deny all;
    }

    # Deny access to sensitive files
    location ~* \.(env|log|ini)\$ {
        deny all;
    }

    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|woff|woff2|ttf|svg)\$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml application/javascript application/json;
}
NGINXCONF

# Probar y recargar nginx
nginx -t && systemctl reload nginx

echo "Instalacion de PHP completada"
EOFPHP

    # Copiar script al contenedor y ejecutarlo
    pct push $CONTAINER_ID /tmp/php-install.sh /tmp/php-install.sh
    pct exec $CONTAINER_ID -- chmod +x /tmp/php-install.sh
    pct exec $CONTAINER_ID -- /tmp/php-install.sh

    if [ $? -eq 0 ]; then
        show_success "$TXT_PHP_INSTALLED"
    else
        show_error "$TXT_PHP_ERROR"
    fi

    # Limpiar archivo temporal
    rm -f /tmp/php-install.sh
}

# Crear pagina de bienvenida
create_welcome_page() {
    show_step_msg "Creating welcome page..."

    local INSTALL_PHP_FLAG="$INSTALL_PHP"
    local PHP_VER="$PHP_VERSION"

    # Crear script para pagina de bienvenida
    cat > /tmp/create-welcome.sh << EOFWELCOME
#!/bin/bash

INSTALL_PHP="$INSTALL_PHP_FLAG"
PHP_VERSION="$PHP_VER"

# Crear pagina de bienvenida
if [ "\$INSTALL_PHP" = "yes" ]; then
    # Pagina PHP con info del sistema
    cat > /var/www/html/index.php << 'PHPHTML'
<?php
\$hostname = gethostname();
\$ip = shell_exec("hostname -I | awk '{print \$1}'");
\$phpVersion = phpversion();
\$nginxVersion = shell_exec("nginx -v 2>&1 | cut -d'/' -f2");
\$uptime = shell_exec("uptime -p");
\$memory = shell_exec("free -h | grep Mem | awk '{print \$3 \"/\" \$2}'");
\$disk = shell_exec("df -h / | tail -1 | awk '{print \$3 \"/\" \$2}'");
\$loadAvg = sys_getloadavg();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx + PHP Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            padding: 2rem;
        }
        .header { text-align: center; margin-bottom: 2rem; }
        .logo { font-size: 4rem; margin-bottom: 1rem; }
        h1 { font-size: 2rem; margin-bottom: 0.5rem; color: #4ade80; }
        .subtitle { color: #9ca3af; margin-bottom: 1rem; }
        .status {
            display: inline-block;
            padding: 0.5rem 1.5rem;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            border-radius: 25px;
            font-weight: bold;
            color: white;
        }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin: 2rem 0; }
        .card {
            background: rgba(255, 255, 255, 0.05);
            padding: 1.5rem;
            border-radius: 15px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            text-align: center;
        }
        .card h3 { color: #60a5fa; margin-bottom: 0.5rem; font-size: 0.9rem; }
        .card p { font-size: 1.2rem; font-weight: bold; }
        .card small { color: #9ca3af; font-size: 0.8rem; }
        .commands {
            background: rgba(0, 0, 0, 0.3);
            padding: 1.5rem;
            border-radius: 15px;
            margin: 2rem 0;
        }
        .commands h3 { color: #fbbf24; margin-bottom: 1rem; text-align: center; }
        .cmd-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 0.5rem; }
        code {
            display: block;
            background: rgba(0, 0, 0, 0.5);
            padding: 0.5rem;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            font-size: 0.85rem;
            color: #a5f3fc;
        }
        .footer { text-align: center; margin-top: 2rem; padding-top: 1rem; border-top: 1px solid rgba(255, 255, 255, 0.1); color: #9ca3af; }
        .tech-badge {
            display: inline-block;
            padding: 0.3rem 0.8rem;
            margin: 0.2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            font-size: 0.8rem;
        }
        .php-badge { background: #4f46e5; }
        .nginx-badge { background: #059669; }
        a { color: #60a5fa; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">[Web]</div>
            <h1>Nginx + PHP Server</h1>
            <p class="subtitle">Your web server is ready to serve content</p>
            <div class="status">[OK] ACTIVE</div>
            <div style="margin-top: 1rem;">
                <span class="tech-badge nginx-badge">Nginx <?= trim(\$nginxVersion) ?></span>
                <span class="tech-badge php-badge">PHP <?= \$phpVersion ?></span>
            </div>
        </div>

        <div class="grid">
            <div class="card">
                <h3>HOSTNAME</h3>
                <p><?= \$hostname ?></p>
            </div>
            <div class="card">
                <h3>IP ADDRESS</h3>
                <p><?= trim(\$ip) ?></p>
            </div>
            <div class="card">
                <h3>MEMORY</h3>
                <p><?= trim(\$memory) ?></p>
            </div>
            <div class="card">
                <h3>DISK</h3>
                <p><?= trim(\$disk) ?></p>
            </div>
            <div class="card">
                <h3>LOAD AVG</h3>
                <p><?= number_format(\$loadAvg[0], 2) ?></p>
                <small>1 min avg</small>
            </div>
            <div class="card">
                <h3>UPTIME</h3>
                <p style="font-size: 0.9rem;"><?= trim(\$uptime) ?></p>
            </div>
        </div>

        <div class="commands">
            <h3>Useful Commands</h3>
            <div class="cmd-grid">
                <code>nginx-info</code>
                <code>nginx-manager</code>
                <code>ssl-manager</code>
                <code>php-manager</code>
                <code>nginx-status</code>
                <code>nginx-reload</code>
                <code>composer --version</code>
                <code>php -v</code>
            </div>
        </div>

        <div style="text-align: center; margin: 1rem 0;">
            <p><a href="/info.php">View PHP Info</a></p>
        </div>

        <div class="footer">
            <p>Developed with care for the Proxmox community</p>
            <p>Made in Puerto Rico</p>
        </div>
    </div>
</body>
</html>
PHPHTML

    # Crear pagina phpinfo
    cat > /var/www/html/info.php << 'PHPINFO'
<?php
// Security: Only allow from local network (optional)
phpinfo();
PHPINFO

else
    # Pagina HTML simple sin PHP
    cat > /var/www/html/index.html << 'HTMLONLY'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Web Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            padding: 2rem;
            text-align: center;
        }
        .logo { font-size: 4rem; margin-bottom: 1rem; }
        h1 { font-size: 2rem; margin-bottom: 0.5rem; color: #4ade80; }
        .subtitle { color: #9ca3af; margin-bottom: 1rem; }
        .status {
            display: inline-block;
            padding: 0.5rem 1.5rem;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            border-radius: 25px;
            font-weight: bold;
            color: white;
            margin: 1rem 0;
        }
        .info {
            background: rgba(0, 0, 0, 0.3);
            padding: 1.5rem;
            border-radius: 15px;
            margin: 2rem 0;
            text-align: left;
        }
        .info h3 { color: #fbbf24; margin-bottom: 1rem; text-align: center; }
        code {
            display: block;
            background: rgba(0, 0, 0, 0.5);
            padding: 0.5rem;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            margin: 0.5rem 0;
            color: #a5f3fc;
        }
        .footer { margin-top: 2rem; padding-top: 1rem; border-top: 1px solid rgba(255, 255, 255, 0.1); color: #9ca3af; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">[Web]</div>
        <h1>Nginx Web Server</h1>
        <p class="subtitle">Your web server is ready to serve content</p>
        <div class="status">[OK] ACTIVE</div>

        <div class="info">
            <h3>Useful Commands</h3>
            <code>nginx-info</code>
            <code>nginx-manager</code>
            <code>ssl-manager</code>
            <code>nginx-status</code>
            <code>nginx-reload</code>
        </div>

        <div class="footer">
            <p>Developed with care for the Proxmox community</p>
            <p>Made in Puerto Rico</p>
        </div>
    </div>
</body>
</html>
HTMLONLY
fi

# Configurar permisos
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

echo "Welcome page created"
EOFWELCOME

    pct push $CONTAINER_ID /tmp/create-welcome.sh /tmp/create-welcome.sh
    pct exec $CONTAINER_ID -- chmod +x /tmp/create-welcome.sh
    pct exec $CONTAINER_ID -- /tmp/create-welcome.sh

    rm -f /tmp/create-welcome.sh

    show_success "Welcome page created"
}

# Instalar herramientas de gestion
install_management_tools() {
    show_step_msg "$TXT_INSTALLING_TOOLS"

    local INSTALL_PHP_FLAG="$INSTALL_PHP"
    local PHP_VER="$PHP_VERSION"

    # Crear script de herramientas
    cat > /tmp/tools-install.sh << EOFTOOLS
#!/bin/bash

INSTALL_PHP="$INSTALL_PHP_FLAG"
PHP_VERSION="$PHP_VER"

mkdir -p /opt/nginx-server

# Crear script de bienvenida/info
cat > /opt/nginx-server/welcome.sh << 'WELCOMESCRIPT'
#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Obtener informacion del sistema
HOSTNAME=\$(hostname)
IP_ADDRESS=\$(hostname -I | awk '{print \$1}')
NGINX_STATUS=\$(systemctl is-active nginx)
NGINX_VERSION=\$(nginx -v 2>&1 | cut -d'/' -f2)
UPTIME=\$(uptime -p)
MEMORY=\$(free -h | grep Mem | awk '{print \$3 "/" \$2}')
DISK=\$(df -h / | tail -1 | awk '{print \$3 "/" \$2}')

# Detectar PHP
PHP_INSTALLED="no"
PHP_VERSION=""
if command -v php &> /dev/null; then
    PHP_INSTALLED="yes"
    PHP_VERSION=\$(php -v | head -1 | cut -d' ' -f2)
fi

clear
echo -e "\${CYAN}"
echo "=================================================================="
echo "||                                                              ||"
echo "||              NGINX + PHP WEB SERVER - INFO                   ||"
echo "||                                                              ||"
echo "=================================================================="
echo -e "\${NC}"

echo -e "\${WHITE}Server Information\${NC}"
echo -e "   \${CYAN}Hostname:\${NC} \$HOSTNAME"
echo -e "   \${CYAN}IP Address:\${NC} \$IP_ADDRESS"
echo -e "   \${CYAN}Uptime:\${NC} \$UPTIME"
echo -e "   \${CYAN}Memory:\${NC} \$MEMORY"
echo -e "   \${CYAN}Disk:\${NC} \$DISK"
echo

echo -e "\${WHITE}Services Status\${NC}"
if [ "\$NGINX_STATUS" = "active" ]; then
    echo -e "   \${GREEN}[OK]\${NC} Nginx \$NGINX_VERSION"
else
    echo -e "   \${RED}[X]\${NC} Nginx (inactive)"
fi

if [ "\$PHP_INSTALLED" = "yes" ]; then
    PHP_FPM_STATUS=\$(systemctl is-active php*-fpm 2>/dev/null || echo "inactive")
    if [ "\$PHP_FPM_STATUS" = "active" ]; then
        echo -e "   \${GREEN}[OK]\${NC} PHP-FPM \$PHP_VERSION"
    else
        echo -e "   \${RED}[X]\${NC} PHP-FPM (inactive)"
    fi

    if command -v composer &> /dev/null; then
        COMPOSER_VER=\$(composer --version 2>/dev/null | awk '{print \$3}')
        echo -e "   \${GREEN}[OK]\${NC} Composer \$COMPOSER_VER"
    fi
fi
echo

echo -e "\${WHITE}Important Directories\${NC}"
echo -e "   \${CYAN}Web root:\${NC} /var/www/html"
echo -e "   \${CYAN}Nginx config:\${NC} /etc/nginx/"
echo -e "   \${CYAN}Sites available:\${NC} /etc/nginx/sites-available/"
echo -e "   \${CYAN}Logs:\${NC} /var/log/nginx/"
if [ "\$PHP_INSTALLED" = "yes" ]; then
    echo -e "   \${CYAN}PHP config:\${NC} /etc/php/"
fi
echo

echo -e "\${WHITE}Useful Commands\${NC}"
echo -e "   \${YELLOW}nginx-info\${NC}      - Show this information"
echo -e "   \${YELLOW}nginx-manager\${NC}   - Manage web sites"
echo -e "   \${YELLOW}ssl-manager\${NC}     - Manage SSL certificates"
echo -e "   \${YELLOW}nginx-status\${NC}    - Show nginx status"
echo -e "   \${YELLOW}nginx-test\${NC}      - Test configuration"
echo -e "   \${YELLOW}nginx-reload\${NC}    - Reload configuration"
echo -e "   \${YELLOW}nginx-logs\${NC}      - View access logs"
echo -e "   \${YELLOW}nginx-errors\${NC}    - View error logs"
if [ "\$PHP_INSTALLED" = "yes" ]; then
    echo -e "   \${YELLOW}php-manager\${NC}     - Manage PHP settings"
    echo -e "   \${YELLOW}php-status\${NC}      - Show PHP-FPM status"
fi
echo

echo -e "\${WHITE}Quick Access\${NC}"
echo -e "   \${CYAN}Web:\${NC} http://\$IP_ADDRESS"
if [ "\$PHP_INSTALLED" = "yes" ]; then
    echo -e "   \${CYAN}PHP Info:\${NC} http://\$IP_ADDRESS/info.php"
fi
echo

echo -e "\${PURPLE}Developed for the Proxmox community\${NC}"
echo -e "\${PURPLE}Made in Puerto Rico\${NC}"
echo
WELCOMESCRIPT

chmod +x /opt/nginx-server/welcome.sh

# Crear php-manager si PHP esta instalado
if [ "\$INSTALL_PHP" = "yes" ]; then
    cat > /opt/nginx-server/php-manager.sh << 'PHPMANAGER'
#!/bin/bash

# PHP Manager Script
# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

PHP_VERSION=\$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)

show_menu() {
    clear
    echo -e "\${CYAN}"
    echo "================================================"
    echo "           PHP Manager - v1.0"
    echo "================================================"
    echo -e "\${NC}"
    echo ""
    echo "   1) Show PHP info"
    echo "   2) Show installed modules"
    echo "   3) Restart PHP-FPM"
    echo "   4) View PHP-FPM status"
    echo "   5) Edit php.ini"
    echo "   6) View PHP-FPM logs"
    echo "   7) Clear OPcache"
    echo "   8) Update Composer"
    echo "   0) Exit"
    echo ""
    echo -ne "\${GREEN}>\${NC} Select option: "
}

while true; do
    show_menu
    read option

    case \$option in
        1)
            echo ""
            php -v
            echo ""
            echo "Config file: \$(php --ini | grep 'Loaded Configuration' | cut -d':' -f2)"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            php -m
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            systemctl restart php\${PHP_VERSION}-fpm
            echo -e "\${GREEN}[OK]\${NC} PHP-FPM restarted"
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            systemctl status php\${PHP_VERSION}-fpm
            read -p "Press Enter to continue..."
            ;;
        5)
            nano /etc/php/\${PHP_VERSION}/fpm/php.ini
            echo ""
            echo -ne "Restart PHP-FPM? (y/n): "
            read restart
            if [[ "\$restart" =~ ^[Yy]\$ ]]; then
                systemctl restart php\${PHP_VERSION}-fpm
                echo -e "\${GREEN}[OK]\${NC} PHP-FPM restarted"
            fi
            ;;
        6)
            echo ""
            journalctl -u php\${PHP_VERSION}-fpm -n 50
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            if php -r "opcache_reset();" 2>/dev/null; then
                echo -e "\${GREEN}[OK]\${NC} OPcache cleared"
            else
                echo -e "\${YELLOW}[WARN]\${NC} Could not clear OPcache (may require web request)"
            fi
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            composer self-update
            read -p "Press Enter to continue..."
            ;;
        0)
            echo ""
            echo "Bye!"
            exit 0
            ;;
        *)
            echo -e "\${RED}Invalid option\${NC}"
            sleep 1
            ;;
    esac
done
PHPMANAGER

    chmod +x /opt/nginx-server/php-manager.sh
fi

# Crear nginx-manager basico
cat > /opt/nginx-server/nginx-manager.sh << 'NGINXMANAGER'
#!/bin/bash

# Nginx Manager Script
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "\${CYAN}"
    echo "================================================"
    echo "           Nginx Manager - v1.0"
    echo "================================================"
    echo -e "\${NC}"
    echo ""
    echo "   1) List sites"
    echo "   2) Enable site"
    echo "   3) Disable site"
    echo "   4) Create new site"
    echo "   5) Test configuration"
    echo "   6) Reload Nginx"
    echo "   7) View access logs"
    echo "   8) View error logs"
    echo "   0) Exit"
    echo ""
    echo -ne "\${GREEN}>\${NC} Select option: "
}

list_sites() {
    echo ""
    echo -e "\${WHITE}Available sites:\${NC}"
    ls -la /etc/nginx/sites-available/
    echo ""
    echo -e "\${WHITE}Enabled sites:\${NC}"
    ls -la /etc/nginx/sites-enabled/
    echo ""
}

while true; do
    show_menu
    read option

    case \$option in
        1)
            list_sites
            read -p "Press Enter to continue..."
            ;;
        2)
            list_sites
            echo -ne "Site name to enable: "
            read site
            if [ -f "/etc/nginx/sites-available/\$site" ]; then
                ln -sf /etc/nginx/sites-available/\$site /etc/nginx/sites-enabled/
                nginx -t && systemctl reload nginx
                echo -e "\${GREEN}[OK]\${NC} Site enabled"
            else
                echo -e "\${RED}[ERROR]\${NC} Site not found"
            fi
            read -p "Press Enter to continue..."
            ;;
        3)
            list_sites
            echo -ne "Site name to disable: "
            read site
            if [ -f "/etc/nginx/sites-enabled/\$site" ]; then
                rm /etc/nginx/sites-enabled/\$site
                systemctl reload nginx
                echo -e "\${GREEN}[OK]\${NC} Site disabled"
            else
                echo -e "\${RED}[ERROR]\${NC} Site not enabled"
            fi
            read -p "Press Enter to continue..."
            ;;
        4)
            echo -ne "Domain name: "
            read domain
            echo -ne "Document root [/var/www/\$domain]: "
            read docroot
            docroot=\${docroot:-/var/www/\$domain}

            mkdir -p \$docroot
            chown -R www-data:www-data \$docroot

            cat > /etc/nginx/sites-available/\$domain << SITECONF
server {
    listen 80;
    server_name \$domain www.\$domain;
    root \$docroot;
    index index.php index.html;

    location / {
        try_files \\\$uri \\\$uri/ /index.php?\\\$query_string;
    }

    location ~ \\.php\\\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}
SITECONF

            echo -e "\${GREEN}[OK]\${NC} Site created: /etc/nginx/sites-available/\$domain"
            echo -ne "Enable now? (y/n): "
            read enable
            if [[ "\$enable" =~ ^[Yy]\$ ]]; then
                ln -sf /etc/nginx/sites-available/\$domain /etc/nginx/sites-enabled/
                nginx -t && systemctl reload nginx
            fi
            read -p "Press Enter to continue..."
            ;;
        5)
            echo ""
            nginx -t
            read -p "Press Enter to continue..."
            ;;
        6)
            systemctl reload nginx
            echo -e "\${GREEN}[OK]\${NC} Nginx reloaded"
            read -p "Press Enter to continue..."
            ;;
        7)
            tail -f /var/log/nginx/access.log
            ;;
        8)
            tail -f /var/log/nginx/error.log
            ;;
        0)
            exit 0
            ;;
    esac
done
NGINXMANAGER

chmod +x /opt/nginx-server/nginx-manager.sh

# Crear ssl-manager basico
cat > /opt/nginx-server/ssl-manager.sh << 'SSLMANAGER'
#!/bin/bash

# SSL Manager Script
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "\${CYAN}"
echo "================================================"
echo "           SSL Manager - v1.0"
echo "================================================"
echo -e "\${NC}"
echo ""
echo "   1) Request SSL certificate"
echo "   2) Renew all certificates"
echo "   3) List certificates"
echo "   0) Exit"
echo ""
echo -ne "\${GREEN}>\${NC} Select option: "
read option

case \$option in
    1)
        echo -ne "Domain name: "
        read domain
        echo -ne "Email for Let's Encrypt: "
        read email
        certbot --nginx -d \$domain -d www.\$domain --email \$email --agree-tos --non-interactive
        ;;
    2)
        certbot renew
        ;;
    3)
        certbot certificates
        ;;
    0)
        exit 0
        ;;
esac
SSLMANAGER

chmod +x /opt/nginx-server/ssl-manager.sh

# Agregar aliases al bashrc
cat >> /root/.bashrc << 'BASHALIASES'

# Nginx + PHP Server Aliases
alias nginx-info='/opt/nginx-server/welcome.sh'
alias nginx-manager='/opt/nginx-server/nginx-manager.sh'
alias ssl-manager='/opt/nginx-server/ssl-manager.sh'
alias nginx-logs='tail -f /var/log/nginx/access.log'
alias nginx-errors='tail -f /var/log/nginx/error.log'
alias nginx-test='nginx -t'
alias nginx-reload='systemctl reload nginx'
alias nginx-restart='systemctl restart nginx'
alias nginx-status='systemctl status nginx'
BASHALIASES

# Agregar aliases de PHP si esta instalado
if [ "\$INSTALL_PHP" = "yes" ]; then
    cat >> /root/.bashrc << 'PHPALIASES'

# PHP Aliases
alias php-manager='/opt/nginx-server/php-manager.sh'
alias php-status='systemctl status php*-fpm'
alias php-restart='systemctl restart php*-fpm'
alias php-logs='journalctl -u php*-fpm -f'
PHPALIASES
fi

# Auto-mostrar welcome al login
echo "" >> /root/.bashrc
echo "# Show welcome on login" >> /root/.bashrc
echo "/opt/nginx-server/welcome.sh" >> /root/.bashrc

# Configurar autologin en getty
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'GETTY'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
GETTY

systemctl daemon-reload
systemctl enable getty@tty1.service

echo "Management tools installed"
EOFTOOLS

    # Copiar y ejecutar script
    pct push $CONTAINER_ID /tmp/tools-install.sh /tmp/tools-install.sh
    pct exec $CONTAINER_ID -- chmod +x /tmp/tools-install.sh
    pct exec $CONTAINER_ID -- /tmp/tools-install.sh

    if [ $? -eq 0 ]; then
        show_success "$TXT_TOOLS_INSTALLED"
    else
        show_warning "$TXT_TOOLS_ERROR"
    fi

    rm -f /tmp/tools-install.sh
}

# Obtener informacion del contenedor
get_container_info() {
    show_step_msg "$TXT_GETTING_INFO"

    # Obtener IP del contenedor
    sleep 5
    CONTAINER_IP=$(pct exec $CONTAINER_ID -- hostname -I | awk '{print $1}')

    if [ -z "$CONTAINER_IP" ]; then
        show_warning "$TXT_IP_NOT_FOUND"
        CONTAINER_IP="Verificar con: pct exec $CONTAINER_ID -- hostname -I"
    fi

    show_success "$TXT_INFO_OBTAINED"
}

# =============================================================================
# RESUMEN FINAL
# =============================================================================

show_summary() {
    clear
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "||                                                              ||"
    echo "||              [OK] $TXT_INSTALL_COMPLETE              ||"
    echo "||                                                              ||"
    echo "=================================================================="
    echo -e "${NC}"

    echo ""
    echo -e "${WHITE}$TXT_SUMMARY${NC}"
    echo ""
    echo "   Container"
    echo "   ├─ ID: $CONTAINER_ID"
    echo "   ├─ Hostname: $CONTAINER_NAME"
    echo "   ├─ IP: $CONTAINER_IP"
    echo "   ├─ Password: $CONTAINER_PASSWORD"
    echo "   └─ Template: $SELECTED_TEMPLATE"
    echo ""
    echo "   Resources"
    echo "   ├─ Memory: ${CONTAINER_MEMORY}MB"
    echo "   ├─ Disk: ${CONTAINER_DISK}GB"
    echo "   └─ CPU: $CONTAINER_CORES cores"
    echo ""
    echo "   Software"
    echo "   ├─ [OK] Nginx"
    if [ "$INSTALL_PHP" = "yes" ]; then
        echo "   ├─ [OK] PHP $PHP_VERSION (PHP-FPM)"
        echo "   └─ [OK] Composer"
    else
        echo "   └─ PHP: not installed"
    fi
    echo ""
    echo "   $TXT_FEATURES"
    echo "   ├─ [OK] $TXT_AUTOBOOT"
    echo "   ├─ [OK] $TXT_AUTOLOGIN"
    echo "   └─ [OK] $TXT_SERVICE_RUNNING"
    echo ""

    echo -e "${WHITE}$TXT_WEB_ACCESS${NC}"
    echo "   ├─ http://$CONTAINER_IP"
    if [ "$INSTALL_PHP" = "yes" ]; then
        echo "   └─ http://$CONTAINER_IP/info.php (PHP Info)"
    fi
    echo ""

    echo -e "${WHITE}$TXT_CONTAINER_ACCESS${NC}"
    echo "   ├─ $TXT_PROXMOX_CONSOLE: pct enter $CONTAINER_ID"
    echo "   └─ SSH: ssh root@$CONTAINER_IP"
    echo ""

    echo -e "${WHITE}$TXT_NEXT_STEPS${NC}"
    echo "   1. pct enter $CONTAINER_ID"
    echo "   2. nginx-info"
    echo "   3. nginx-manager"
    if [ "$INSTALL_PHP" = "yes" ]; then
        echo "   4. php-manager"
        echo "   5. ssl-manager"
    else
        echo "   4. ssl-manager"
    fi
    echo ""

    echo -e "${WHITE}$TXT_DOCUMENTATION${NC}"
    echo "   └─ https://github.com/MondoBoricua/nginx-server"
    echo ""

    echo -e "${CYAN}$TXT_THANKS${NC}"
    echo -e "${CYAN}$TXT_DEVELOPED${NC}"
    echo -e "${CYAN}$TXT_MADE_IN${NC}"
    echo ""
}

# =============================================================================
# FUNCION PRINCIPAL
# =============================================================================

main() {
    # Seleccionar idioma primero
    select_language

    # Mostrar banner
    show_banner

    # PASO 1: Verificaciones
    show_step "$TXT_STEP1"
    check_proxmox
    detect_templates
    get_next_vmid

    # PASO 2: Configuracion del contenedor
    configure_container

    # PASO 3: Recursos y red
    configure_resources

    # PASO 4: Configuracion de PHP
    configure_php

    # PASO 5: Confirmacion
    show_confirmation

    # Proceso de instalacion
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  INSTALLING / INSTALANDO...${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    create_container
    install_nginx
    install_php
    create_welcome_page
    install_management_tools
    get_container_info

    # Mostrar resumen
    show_summary
}

# =============================================================================
# VERIFICAR ROOT Y EJECUTAR
# =============================================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m[ERROR]\033[0m This script must be run as root / Este script debe ejecutarse como root"
    exit 1
fi

main "$@"
