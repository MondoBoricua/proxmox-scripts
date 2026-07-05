#!/bin/bash

# 🗂️ Script de Instalación y Configuración de Samba para LXC
# Desarrollado por MondoBoricua para la comunidad de Proxmox
# Versión: 1.0

# No usar set -e en modo automático para permitir continuar con errores menores
# set -e  # Salir si hay algún error

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
}

# Actualizar el sistema y instalar dependencias
install_dependencies() {
    print_header "Instalando Dependencias"
    
    # Actualizar la lista de paquetes
    print_message "Actualizando lista de paquetes..."
    apt update
    
    # Instalar Samba y herramientas necesarias
    print_message "Instalando Samba y dependencias..."
    apt install -y samba samba-common-bin samba-client cifs-utils acl
    
    # Instalar herramientas adicionales útiles
    apt install -y net-tools curl wget nano htop tree
    
    print_success "Dependencias instaladas correctamente"
}

# Solicitar información de configuración al usuario
get_user_input() {
    print_header "Configuración del Servidor Samba"
    
    # Nombre del servidor
    read -p "Nombre del servidor Samba [samba-server]: " SERVER_NAME
    SERVER_NAME=${SERVER_NAME:-samba-server}
    
    # Grupo de trabajo
    read -p "Grupo de trabajo [WORKGROUP]: " WORKGROUP
    WORKGROUP=${WORKGROUP:-WORKGROUP}
    
    # Crear usuario administrador
    read -p "¿Crear usuario administrador? (s/n) [s]: " CREATE_ADMIN
    CREATE_ADMIN=${CREATE_ADMIN:-s}
    
    if [[ $CREATE_ADMIN == "s" || $CREATE_ADMIN == "S" ]]; then
        read -p "Nombre del usuario administrador [admin]: " ADMIN_USER
        ADMIN_USER=${ADMIN_USER:-admin}
        
        # Solicitar contraseña de forma segura
        echo -n "Contraseña para $ADMIN_USER: "
        read -s ADMIN_PASS
        echo
        echo -n "Confirmar contraseña: "
        read -s ADMIN_PASS_CONFIRM
        echo
        
        if [[ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]]; then
            print_error "Las contraseñas no coinciden"
            exit 1
        fi
    fi
    
    # Crear compartido público
    read -p "¿Crear compartido público? (s/n) [s]: " CREATE_PUBLIC
    CREATE_PUBLIC=${CREATE_PUBLIC:-s}
    
    # Crear compartido privado
    read -p "¿Crear compartido privado? (s/n) [s]: " CREATE_PRIVATE
    CREATE_PRIVATE=${CREATE_PRIVATE:-s}
    
    print_success "Configuración recopilada correctamente"
}

# Función para configurar permisos seguros (compatible con NTFS)
safe_chmod() {
    local target="$1"
    local permissions="$2"
    
    if is_ntfs_filesystem "$target"; then
        log_debug "Directorio $target está en NTFS, omitiendo chmod"
        print_warning "Directorio $target está en NTFS - permisos Unix no aplicables"
        return 0
    else
        log_debug "Aplicando chmod $permissions a $target"
        chmod "$permissions" "$target"
    fi
}

