#!/bin/bash

# 🔧 Script de Recuperación Rápida para Samba
# Desarrollado por MondoBoricua
# Este script intenta solucionar problemas comunes después de una instalación fallida

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                🔧 RECUPERACIÓN RÁPIDA DE SAMBA                ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

# Reparar instalación de paquetes
fix_packages() {
    print_step "Reparando instalación de paquetes..."
    
    # Actualizar repositorios
    apt update -qq
    
    # Instalar/reinstalar paquetes de Samba
    apt install -y samba samba-common-bin samba-client
    
    if dpkg -l | grep -q "^ii.*samba"; then
        print_success "Paquetes de Samba instalados correctamente"
    else
        print_error "Error al instalar paquetes de Samba"
        return 1
    fi
}

# Crear directorios necesarios
fix_directories() {
    print_step "Creando directorios necesarios..."
    
    # Crear directorios principales
    mkdir -p /srv/samba/{public,private}
    mkdir -p /opt/samba
    
    # Crear grupo sambashare si no existe
    if ! getent group sambashare > /dev/null 2>&1; then
        groupadd sambashare
        print_success "Grupo sambashare creado"
    fi
    
    # Configurar permisos básicos (compatible con NTFS)
    # Detectar si está en NTFS
    fs_type=$(df -T /srv/samba 2>/dev/null | tail -1 | awk '{print $2}')
    if [[ "$fs_type" == "ntfs" || "$fs_type" == "fuseblk" ]]; then
        print_warning "Directorio /srv/samba está en NTFS - permisos Unix no aplicables"
        print_message "Samba manejará los permisos automáticamente"
    else
        chown -R root:sambashare /srv/samba/ 2>/dev/null || print_warning "Error al cambiar permisos, continuando..."
        chmod 2775 /srv/samba/public 2>/dev/null || print_warning "Error al cambiar permisos de public"
        chmod 2770 /srv/samba/private 2>/dev/null || print_warning "Error al cambiar permisos de private"
    fi
    
    print_success "Directorios configurados"
}

# Crear configuración básica de Samba
fix_config() {
    print_step "Creando configuración básica de Samba..."
    
    # Backup de configuración existente
    if [ -f /etc/samba/smb.conf ]; then
        cp /etc/samba/smb.conf "/etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Crear configuración básica
    cat > /etc/samba/smb.conf << 'EOF'
[global]
    workgroup = WORKGROUP
    server string = Samba Server %v
    netbios name = samba-server
    security = user
    map to guest = bad user
    dns proxy = no
    log file = /var/log/samba/log.%m
    max log size = 1000
    syslog = 0
    panic action = /usr/share/samba/panic-action %d
    server role = standalone server
    passdb backend = tdbsam
    obey pam restrictions = yes
    unix password sync = yes
    passwd program = /usr/bin/passwd %u
    passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
    pam password change = yes
    map to guest = bad user
    usershare allow guests = yes
    
    # Optimizaciones de rendimiento
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
    read raw = yes
    write raw = yes
    server signing = auto
    use sendfile = yes
    aio read size = 16384
    aio write size = 16384
    
    # Protocolo SMB
    server min protocol = SMB2
    server max protocol = SMB3
    
    # Configuración para sistemas de archivos sin permisos Unix (como NTFS)
    store dos attributes = yes
    map archive = no
    map hidden = no
    map readonly = no
    map system = no

[public]
    comment = Carpeta Pública
    path = /srv/samba/public
    browseable = yes
    writable = yes
    guest ok = yes
    read only = no
    force user = nobody
    force group = sambashare
    create mask = 0664
    directory mask = 0775
    # Configuración para NTFS
    store dos attributes = yes
    map archive = no
    map hidden = no
    map readonly = no
    map system = no

[private]
    comment = Carpeta Privada
    path = /srv/samba/private
    browseable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = @sambashare
    force group = sambashare
    create mask = 0664
    directory mask = 0775
    # Configuración para NTFS
    store dos attributes = yes
    map archive = no
    map hidden = no
    map readonly = no
    map system = no
EOF

    # Verificar configuración
    if testparm -s /etc/samba/smb.conf >/dev/null 2>&1; then
        print_success "Configuración de Samba creada y verificada"
    else
        print_error "Error en la configuración de Samba"
        return 1
    fi
}

