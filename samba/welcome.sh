#!/bin/bash

# 🎉 Pantalla de Bienvenida para Servidor Samba LXC
# Desarrollado por MondoBoricua para la comunidad de Proxmox
# Versión: 1.0

# Colores para hacer que se vea chévere
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Obtener información del sistema
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "No disponible")
HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
UPTIME=$(uptime -p 2>/dev/null || echo "No disponible")

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
    if systemctl is-active --quiet smbd 2>/dev/null; then
        echo -e "   📡 SMB Daemon: ${GREEN}✅ Activo${NC}"
    else
        echo -e "   📡 SMB Daemon: ${RED}❌ Inactivo${NC}"
    fi
    
    # Verificar estado de nmbd
    if systemctl is-active --quiet nmbd 2>/dev/null; then
        echo -e "   🔍 NetBIOS Daemon: ${GREEN}✅ Activo${NC}"
    else
        echo -e "   🔍 NetBIOS Daemon: ${RED}❌ Inactivo${NC}"
    fi
    
    # Mostrar puertos activos
    echo -e "   🔌 Puertos: ${GREEN}139, 445${NC}"
    
    # Verificar si los puertos están escuchando
    if netstat -tlnp 2>/dev/null | grep -q ":445 "; then
        echo -e "   🔗 Puerto 445: ${GREEN}✅ Escuchando${NC}"
    else
        echo -e "   🔗 Puerto 445: ${RED}❌ No disponible${NC}"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":139 "; then
        echo -e "   🔗 Puerto 139: ${GREEN}✅ Escuchando${NC}"
    else
        echo -e "   🔗 Puerto 139: ${RED}❌ No disponible${NC}"
    fi
    echo
}

print_shares() {
    echo -e "${CYAN}📂 RECURSOS COMPARTIDOS${NC}"
    
    # Verificar si Samba está instalado
    if ! command -v smbclient &> /dev/null; then
        echo -e "   ${YELLOW}Samba no está instalado${NC}"
        echo
        return
    fi
    
    # Obtener lista de compartidos
    shares=$(smbclient -L localhost -N 2>/dev/null | grep -E "^\s*[A-Za-z]" | grep -v "IPC\|ADMIN" | awk '{print $1}' 2>/dev/null || echo "")
    
    if [ -n "$shares" ]; then
        while IFS= read -r share; do
            if [ -n "$share" ]; then
                # Verificar si el directorio existe
                share_path=""
                if [ -f /etc/samba/smb.conf ]; then
                    share_path=$(grep -A 10 "^\[$share\]" /etc/samba/smb.conf | grep "path" | head -1 | awk -F= '{print $2}' | sed 's/^ *//' 2>/dev/null || echo "")
                fi
                
                if [ -n "$share_path" ] && [ -d "$share_path" ]; then
                    echo -e "   📁 ${GREEN}\\\\$SERVER_IP\\$share${NC} → $share_path"
                else
                    echo -e "   📁 ${GREEN}\\\\$SERVER_IP\\$share${NC}"
                fi
            fi
        done <<< "$shares"
    else
        echo -e "   ${YELLOW}No hay recursos compartidos configurados${NC}"
    fi
    echo
}

print_users() {
    echo -e "${CYAN}👥 USUARIOS DE SAMBA${NC}"
    
    # Verificar si pdbedit está disponible
    if ! command -v pdbedit &> /dev/null; then
        echo -e "   ${YELLOW}Herramienta pdbedit no disponible${NC}"
        echo
        return
    fi
    
    # Obtener lista de usuarios
    users=$(pdbedit -L 2>/dev/null | cut -d: -f1 || echo "")
    
    if [ -n "$users" ]; then
        user_count=0
        while IFS= read -r user; do
            if [ -n "$user" ]; then
                echo -e "   👤 ${GREEN}$user${NC}"
                user_count=$((user_count + 1))
            fi
        done <<< "$users"
        
        if [ $user_count -eq 0 ]; then
            echo -e "   ${YELLOW}No hay usuarios configurados${NC}"
        fi
    else
        echo -e "   ${YELLOW}No hay usuarios configurados${NC}"
    fi
    echo
}

print_connections() {
    echo -e "${CYAN}🔗 CONEXIONES ACTIVAS${NC}"
    
    # Verificar si smbstatus está disponible
    if ! command -v smbstatus &> /dev/null; then
        echo -e "   ${YELLOW}Herramienta smbstatus no disponible${NC}"
        echo
        return
    fi
    
    # Obtener conexiones activas
    connections=$(smbstatus -b 2>/dev/null | grep -v "^Samba\|^=\|^$\|PID\|Service\|^---" | wc -l 2>/dev/null || echo "0")
    
    if [ "$connections" -gt 0 ]; then
        echo -e "   📊 Conexiones activas: ${GREEN}$connections${NC}"
        
        # Mostrar las primeras 5 conexiones
        echo -e "   ${CYAN}Detalles de conexiones:${NC}"
        smbstatus -b 2>/dev/null | grep -v "^Samba\|^=\|^$\|PID\|Service\|^---" | head -5 | while read line; do
            if [ -n "$line" ]; then
                echo -e "   ${GREEN}→${NC} $line"
            fi
        done
    else
        echo -e "   📊 ${YELLOW}No hay conexiones activas${NC}"
    fi
    echo
}