# Crear estructura de directorios
create_directories() {
    print_header "Creando Estructura de Directorios"
    
    # Directorio base para Samba
    mkdir -p /srv/samba
    mkdir -p /opt/samba
    mkdir -p /var/log/samba
    
    # Verificar si hay mapeos de NTFS
    if mount | grep -q "ntfs\|fuseblk"; then
        print_message "Detectados sistemas de archivos NTFS montados"
        log_debug "Sistemas de archivos montados:"
        mount | grep -E "ntfs|fuseblk" | while read line; do
            log_debug "  $line"
        done
    fi
    
    # Directorios para compartidos
    if [[ $CREATE_PUBLIC == "s" || $CREATE_PUBLIC == "S" ]]; then
        mkdir -p /srv/samba/public
        safe_chmod /srv/samba/public 777
        if is_ntfs_filesystem /srv/samba/public; then
            print_message "Directorio público creado: /srv/samba/public (NTFS - permisos manejados por Samba)"
        else
            print_message "Directorio público creado: /srv/samba/public"
        fi
    fi
    
    if [[ $CREATE_PRIVATE == "s" || $CREATE_PRIVATE == "S" ]]; then
        mkdir -p /srv/samba/private
        safe_chmod /srv/samba/private 770
        if is_ntfs_filesystem /srv/samba/private; then
            print_message "Directorio privado creado: /srv/samba/private (NTFS - permisos manejados por Samba)"
        else
            print_message "Directorio privado creado: /srv/samba/private"
        fi
    fi
    
    # Directorio para usuarios
    mkdir -p /srv/samba/users
    safe_chmod /srv/samba/users 755
    
    print_success "Estructura de directorios creada (compatible con NTFS)"
}

# Función para detectar si un directorio está en NTFS
is_ntfs_filesystem() {
    local dir="$1"
    local fs_type=$(df -T "$dir" 2>/dev/null | tail -1 | awk '{print $2}')
    [[ "$fs_type" == "ntfs" || "$fs_type" == "fuseblk" ]]
}

# Función para configurar permisos seguros
safe_chown() {
    local target="$1"
    local owner="$2"
    
    if is_ntfs_filesystem "$target"; then
        log_debug "Directorio $target está en NTFS, omitiendo chown"
        print_warning "Directorio $target está en NTFS - no se pueden cambiar permisos Unix"
        return 0
    else
        log_debug "Aplicando chown a $target"
        chown "$owner" "$target"
    fi
}

# Crear grupo de Samba
create_samba_group() {
    print_message "Creando grupo sambashare..."
    
    # Crear grupo si no existe
    if ! getent group sambashare > /dev/null 2>&1; then
        groupadd sambashare
        print_message "Grupo sambashare creado"
    else
        print_message "Grupo sambashare ya existe"
    fi
    
    # Establecer permisos en directorios con detección de NTFS
    print_message "Configurando permisos de directorios..."
    
    if [ -d /srv/samba ]; then
        # Verificar si /srv/samba está en NTFS
        if is_ntfs_filesystem /srv/samba; then
            print_warning "/srv/samba está en sistema de archivos NTFS"
            print_message "Los permisos Unix no se aplicarán, pero Samba funcionará correctamente"
        else
            # Solo aplicar chown si no es NTFS
            safe_chown "/srv/samba" "root:sambashare" || {
                print_warning "Error al cambiar permisos de /srv/samba/, continuando..."
            }
            
            if [[ $CREATE_PRIVATE == "s" || $CREATE_PRIVATE == "S" ]] && [ -d /srv/samba/private ]; then
                safe_chown "/srv/samba/private" ":sambashare" || {
                    print_warning "Error al cambiar grupo de /srv/samba/private, continuando..."
                }
            fi
        fi
        
        print_success "Permisos configurados (compatibles con el sistema de archivos)"
    else
        print_error "Directorio /srv/samba no existe"
        return 1
    fi
}

# Crear usuarios del sistema y Samba
create_users() {
    if [[ $CREATE_ADMIN == "s" || $CREATE_ADMIN == "S" ]]; then
        print_header "Creando Usuario Administrador"
        
        # Crear usuario del sistema si no existe
        if ! id "$ADMIN_USER" &>/dev/null; then
            useradd -m -s /bin/bash -G sambashare "$ADMIN_USER"
            print_message "Usuario del sistema $ADMIN_USER creado"
        else
            usermod -a -G sambashare "$ADMIN_USER"
            print_message "Usuario $ADMIN_USER agregado al grupo sambashare"
        fi
        
        # Establecer contraseña del sistema
        echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
        
        # Crear usuario de Samba
        (echo "$ADMIN_PASS"; echo "$ADMIN_PASS") | smbpasswd -a "$ADMIN_USER"
        smbpasswd -e "$ADMIN_USER"
        
        # Crear directorio personal
        mkdir -p "/srv/samba/users/$ADMIN_USER"
        safe_chown "/srv/samba/users/$ADMIN_USER" "$ADMIN_USER:sambashare"
        safe_chmod "/srv/samba/users/$ADMIN_USER" 755
        
        print_success "Usuario administrador $ADMIN_USER creado correctamente"
    fi
}

