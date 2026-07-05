#!/bin/bash

# 🛠️ Instalador de Herramientas para Nginx Server
# Para ejecutar dentro del contenedor nginx-server
# Desarrollado con ❤️ para la comunidad de Proxmox
# Hecho en 🇵🇷 Puerto Rico con mucho ☕ café

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[PASO]${NC} $1"
}

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║        🛠️  INSTALADOR DE HERRAMIENTAS NGINX-SERVER 🛠️        ║"
    echo "║                                                              ║"
    echo "║                    Versión 1.0                               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar que estamos en el contenedor correcto
check_environment() {
    log_step "Verificando entorno..."
    
    if [ ! -f "/etc/nginx/nginx.conf" ]; then
        log_error "Nginx no está instalado. Este script debe ejecutarse en el contenedor nginx-server."
        exit 1
    fi
    
    log_success "Entorno verificado correctamente"
}

# Crear directorio de herramientas
create_tools_directory() {
    log_step "Creando directorio de herramientas..."
    
    mkdir -p /opt/nginx-server/configs
    mkdir -p /opt/nginx-server/sites/default
    mkdir -p /opt/nginx-server/utils
    
    log_success "Directorio /opt/nginx-server creado"
}

# Descargar herramientas desde GitHub
BASE_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/nginx"

download_tools() {
    log_step "Descargando herramientas desde GitHub..."

    cd /opt/nginx-server || { log_error "No se pudo acceder a /opt/nginx-server"; exit 1; }

    # Descargar scripts principales
    wget -O nginx-manager.sh "$BASE_URL/nginx-manager.sh"
    wget -O ssl-manager.sh "$BASE_URL/ssl-manager.sh"
    wget -O welcome.sh "$BASE_URL/welcome.sh"
    wget -O backup-config.sh "$BASE_URL/backup-config.sh"

    # Descargar configuraciones
    wget -O configs/nginx.conf "$BASE_URL/configs/nginx.conf"
    wget -O configs/default-site.conf "$BASE_URL/configs/default-site.conf"
    wget -O configs/ssl-template.conf "$BASE_URL/configs/ssl-template.conf"

    # Descargar sitio de ejemplo
    wget -O sites/default/index.html "$BASE_URL/sites/default/index.html"
    mkdir -p sites/default/css sites/default/js
    wget -O sites/default/css/style.css "$BASE_URL/sites/default/css/style.css"
    wget -O sites/default/js/main.js "$BASE_URL/sites/default/js/main.js"

    # Descargar utilidades
    wget -O utils/security.sh "$BASE_URL/utils/security.sh"
    wget -O utils/monitoring.sh "$BASE_URL/utils/monitoring.sh"

    log_success "Herramientas descargadas"
}

# Hacer scripts ejecutables
make_executable() {
    log_step "Configurando permisos..."
    
    chmod +x /opt/nginx-server/*.sh
    chmod +x /opt/nginx-server/utils/*.sh
    
    log_success "Permisos configurados"
}

# Crear enlaces simbólicos
create_symlinks() {
    log_step "Creando enlaces simbólicos..."
    
    ln -sf /opt/nginx-server/nginx-manager.sh /usr/local/bin/nginx-manager
    ln -sf /opt/nginx-server/ssl-manager.sh /usr/local/bin/ssl-manager
    ln -sf /opt/nginx-server/welcome.sh /usr/local/bin/nginx-info
    ln -sf /opt/nginx-server/backup-config.sh /usr/local/bin/backup-config
    
    log_success "Enlaces simbólicos creados"
}

# Instalar sitio de ejemplo
install_default_site() {
    log_step "Instalando sitio de ejemplo..."
    
    # Copiar sitio de ejemplo
    cp -r /opt/nginx-server/sites/default/* /var/www/html/
    
    # Configurar permisos
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    log_success "Sitio de ejemplo instalado"
}

# Configurar nginx optimizado
configure_nginx() {
    log_step "Configurando nginx optimizado..."
    
    # Backup de configuración actual
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # Aplicar configuración optimizada
    cp /opt/nginx-server/configs/nginx.conf /etc/nginx/nginx.conf
    
    # Verificar configuración
    if nginx -t; then
        log_success "Configuración de nginx aplicada"
        systemctl reload nginx
    else
        log_error "Error en configuración de nginx, restaurando backup"
        cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
        exit 1
    fi
}

# Configurar autologin
configure_autologin() {
    log_step "Configurando autologin..."
    
    # Agregar welcome al .bashrc
    if ! grep -q "nginx-info" /root/.bashrc; then
        echo "" >> /root/.bashrc
        echo "# Mostrar información del servidor nginx" >> /root/.bashrc
        echo "nginx-info" >> /root/.bashrc
    fi
    
    log_success "Autologin configurado"
}

# Función principal
main() {
    show_banner
    
    log_info "Instalando herramientas de gestión para nginx-server..."
    echo
    
    check_environment
    create_tools_directory
    download_tools
    make_executable
    create_symlinks
    install_default_site
    configure_nginx
    configure_autologin
    
    echo
    log_success "¡Instalación completada exitosamente!"
    echo
    echo -e "${WHITE}Herramientas disponibles:${NC}"
    echo -e "  ${YELLOW}nginx-manager${NC}  - Gestionar sitios web"
    echo -e "  ${YELLOW}ssl-manager${NC}    - Gestionar certificados SSL"
    echo -e "  ${YELLOW}nginx-info${NC}     - Información del servidor"
    echo -e "  ${YELLOW}backup-config${NC}  - Backup de configuraciones"
    echo
    echo -e "${CYAN}¡Disfruta tu servidor nginx optimizado!${NC} 🌐🇵🇷☕"
}

# Ejecutar función principal
main "$@" 