print_disk_usage() {
    echo -e "${CYAN}💾 USO DE DISCO${NC}"
    
    # Mostrar uso de disco de los directorios de Samba
    if [ -d /srv/samba ]; then
        total_size=$(du -sh /srv/samba 2>/dev/null | awk '{print $1}' || echo "N/A")
        echo -e "   📦 Tamaño total: ${GREEN}$total_size${NC}"
        
        # Mostrar uso por directorio
        if [ -d /srv/samba/public ]; then
            public_size=$(du -sh /srv/samba/public 2>/dev/null | awk '{print $1}' || echo "N/A")
            echo -e "   📁 Public: ${GREEN}$public_size${NC}"
        fi
        
        if [ -d /srv/samba/private ]; then
            private_size=$(du -sh /srv/samba/private 2>/dev/null | awk '{print $1}' || echo "N/A")
            echo -e "   🔒 Private: ${GREEN}$private_size${NC}"
        fi
        
        if [ -d /srv/samba/users ]; then
            users_size=$(du -sh /srv/samba/users 2>/dev/null | awk '{print $1}' || echo "N/A")
            echo -e "   👥 Users: ${GREEN}$users_size${NC}"
        fi
    else
        echo -e "   ${YELLOW}Directorio /srv/samba no encontrado${NC}"
    fi
    echo
}

print_commands() {
    echo -e "${CYAN}🛠️  COMANDOS ÚTILES${NC}"
    echo -e "   📋 Ver información: ${GREEN}samba-info${NC} o ${GREEN}/opt/samba/welcome.sh${NC}"
    
    if [ -f /opt/samba/samba-manager.sh ]; then
        echo -e "   🔧 Gestionar Samba: ${GREEN}/opt/samba/samba-manager.sh${NC}"
    fi
    
    echo -e "   📊 Ver conexiones: ${GREEN}smbstatus${NC}"
    echo -e "   🔍 Verificar config: ${GREEN}testparm${NC}"
    echo -e "   📝 Ver logs: ${GREEN}tail -f /var/log/samba/log.smbd${NC}"
    echo -e "   🔄 Reiniciar Samba: ${GREEN}systemctl restart smbd nmbd${NC}"
    echo -e "   📈 Ver estado: ${GREEN}systemctl status smbd nmbd${NC}"
    
    if [ -f /opt/samba/backup-config.sh ]; then
        echo -e "   💾 Crear backup: ${GREEN}/opt/samba/backup-config.sh${NC}"
    fi
    echo
}

print_access_info() {
    echo -e "${CYAN}🌐 CÓMO CONECTARSE${NC}"
    echo -e "   🖥️  Desde Windows: ${GREEN}\\\\$SERVER_IP${NC}"
    echo -e "   🐧 Desde Linux: ${GREEN}smb://$SERVER_IP${NC}"
    echo -e "   📱 Desde móvil: ${GREEN}smb://$SERVER_IP${NC}"
    echo
    
    echo -e "${CYAN}📋 COMANDOS DE CONEXIÓN${NC}"
    echo -e "   🐧 Linux mount: ${GREEN}sudo mount -t cifs //$SERVER_IP/public /mnt/samba${NC}"
    echo -e "   🐧 smbclient: ${GREEN}smbclient //$SERVER_IP/public${NC}"
    echo
}

print_network_info() {
    echo -e "${CYAN}🌐 INFORMACIÓN DE RED${NC}"
    
    # Mostrar todas las interfaces de red
    interfaces=$(ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 || echo "")
    
    if [ -n "$interfaces" ]; then
        echo -e "   📡 Interfaces de red:"
        while IFS= read -r ip; do
            if [ -n "$ip" ]; then
                echo -e "     ${GREEN}→${NC} $ip"
            fi
        done <<< "$interfaces"
    fi
    
    # Mostrar gateway si está disponible
    gateway=$(ip route show default 2>/dev/null | awk '{print $3}' | head -1 || echo "")
    if [ -n "$gateway" ]; then
        echo -e "   🚪 Gateway: ${GREEN}$gateway${NC}"
    fi
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
    print_disk_usage
    print_network_info
    print_access_info
    print_commands
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}        Desarrollado  con mucho ☕ por MondoBoricua              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Verificar argumentos
case "${1:-}" in
    --help|-h)
        echo "🗂️ Pantalla de Bienvenida para Servidor Samba"
        echo "Uso: $0 [--help|--status|--quick]"
        echo
        echo "Opciones:"
        echo "  --help, -h     Mostrar esta ayuda"
        echo "  --status       Mostrar solo el estado de servicios"
        echo "  --quick        Mostrar información básica"
        echo "  (sin args)     Mostrar información completa"
        exit 0
        ;;
    --status)
        print_samba_status
        exit 0
        ;;
    --quick)
        print_header
        print_server_info
        print_samba_status
        print_shares
        echo -e "${CYAN}Para información completa ejecuta: ${GREEN}$0${NC}"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 