# Configurar Samba
configure_samba() {
    print_header "Configurando Samba"
    
    # Hacer backup de la configuración original
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    
    # Crear nueva configuración optimizada
    cat > /etc/samba/smb.conf << EOF
# Configuración de Samba generada por script de MondoBoricua
# Fecha: $(date)

[global]
    # Configuración básica del servidor
    workgroup = $WORKGROUP
    server string = $SERVER_NAME - Servidor Samba LXC
    netbios name = $(echo $SERVER_NAME | tr '[:lower:]' '[:upper:]')
    
    # Configuración de seguridad
    security = user
    map to guest = never
    guest account = nobody
    
    # Configuración de red - optimizada para LXC
    interfaces = lo eth0
    bind interfaces only = yes
    
    # Configuración de logs
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file
    log level = 1
    
    # Optimizaciones para rendimiento
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
    read raw = yes
    write raw = yes
    max xmit = 65535
    dead time = 15
    getwd cache = yes
    
    # Configuración de protocolos - solo versiones modernas y seguras
    min protocol = SMB2
    max protocol = SMB3
    
    # Configuración de archivos
    create mask = 0664
    directory mask = 0775
    force create mode = 0664
    force directory mode = 0775
    
    # Configuración adicional
    load printers = no
    disable spoolss = yes
    printing = bsd
    printcap name = /dev/null
    
    # Evitar problemas con archivos especiales
    veto files = /._*/.DS_Store/Thumbs.db/desktop.ini/
    delete veto files = yes

EOF

    # Agregar compartido público si se solicitó
    if [[ $CREATE_PUBLIC == "s" || $CREATE_PUBLIC == "S" ]]; then
        cat >> /etc/samba/smb.conf << EOF

# Compartido público - acceso sin autenticación
[public]
    comment = Directorio Público - Acceso para todos
    path = /srv/samba/public
    browsable = yes
    writable = yes
    guest ok = yes
    read only = no
    public = yes
    create mask = 0666
    directory mask = 0777
    force user = nobody
    force group = nogroup

EOF
        print_message "Compartido público configurado"
    fi

    # Agregar compartido privado si se solicitó
    if [[ $CREATE_PRIVATE == "s" || $CREATE_PRIVATE == "S" ]]; then
        cat >> /etc/samba/smb.conf << EOF

# Compartido privado - solo usuarios autenticados
[private]
    comment = Directorio Privado - Solo usuarios autenticados
    path = /srv/samba/private
    browsable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = @sambashare
    create mask = 0664
    directory mask = 0775
    force group = sambashare

EOF
        print_message "Compartido privado configurado"
    fi

    # Agregar directorios de usuarios si se creó el admin
    if [[ $CREATE_ADMIN == "s" || $CREATE_ADMIN == "S" ]]; then
        cat >> /etc/samba/smb.conf << EOF

# Directorio personal del usuario administrador
[$ADMIN_USER]
    comment = Directorio personal de $ADMIN_USER
    path = /srv/samba/users/$ADMIN_USER
    browsable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = $ADMIN_USER
    create mask = 0644
    directory mask = 0755

EOF
        print_message "Directorio personal de $ADMIN_USER configurado"
    fi

    # Verificar la configuración
    print_message "Verificando configuración de Samba..."
    if testparm -s > /dev/null 2>&1; then
        print_success "Configuración de Samba válida"
    else
        print_error "Error en la configuración de Samba"
        testparm
        exit 1
    fi
}

