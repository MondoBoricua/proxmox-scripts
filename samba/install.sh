#!/bin/bash

# 🗂️ Script de Instalación Rápida de Samba para LXC Existente
# Desarrollado por MondoBoricua para la comunidad de Proxmox
# Versión: 1.0

set -e  # Salir si hay algún error

# Colores para output - pa' que se vea bonito
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con estilo
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Verificar que el script se ejecute como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root. Usa 'sudo' o ejecuta como root."
        exit 1
    fi
}

# Detectar si estamos en un contenedor LXC
check_lxc() {
    if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ] && ! grep -q "lxc" /proc/1/cgroup 2>/dev/null; then
        print_warning "Este script está diseñado para contenedores LXC"
        read -p "¿Continuar de todas formas? (s/n) [n]: " CONTINUE
        CONTINUE=${CONTINUE:-n}
        if [[ $CONTINUE != "s" && $CONTINUE != "S" ]]; then
            print_message "Instalación cancelada"
            exit 0
        fi
    fi
}

# Detectar el sistema operativo
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_error "No se puede detectar el sistema operativo"
        exit 1
    fi
    
    print_message "Sistema detectado: $OS $VERSION"
    
    # Verificar compatibilidad
    case $ID in
        ubuntu|debian)
            print_success "Sistema operativo compatible"
            ;;
        *)
            print_warning "Sistema operativo no probado: $ID"
            read -p "¿Continuar de todas formas? (s/n) [n]: " CONTINUE
            CONTINUE=${CONTINUE:-n}
            if [[ $CONTINUE != "s" && $CONTINUE != "S" ]]; then
                print_message "Instalación cancelada"
                exit 0
            fi
            ;;
    esac
}

# Descargar el script principal de Samba
download_samba_script() {
    print_header "Descargando Script Principal de Samba"
    
    SCRIPT_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/samba/samba.sh"
    SCRIPT_PATH="/tmp/samba-installer.sh"
    
    print_message "Descargando desde GitHub..."
    
    # Intentar descargar con curl primero
    if command -v curl &> /dev/null; then
        if curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
            print_success "Script descargado exitosamente con curl"
        else
            print_warning "Error al descargar con curl, intentando con wget..."
            download_with_wget
        fi
    elif command -v wget &> /dev/null; then
        download_with_wget
    else
        print_error "No se encontró curl ni wget para descargar el script"
        create_local_script
    fi
    
    # Verificar que el archivo se descargó correctamente
    if [ -f "$SCRIPT_PATH" ] && [ -s "$SCRIPT_PATH" ]; then
        chmod +x "$SCRIPT_PATH"
        print_success "Script preparado para ejecución"
    else
        print_error "Error al descargar el script"
        create_local_script
    fi
}

# Función auxiliar para descargar con wget
download_with_wget() {
    if wget -O "$SCRIPT_PATH" "$SCRIPT_URL"; then
        print_success "Script descargado exitosamente con wget"
    else
        print_warning "Error al descargar con wget, creando script local..."
        create_local_script
    fi
}

# Crear script local si no se puede descargar
create_local_script() {
    print_message "Creando instalación básica local..."
    
    cat > "$SCRIPT_PATH" << 'LOCAL_SCRIPT_EOF'
#!/bin/bash

# Script básico de instalación de Samba
# Versión local de emergencia

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

# Actualizar sistema e instalar Samba
print_message "Actualizando sistema..."
export DEBIAN_FRONTEND=noninteractive
apt update

print_message "Instalando Samba y dependencias..."
apt install -y samba samba-common-bin samba-client cifs-utils

# Crear estructura de directorios
print_message "Creando estructura de directorios..."
mkdir -p /srv/samba/{public,private,users}
mkdir -p /opt/samba
mkdir -p /var/log/samba

# Configurar permisos
chmod 777 /srv/samba/public
chmod 770 /srv/samba/private
chmod 755 /srv/samba/users

# Crear grupo sambashare
groupadd -f sambashare
chown -R root:sambashare /srv/samba/

# Backup de configuración original
cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Crear configuración básica
cat > /etc/samba/smb.conf << 'SMB_CONF_EOF'
[global]
    workgroup = WORKGROUP
    server string = Samba Server LXC
    security = user
    map to guest = never
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file
    
    # Optimizaciones básicas
    socket options = TCP_NODELAY
    read raw = yes
    write raw = yes
    
    # Protocolos modernos
    min protocol = SMB2
    max protocol = SMB3
    
    # Configuración de archivos
    create mask = 0664
    directory mask = 0775

[public]
    comment = Directorio Público
    path = /srv/samba/public
    browsable = yes
    writable = yes
    guest ok = yes
    read only = no
    public = yes
    create mask = 0666
    directory mask = 0777

[private]
    comment = Directorio Privado
    path = /srv/samba/private
    browsable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = @sambashare
    create mask = 0664
    directory mask = 0775

SMB_CONF_EOF

# Verificar configuración
if testparm -s > /dev/null 2>&1; then
    print_success "Configuración de Samba válida"
else
    print_error "Error en la configuración de Samba"
    exit 1
fi

# Habilitar e iniciar servicios
systemctl enable smbd nmbd
systemctl start smbd nmbd

# Verificar servicios
if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
    print_success "Servicios de Samba iniciados correctamente"
else
    print_error "Error al iniciar los servicios de Samba"
    exit 1
fi

# Crear script de información básico
cat > /opt/samba/samba-info.sh << 'INFO_SCRIPT_EOF'
#!/bin/bash

echo "🗂️ Información del Servidor Samba"
echo "=================================="
echo "IP del servidor: $(hostname -I | awk '{print $1}')"
echo "Hostname: $(hostname)"
echo

echo "Estado de servicios:"
systemctl is-active smbd && echo "  ✅ SMB Daemon: Activo" || echo "  ❌ SMB Daemon: Inactivo"
systemctl is-active nmbd && echo "  ✅ NetBIOS Daemon: Activo" || echo "  ❌ NetBIOS Daemon: Inactivo"
echo

echo "Recursos compartidos:"
smbclient -L localhost -N 2>/dev/null | grep -E "^\s*[A-Za-z]" | grep -v "IPC\|ADMIN" || echo "  No hay recursos disponibles"
echo

echo "Comandos útiles:"
echo "  - Ver conexiones: smbstatus"
echo "  - Verificar config: testparm"
echo "  - Ver logs: tail -f /var/log/samba/log.smbd"

INFO_SCRIPT_EOF

chmod +x /opt/samba/samba-info.sh

# Crear alias
echo 'alias samba-info="/opt/samba/samba-info.sh"' >> /root/.bashrc

print_success "Instalación básica de Samba completada"
echo
echo "🔗 Cómo conectarse:"
echo "   Desde Windows: \\\\$(hostname -I | awk '{print $1}')"
echo "   Desde Linux: smb://$(hostname -I | awk '{print $1}')"
echo
echo "📁 Recursos compartidos creados:"
echo "   - public: Acceso público"
echo "   - private: Solo usuarios autenticados"
echo
echo "Para ver información completa: samba-info"

LOCAL_SCRIPT_EOF

    chmod +x "$SCRIPT_PATH"
    print_success "Script local creado"
}