# Reparar servicios
fix_services() {
    print_step "Reparando servicios de Samba..."
    
    # Detener servicios
    systemctl stop smbd nmbd 2>/dev/null || true
    
    # Limpiar cualquier proceso colgado
    pkill -f smbd 2>/dev/null || true
    pkill -f nmbd 2>/dev/null || true
    
    # Esperar un momento
    sleep 2
    
    # Habilitar servicios
    systemctl enable smbd nmbd
    
    # Iniciar servicios
    systemctl start smbd
    systemctl start nmbd
    
    # Verificar que estén corriendo
    sleep 3
    
    if systemctl is-active --quiet smbd; then
        print_success "Servicio smbd iniciado correctamente"
    else
        print_error "Error al iniciar smbd"
        systemctl status smbd --no-pager -l
        return 1
    fi
    
    if systemctl is-active --quiet nmbd; then
        print_success "Servicio nmbd iniciado correctamente"
    else
        print_warning "nmbd no está corriendo, continuando..."
    fi
}

# Configurar firewall básico
fix_firewall() {
    print_step "Configurando firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow samba 2>/dev/null || print_warning "Error al configurar UFW"
        print_success "Reglas de firewall configuradas"
    else
        print_warning "UFW no está instalado"
    fi
}

# Pruebas básicas
run_tests() {
    print_step "Ejecutando pruebas básicas..."
    
    # Probar configuración
    if testparm -s >/dev/null 2>&1; then
        print_success "Configuración válida"
    else
        print_error "Configuración inválida"
        return 1
    fi
    
    # Probar conexión local
    if smbclient -L localhost -N >/dev/null 2>&1; then
        print_success "Conexión local exitosa"
    else
        print_warning "Conexión local fallida"
    fi
    
    # Mostrar estado
    echo
    echo -e "${CYAN}Estado final:${NC}"
    systemctl is-active smbd && echo -e "  smbd: ${GREEN}Activo${NC}" || echo -e "  smbd: ${RED}Inactivo${NC}"
    systemctl is-active nmbd && echo -e "  nmbd: ${GREEN}Activo${NC}" || echo -e "  nmbd: ${RED}Inactivo${NC}"
}

# Mostrar información final
show_final_info() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                    RECUPERACIÓN COMPLETADA                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}🌐 Información de conexión:${NC}"
    echo -e "   IP del servidor: ${GREEN}$SERVER_IP${NC}"
    echo -e "   Desde Windows: ${GREEN}\\\\$SERVER_IP${NC}"
    echo -e "   Desde Linux: ${GREEN}smb://$SERVER_IP${NC}"
    echo
    echo -e "${CYAN}📂 Recursos disponibles:${NC}"
    echo -e "   📁 ${GREEN}public${NC} - Acceso público"
    echo -e "   🔒 ${GREEN}private${NC} - Solo usuarios autenticados"
    echo
    echo -e "${CYAN}🛠️ Comandos útiles:${NC}"
    echo -e "   Verificar estado: ${GREEN}systemctl status smbd${NC}"
    echo -e "   Ver configuración: ${GREEN}testparm${NC}"
    echo -e "   Ver conexiones: ${GREEN}smbstatus${NC}"
    echo -e "   Reiniciar servicios: ${GREEN}systemctl restart smbd nmbd${NC}"
    echo
}

# Función principal
main() {
    clear
    print_header
    
    check_root
    
    echo -e "${YELLOW}Este script intentará reparar problemas comunes de Samba${NC}"
    echo -e "${YELLOW}¿Continuar? (s/n) [s]:${NC}"
    read -r confirm
    confirm=${confirm:-s}
    
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        echo "Operación cancelada"
        exit 0
    fi
    
    echo
    
    # Ejecutar reparaciones
    if ! fix_packages; then
        print_error "Error crítico en la instalación de paquetes"
        exit 1
    fi
    
    fix_directories
    
    if ! fix_config; then
        print_error "Error crítico en la configuración"
        exit 1
    fi
    
    if ! fix_services; then
        print_error "Error crítico en los servicios"
        exit 1
    fi
    
    fix_firewall
    
    run_tests
    
    show_final_info
    
    print_success "¡Recuperación completada! Tu servidor Samba debería estar funcionando."
}

main "$@" 