# Configurar servicios y firewall
configure_services() {
    print_header "Configurando Servicios"
    
    # Habilitar servicios de Samba
    print_message "Habilitando servicios de Samba..."
    if systemctl enable smbd; then
        print_message "Servicio smbd habilitado"
    else
        print_warning "Error al habilitar smbd, continuando..."
    fi
    
    if systemctl enable nmbd; then
        print_message "Servicio nmbd habilitado"
    else
        print_warning "Error al habilitar nmbd, continuando..."
    fi
    
    # Iniciar servicios de Samba
    print_message "Iniciando servicios de Samba..."
    
    # Intentar iniciar smbd
    if systemctl start smbd; then
        print_message "Servicio smbd iniciado"
    else
        print_error "Error al iniciar smbd"
        systemctl status smbd --no-pager -l
        return 1
    fi
    
    # Intentar iniciar nmbd
    if systemctl start nmbd; then
        print_message "Servicio nmbd iniciado"
    else
        print_warning "Error al iniciar nmbd, continuando sin NetBIOS..."
        systemctl status nmbd --no-pager -l
    fi
    
    # Verificar que al menos smbd esté corriendo
    sleep 2  # Dar tiempo para que los servicios se inicien
    
    if systemctl is-active --quiet smbd; then
        print_success "Servicios de Samba configurados correctamente"
        
        # Mostrar estado de los servicios
        print_message "Estado de servicios:"
        systemctl is-active smbd && echo "  ✅ smbd: Activo" || echo "  ❌ smbd: Inactivo"
        systemctl is-active nmbd && echo "  ✅ nmbd: Activo" || echo "  ⚠️  nmbd: Inactivo"
    else
        print_error "El servicio principal smbd no está corriendo"
        return 1
    fi
    
    # Configurar firewall si UFW está instalado y activo
    if command -v ufw &> /dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        print_message "Configurando firewall UFW..."
        if ufw allow samba 2>/dev/null; then
            print_success "Reglas de firewall configuradas"
        else
            print_warning "Error al configurar firewall, continuando..."
        fi
    else
        print_message "UFW no está activo o no está instalado"
    fi
}