# Ejecutar el script de instalación
run_installation() {
    print_header "Ejecutando Instalación de Samba"
    
    if [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
        print_message "Iniciando instalación automática..."
        
        # Ejecutar el script con configuración automática si es posible
        if grep -q "get_user_input" "$SCRIPT_PATH"; then
            print_message "Ejecutando instalación interactiva..."
            "$SCRIPT_PATH"
        else
            print_message "Ejecutando instalación básica..."
            "$SCRIPT_PATH"
        fi
        
        print_success "Instalación completada exitosamente"
    else
        print_error "No se pudo ejecutar el script de instalación"
        exit 1
    fi
}

# Limpiar archivos temporales
cleanup() {
    if [ -f "$SCRIPT_PATH" ]; then
        rm -f "$SCRIPT_PATH"
        print_message "Archivos temporales limpiados"
    fi
}

# Mostrar información final
show_final_info() {
    print_header "🎉 INSTALACIÓN COMPLETADA"
    
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "No disponible")
    
    echo -e "${GREEN}✅ Samba instalado y configurado exitosamente${NC}"
    echo
    echo -e "${CYAN}📋 INFORMACIÓN DEL SERVIDOR:${NC}"
    echo -e "   🌐 IP del servidor: ${GREEN}$SERVER_IP${NC}"
    echo -e "   🖥️  Hostname: ${GREEN}$(hostname)${NC}"
    echo
    
    echo -e "${CYAN}🔗 CÓMO CONECTARSE:${NC}"
    echo -e "   🖥️  Desde Windows: ${GREEN}\\\\$SERVER_IP${NC}"
    echo -e "   🐧 Desde Linux: ${GREEN}smb://$SERVER_IP${NC}"
    echo -e "   📱 Desde móvil: ${GREEN}smb://$SERVER_IP${NC}"
    echo
    
    echo -e "${CYAN}📂 RECURSOS COMPARTIDOS:${NC}"
    echo -e "   📁 ${GREEN}public${NC} - Acceso público sin autenticación"
    echo -e "   🔒 ${GREEN}private${NC} - Solo usuarios autenticados"
    echo
    
    echo -e "${CYAN}🛠️  COMANDOS ÚTILES:${NC}"
    echo -e "   📊 Ver información: ${GREEN}samba-info${NC}"
    echo -e "   🔧 Verificar config: ${GREEN}testparm${NC}"
    echo -e "   📈 Ver conexiones: ${GREEN}smbstatus${NC}"
    echo -e "   📝 Ver logs: ${GREEN}tail -f /var/log/samba/log.smbd${NC}"
    echo
    
    print_success "¡Listo pa' usar! Tu servidor Samba está funcionando."
    
    # Mostrar información del servidor si está disponible
    if command -v /opt/samba/samba-info.sh &> /dev/null; then
        echo
        read -p "¿Quieres ver la información detallada del servidor? (s/n) [s]: " SHOW_INFO
        SHOW_INFO=${SHOW_INFO:-s}
        
        if [[ $SHOW_INFO == "s" || $SHOW_INFO == "S" ]]; then
            echo
            /opt/samba/samba-info.sh
        fi
    fi
}

# Función principal
main() {
    print_header "🗂️ Instalador Rápido de Samba para LXC"
    echo -e "${CYAN}Desarrollado por MondoBoricua para la comunidad${NC}"
    echo
    
    # Verificaciones iniciales
    check_root
    check_lxc
    detect_os
    
    # Proceso de instalación
    download_samba_script
    run_installation
    cleanup
    
    # Información final
    show_final_info
}

# Configurar trap para limpieza
trap cleanup EXIT

# Ejecutar función principal
main "$@" 