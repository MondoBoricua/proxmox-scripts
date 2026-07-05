#!/bin/bash

# Script para configurar FTP en contenedor nginx
# Desarrollado con ❤️ para la comunidad de Proxmox
# Hecho en 🇵🇷 Puerto Rico con mucho ☕ café

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${WHITE}[STEP]${NC} $1"
}

# Verificar si somos root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Instalar y configurar vsftpd
install_ftp() {
    log_step "Instalando servidor FTP (vsftpd)..."
    
    # Actualizar e instalar vsftpd
    apt update
    apt install -y vsftpd
    
    # Backup de configuración original
    cp /etc/vsftpd.conf /etc/vsftpd.conf.backup
    
    # Crear configuración optimizada
    cat > /etc/vsftpd.conf << 'EOF'
# Configuración vsftpd para nginx-server
# Desarrollado con ❤️ para la comunidad de Proxmox

# Configuración básica
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

# Configuración de seguridad
ftpd_banner=Nginx Server FTP Ready
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO

# Configuración de usuarios
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Configuración de puertos
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110

# Configuración de logs
log_ftp_protocol=YES
xferlog_file=/var/log/vsftpd.log

# Configuración de timeouts
idle_session_timeout=300
data_connection_timeout=300
EOF
    
    log_success "vsftpd instalado y configurado"
}

# Configurar usuario FTP
setup_ftp_user() {
    log_step "Configurando usuario FTP..."
    
    # Crear usuario web si no existe
    if ! id "webuser" &>/dev/null; then
        log_info "Creando usuario webuser..."
        useradd -m -d /var/www -s /bin/bash webuser
        
        # Establecer contraseña
        echo "webuser:webpass123" | chpasswd
        log_warning "Contraseña por defecto: webpass123"
        log_warning "¡Cambia la contraseña después!"
    fi
    
    # Configurar permisos
    chown -R webuser:webuser /var/www
    chmod -R 755 /var/www
    
    # Agregar usuario a lista permitida
    echo "webuser" > /etc/vsftpd.userlist
    echo "root" >> /etc/vsftpd.userlist
    
    log_success "Usuario FTP configurado"
}

# Configurar firewall
setup_firewall() {
    log_step "Configurando firewall para FTP..."
    
    if command -v ufw &> /dev/null; then
        # Permitir FTP (puerto 21)
        ufw allow 21/tcp
        
        # Permitir rango de puertos pasivos
        ufw allow 21100:21110/tcp
        
        log_success "Firewall configurado para FTP"
    else
        log_warning "UFW no está instalado, configuración manual requerida"
    fi
}

# Iniciar servicios
start_services() {
    log_step "Iniciando servicios FTP..."
    
    # Habilitar e iniciar vsftpd
    systemctl enable vsftpd
    systemctl start vsftpd
    
    if systemctl is-active --quiet vsftpd; then
        log_success "Servidor FTP iniciado correctamente"
    else
        log_error "Error al iniciar servidor FTP"
        return 1
    fi
}

# Mostrar información de conexión
show_connection_info() {
    local server_ip=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${WHITE}🌐 Información de conexión FTP:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "Servidor: $server_ip"
    echo -e "Puerto: 21"
    echo -e "Usuario: webuser"
    echo -e "Contraseña: webpass123"
    echo -e "Directorio: /var/www"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    echo -e "\n${WHITE}📁 Configuración FileZilla:${NC}"
    echo -e "Protocolo: FTP"
    echo -e "Servidor: $server_ip"
    echo -e "Puerto: 21"
    echo -e "Usuario: webuser"
    echo -e "Contraseña: webpass123"
    echo -e "Modo: Pasivo"
    
    echo -e "\n${YELLOW}⚠️  Importante:${NC}"
    echo -e "1. Cambia la contraseña: passwd webuser"
    echo -e "2. El directorio web es: /var/www"
    echo -e "3. Usa modo pasivo en FileZilla"
    
    echo -e "\n${WHITE}🔒 Para mayor seguridad, usa SFTP:${NC}"
    echo -e "Protocolo: SFTP"
    echo -e "Servidor: $server_ip"
    echo -e "Puerto: 22"
    echo -e "Usuario: root"
    echo -e "Contraseña: [contraseña de root]"
}

# Configurar SFTP (alternativa más segura)
setup_sftp() {
    log_step "Configurando SFTP (recomendado)..."
    
    # Asegurar que SSH esté instalado
    apt install -y openssh-server
    
    # Configurar SSH para permitir root login
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    
    # Reiniciar SSH
    systemctl restart ssh
    
    # Configurar contraseña de root si no está configurada
    if ! passwd -S root | grep -q "P"; then
        log_warning "Configurando contraseña de root..."
        echo "root:nginx123" | chpasswd
        log_warning "Contraseña de root: nginx123"
        log_warning "¡Cambia la contraseña después!"
    fi
    
    log_success "SFTP configurado"
    
    local server_ip=$(hostname -I | awk '{print $1}')
    echo -e "\n${WHITE}🔐 Configuración SFTP (Recomendado):${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "Protocolo: SFTP"
    echo -e "Servidor: $server_ip"
    echo -e "Puerto: 22"
    echo -e "Usuario: root"
    echo -e "Contraseña: nginx123"
    echo -e "Directorio: /var/www"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# Menú principal
show_menu() {
    echo -e "${WHITE}🔧 Configuración FTP/SFTP para nginx-server${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════${NC}"
    echo -e "   ${YELLOW}1.${NC} Configurar FTP (vsftpd)"
    echo -e "   ${YELLOW}2.${NC} Configurar SFTP (recomendado)"
    echo -e "   ${YELLOW}3.${NC} Configurar ambos"
    echo -e "   ${YELLOW}4.${NC} Mostrar información de conexión"
    echo -e "   ${YELLOW}0.${NC} Salir"
    echo
}

# Función principal
main() {
    check_root
    
    if [ $# -eq 0 ]; then
        # Menú interactivo
        while true; do
            show_menu
            read -p "Selecciona una opción: " choice
            
            case $choice in
                1)
                    install_ftp
                    setup_ftp_user
                    setup_firewall
                    start_services
                    show_connection_info
                    ;;
                2)
                    setup_sftp
                    ;;
                3)
                    install_ftp
                    setup_ftp_user
                    setup_firewall
                    start_services
                    setup_sftp
                    show_connection_info
                    ;;
                4)
                    show_connection_info
                    ;;
                0)
                    log_info "¡Hasta luego!"
                    exit 0
                    ;;
                *)
                    log_error "Opción inválida"
                    ;;
            esac
            
            echo
            read -p "Presiona Enter para continuar..."
        done
    else
        # Modo automático
        case $1 in
            "ftp")
                install_ftp
                setup_ftp_user
                setup_firewall
                start_services
                show_connection_info
                ;;
            "sftp")
                setup_sftp
                ;;
            "both")
                install_ftp
                setup_ftp_user
                setup_firewall
                start_services
                setup_sftp
                show_connection_info
                ;;
            *)
                log_error "Opción desconocida: $1"
                echo "Uso: $0 [ftp|sftp|both]"
                exit 1
                ;;
        esac
    fi
}

# Ejecutar función principal
main "$@" 