# Crear scripts de gestión
create_management_scripts() {
    print_header "Creando Scripts de Gestión"
    
    # Script de gestión de Samba
    cat > /opt/samba/samba-manager.sh << 'EOF'
#!/bin/bash

# 🛠️ Gestor de Samba - Herramienta de administración
# Desarrollado por MondoBoricua

# Colores pa' que se vea chévere
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

show_menu() {
    print_header "Gestor de Samba"
    echo "1. Listar usuarios de Samba"
    echo "2. Agregar nuevo usuario"
    echo "3. Cambiar contraseña de usuario"
    echo "4. Eliminar usuario"
    echo "5. Mostrar recursos compartidos"
    echo "6. Ver conexiones activas"
    echo "7. Verificar configuración"
    echo "8. Reiniciar servicios"
    echo "9. Ver logs"
    echo "0. Salir"
    echo
    read -p "Selecciona una opción: " choice
}

list_users() {
    echo -e "${GREEN}Usuarios de Samba:${NC}"
    pdbedit -L
}

add_user() {
    read -p "Nombre del nuevo usuario: " username
    if [ -z "$username" ]; then
        echo -e "${RED}El nombre de usuario no puede estar vacío${NC}"
        return
    fi
    
    # Crear usuario del sistema si no existe
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash -G sambashare "$username"
        echo "Usuario del sistema creado"
    else
        usermod -a -G sambashare "$username"
    fi
    
    # Crear directorio personal
    mkdir -p "/srv/samba/users/$username"
    chown "$username:sambashare" "/srv/samba/users/$username"
    chmod 755 "/srv/samba/users/$username"
    
    # Agregar a Samba
    smbpasswd -a "$username"
    smbpasswd -e "$username"
    
    echo -e "${GREEN}Usuario $username creado exitosamente${NC}"
}

change_password() {
    read -p "Usuario para cambiar contraseña: " username
    if pdbedit -L | grep -q "^$username:"; then
        smbpasswd "$username"
        echo -e "${GREEN}Contraseña cambiada exitosamente${NC}"
    else
        echo -e "${RED}Usuario no encontrado${NC}"
    fi
}

remove_user() {
    read -p "Usuario a eliminar: " username
    read -p "¿Estás seguro? (s/n): " confirm
    if [[ $confirm == "s" || $confirm == "S" ]]; then
        smbpasswd -x "$username" 2>/dev/null || true
        userdel "$username" 2>/dev/null || true
        rm -rf "/srv/samba/users/$username"
        echo -e "${GREEN}Usuario $username eliminado${NC}"
    fi
}

show_shares() {
    echo -e "${GREEN}Recursos compartidos:${NC}"
    smbclient -L localhost -N 2>/dev/null | grep -E "^\s*[A-Za-z]" | grep -v "IPC\|ADMIN"
}

show_connections() {
    echo -e "${GREEN}Conexiones activas:${NC}"
    smbstatus -b 2>/dev/null || echo "No hay conexiones activas"
}

verify_config() {
    echo -e "${GREEN}Verificando configuración:${NC}"
    testparm -s
}

restart_services() {
    echo "Reiniciando servicios de Samba..."
    systemctl restart smbd nmbd
    echo -e "${GREEN}Servicios reiniciados${NC}"
}

show_logs() {
    echo -e "${GREEN}Últimas entradas del log:${NC}"
    tail -20 /var/log/samba/log.smbd 2>/dev/null || echo "No hay logs disponibles"
}

# Función principal
main() {
    if [[ $1 == "add-user" ]]; then
        add_user
    elif [[ $1 == "list-users" ]]; then
        list_users
    elif [[ $1 == "change-password" ]]; then
        change_password
    elif [[ $1 == "remove-user" ]]; then
        remove_user
    elif [[ $1 == "add-share" ]]; then
        echo "Funcionalidad en desarrollo"
    else
        while true; do
            show_menu
            case $choice in
                1) list_users ;;
                2) add_user ;;
                3) change_password ;;
                4) remove_user ;;
                5) show_shares ;;
                6) show_connections ;;
                7) verify_config ;;
                8) restart_services ;;
                9) show_logs ;;
                0) exit 0 ;;
                *) echo -e "${RED}Opción inválida${NC}" ;;
            esac
            echo
            read -p "Presiona Enter para continuar..."
        done
    fi
}

main "$@"
EOF

    chmod +x /opt/samba/samba-manager.sh
    print_success "Script de gestión creado en /opt/samba/samba-manager.sh"
}

# Crear pantalla de bienvenida
create_welcome_screen() {
    print_header "Creando Pantalla de Bienvenida"
    
    cat > /opt/samba/welcome.sh << 'EOF'
#!/bin/bash

# 🎉 Pantalla de Bienvenida para Servidor Samba
# Desarrollado por MondoBoricua

# Colores para hacer que se vea chévere
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Obtener información del sistema
SERVER_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
UPTIME=$(uptime -p)

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}              🗂️  SERVIDOR SAMBA PROXMOX LXC                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_server_info() {
    echo -e "${CYAN}🖥️  INFORMACIÓN DEL SERVIDOR${NC}"
    echo -e "   📍 Hostname: ${GREEN}$HOSTNAME${NC}"
    echo -e "   🌐 IP Address: ${GREEN}$SERVER_IP${NC}"
    echo -e "   ⏱️  Uptime: ${GREEN}$UPTIME${NC}"
    echo
}

print_samba_status() {
    echo -e "${CYAN}🔄 ESTADO DE SERVICIOS SAMBA${NC}"
    
    # Verificar estado de smbd
    if systemctl is-active --quiet smbd; then
        echo -e "   📡 SMB Daemon: ${GREEN}✅ Activo${NC}"
    else
        echo -e "   📡 SMB Daemon: ${RED}❌ Inactivo${NC}"
    fi
    
    # Verificar estado de nmbd
    if systemctl is-active --quiet nmbd; then
        echo -e "   🔍 NetBIOS Daemon: ${GREEN}✅ Activo${NC}"
    else
        echo -e "   🔍 NetBIOS Daemon: ${RED}❌ Inactivo${NC}"
    fi
    
    # Mostrar puertos activos
    echo -e "   🔌 Puertos: ${GREEN}139, 445${NC}"
    echo
}

print_shares() {
    echo -e "${CYAN}📂 RECURSOS COMPARTIDOS${NC}"
    
    # Obtener lista de compartidos
    shares=$(smbclient -L localhost -N 2>/dev/null | grep -E "^\s*[A-Za-z]" | grep -v "IPC\|ADMIN" | awk '{print $1}' || echo "")
    
    if [ -n "$shares" ]; then
        while IFS= read -r share; do
            if [ -n "$share" ]; then
                echo -e "   📁 ${GREEN}\\\\$SERVER_IP\\$share${NC}"
            fi
        done <<< "$shares"
    else
        echo -e "   ${YELLOW}No hay recursos compartidos configurados${NC}"
    fi
    echo
}

print_users() {
    echo -e "${CYAN}👥 USUARIOS DE SAMBA${NC}"
    
    # Obtener lista de usuarios
    users=$(pdbedit -L 2>/dev/null | cut -d: -f1 || echo "")
    
    if [ -n "$users" ]; then
        while IFS= read -r user; do
            if [ -n "$user" ]; then
                echo -e "   👤 ${GREEN}$user${NC}"
            fi
        done <<< "$users"
    else
        echo -e "   ${YELLOW}No hay usuarios configurados${NC}"
    fi
    echo
}

print_connections() {
    echo -e "${CYAN}🔗 CONEXIONES ACTIVAS${NC}"
    
    # Obtener conexiones activas
    connections=$(smbstatus -b 2>/dev/null | grep -v "^Samba\|^=\|^$\|PID\|Service\|^---" | wc -l)
    
    if [ "$connections" -gt 0 ]; then
        echo -e "   📊 Conexiones activas: ${GREEN}$connections${NC}"
        smbstatus -b 2>/dev/null | grep -v "^Samba\|^=\|^$\|PID\|Service\|^---" | head -5
    else
        echo -e "   📊 ${YELLOW}No hay conexiones activas${NC}"
    fi
    echo
}

print_commands() {
    echo -e "${CYAN}🛠️  COMANDOS ÚTILES${NC}"
    echo -e "   📋 Ver información: ${GREEN}samba-info${NC}"
    echo -e "   🔧 Gestionar Samba: ${GREEN}/opt/samba/samba-manager.sh${NC}"
    echo -e "   📊 Ver conexiones: ${GREEN}smbstatus${NC}"
    echo -e "   🔍 Verificar config: ${GREEN}testparm${NC}"
    echo -e "   📝 Ver logs: ${GREEN}tail -f /var/log/samba/log.smbd${NC}"
    echo
}

print_access_info() {
    echo -e "${CYAN}🌐 CÓMO CONECTARSE${NC}"
    echo -e "   🖥️  Desde Windows: ${GREEN}\\\\$SERVER_IP${NC}"
    echo -e "   🐧 Desde Linux: ${GREEN}smb://$SERVER_IP${NC}"
    echo -e "   📱 Desde móvil: ${GREEN}smb://$SERVER_IP${NC}"
    echo
}

# Función principal
main() {
    clear
    print_header
    print_server_info
    print_samba_status
    print_shares
    print_users
    print_connections
    print_access_info
    print_commands
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}            Desarrollado con ❤️  por MondoBoricua              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

main "$@"
EOF

    chmod +x /opt/samba/welcome.sh
    
    # Crear alias para acceso rápido
    echo 'alias samba-info="/opt/samba/welcome.sh"' >> /root/.bashrc
    
    # Configurar para que se ejecute al login
    echo '/opt/samba/welcome.sh' >> /root/.bashrc
    
    print_success "Pantalla de bienvenida configurada"
}

# Crear script de backup
create_backup_script() {
    cat > /opt/samba/backup-config.sh << 'EOF'
#!/bin/bash

# 💾 Script de Backup para Configuración de Samba
# Desarrollado por MondoBoricua

BACKUP_DIR="/opt/samba/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="samba_backup_$DATE.tar.gz"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

echo "Creando backup de configuración de Samba..."

# Crear backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    /etc/samba/ \
    /srv/samba/ \
    /opt/samba/ \
    --exclude="$BACKUP_DIR" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Backup creado exitosamente: $BACKUP_DIR/$BACKUP_FILE"
    
    # Mantener solo los últimos 5 backups
    cd "$BACKUP_DIR"
    ls -t samba_backup_*.tar.gz | tail -n +6 | xargs -r rm
    
    echo "📁 Backups disponibles:"
    ls -lh samba_backup_*.tar.gz 2>/dev/null || echo "No hay backups anteriores"
else
    echo "❌ Error al crear el backup"
    exit 1
fi
EOF

    chmod +x /opt/samba/backup-config.sh
    print_success "Script de backup creado en /opt/samba/backup-config.sh"
}

# Mostrar información final
show_final_info() {
    print_header "🎉 INSTALACIÓN COMPLETADA"
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}✅ Servidor Samba configurado exitosamente${NC}"
    echo
    echo -e "${CYAN}📋 INFORMACIÓN DEL SERVIDOR:${NC}"
    echo -e "   🌐 IP del servidor: ${GREEN}$SERVER_IP${NC}"
    echo -e "   🖥️  Nombre del servidor: ${GREEN}$SERVER_NAME${NC}"
    echo -e "   👥 Grupo de trabajo: ${GREEN}$WORKGROUP${NC}"
    echo
    
    if [[ $CREATE_ADMIN == "s" || $CREATE_ADMIN == "S" ]]; then
        echo -e "${CYAN}👤 USUARIO ADMINISTRADOR:${NC}"
        echo -e "   📝 Usuario: ${GREEN}$ADMIN_USER${NC}"
        echo -e "   🔑 Contraseña: ${YELLOW}[La que configuraste]${NC}"
        echo
    fi
    
    echo -e "${CYAN}🔗 CÓMO CONECTARSE:${NC}"
    echo -e "   🖥️  Desde Windows: ${GREEN}\\\\$SERVER_IP${NC}"
    echo -e "   🐧 Desde Linux: ${GREEN}smb://$SERVER_IP${NC}"
    echo -e "   📱 Desde móvil: ${GREEN}smb://$SERVER_IP${NC}"
    echo
    
    echo -e "${CYAN}🛠️  HERRAMIENTAS DISPONIBLES:${NC}"
    echo -e "   📊 Ver información: ${GREEN}samba-info${NC}"
    echo -e "   🔧 Gestionar usuarios: ${GREEN}/opt/samba/samba-manager.sh${NC}"
    echo -e "   💾 Crear backup: ${GREEN}/opt/samba/backup-config.sh${NC}"
    echo
    
    echo -e "${CYAN}📂 RECURSOS COMPARTIDOS CREADOS:${NC}"
    if [[ $CREATE_PUBLIC == "s" || $CREATE_PUBLIC == "S" ]]; then
        echo -e "   📁 ${GREEN}public${NC} - Acceso público sin autenticación"
    fi
    if [[ $CREATE_PRIVATE == "s" || $CREATE_PRIVATE == "S" ]]; then
        echo -e "   🔒 ${GREEN}private${NC} - Solo usuarios autenticados"
    fi
    if [[ $CREATE_ADMIN == "s" || $CREATE_ADMIN == "S" ]]; then
        echo -e "   👤 ${GREEN}$ADMIN_USER${NC} - Directorio personal del administrador"
    fi
    echo
    
    print_success "¡Listo pa' usar! Tu servidor Samba está funcionando perfectamente."
}

# Función de logging para debug
log_debug() {
    if [ "${DEBUG_MODE:-false}" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Función para ejecutar comandos con logging
run_command() {
    local cmd="$1"
    local description="$2"
    
    log_debug "Ejecutando: $cmd"
    
    if eval "$cmd"; then
        log_debug "$description - ÉXITO"
        return 0
    else
        local exit_code=$?
        log_debug "$description - ERROR (código: $exit_code)"
        return $exit_code
    fi
}

# Configuración automática para modo no interactivo
setup_auto_config() {
    # Configuración por defecto para instalación automática
    SERVER_NAME="samba-server"
    WORKGROUP="WORKGROUP"
    CREATE_ADMIN="n"  # No crear usuario admin en modo auto
    CREATE_PUBLIC="s"
    CREATE_PRIVATE="s"
    
    print_message "Modo automático activado - usando configuración por defecto"
    print_message "Servidor: $SERVER_NAME, Grupo: $WORKGROUP"
    print_message "Recursos: público y privado (sin usuario admin)"
    
    # Activar modo debug en automático para mejor diagnóstico
    DEBUG_MODE=true
    log_debug "Modo debug activado para instalación automática"
}

# Función principal
main() {
    # Verificar si se ejecuta en modo automático
    AUTO_MODE=false
    for arg in "$@"; do
        case $arg in
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --help|-h)
                echo "🗂️ Instalador de Samba para Proxmox LXC"
                echo "Uso: $0 [--auto] [--help]"
                echo
                echo "Opciones:"
                echo "  --auto    Instalación automática sin interacción"
                echo "  --help    Mostrar esta ayuda"
                exit 0
                ;;
        esac
    done
    
    print_header "🗂️ Instalador de Samba para Proxmox LXC"
    echo -e "${CYAN}Desarrollado por MondoBoricua para la comunidad${NC}"
    echo
    
    # Verificaciones iniciales
    check_root
    detect_os
    
    # Configuración según el modo
    if [ "$AUTO_MODE" = true ]; then
        setup_auto_config
    else
        get_user_input
    fi
    
    # Proceso de instalación con manejo de errores
    log_debug "Iniciando proceso de instalación..."
    
    print_message "📦 Instalando dependencias..."
    if ! install_dependencies; then
        print_error "Error crítico al instalar dependencias"
        exit 1
    fi
    
    print_message "📁 Creando directorios..."
    if ! create_directories; then
        print_error "Error crítico al crear directorios"
        exit 1
    fi
    
    print_message "👥 Configurando grupo de Samba..."
    if ! create_samba_group; then
        print_warning "Error al configurar grupo, continuando..."
    fi
    
    print_message "👤 Creando usuarios..."
    if ! create_users; then
        print_warning "Error al crear usuarios, continuando..."
    fi
    
    print_message "⚙️ Configurando Samba..."
    if ! configure_samba; then
        print_error "Error crítico al configurar Samba"
        exit 1
    fi
    
    print_message "🔄 Configurando servicios..."
    if ! configure_services; then
        print_error "Error crítico al configurar servicios"
        exit 1
    fi
    
    print_message "🛠️ Creando scripts de gestión..."
    if ! create_management_scripts; then
        print_warning "Error al crear scripts de gestión, continuando..."
    fi
    
    print_message "🎉 Creando pantalla de bienvenida..."
    if ! create_welcome_screen; then
        print_warning "Error al crear pantalla de bienvenida, continuando..."
    fi
    
    print_message "💾 Creando script de backup..."
    if ! create_backup_script; then
        print_warning "Error al crear script de backup, continuando..."
    fi
    
    # Información final
    show_final_info
    
    # Ejecutar pantalla de bienvenida solo en modo interactivo
    if [ "$AUTO_MODE" = false ]; then
        echo
        read -p "¿Quieres ver la pantalla de bienvenida ahora? (s/n) [s]: " SHOW_WELCOME
        SHOW_WELCOME=${SHOW_WELCOME:-s}
        
        if [[ $SHOW_WELCOME == "s" || $SHOW_WELCOME == "S" ]]; then
            /opt/samba/welcome.sh
        fi
    else
        print_success "Instalación automática completada. Usa 'samba-info' para ver el estado."
    fi
}

# Ejecutar función principal
main "$@" 