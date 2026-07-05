#!/bin/bash

# 🌐 Welcome Screen - Pantalla de Bienvenida para Nginx Server
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

# Función para obtener información del sistema
get_system_info() {
    # Información básica del sistema
    HOSTNAME=$(hostname)
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    UPTIME=$(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f4-)
    LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    
    # Información de memoria
    MEMORY_INFO=$(free -h | grep Mem)
    MEMORY_USED=$(echo $MEMORY_INFO | awk '{print $3}')
    MEMORY_TOTAL=$(echo $MEMORY_INFO | awk '{print $2}')
    MEMORY_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # Información de disco
    DISK_INFO=$(df -h / | tail -1)
    DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
    DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
    DISK_PERCENT=$(echo $DISK_INFO | awk '{print $5}')
    
    # Información de CPU
    CPU_CORES=$(nproc)
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    
    # Información de red
    NETWORK_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    
    # Información del contenedor (si aplica)
    if [ -f "/proc/1/environ" ] && grep -q "container" /proc/1/environ 2>/dev/null; then
        CONTAINER_TYPE="LXC"
    else
        CONTAINER_TYPE="Físico/VM"
    fi
}

# Función para obtener información de nginx
get_nginx_info() {
    # Estado del servicio nginx
    if systemctl is-active --quiet nginx; then
        NGINX_STATUS="activo"
        NGINX_STATUS_COLOR="$GREEN"
        NGINX_STATUS_ICON="✅"
    else
        NGINX_STATUS="inactivo"
        NGINX_STATUS_COLOR="$RED"
        NGINX_STATUS_ICON="❌"
    fi
    
    # Versión de nginx
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)
    
    # Tiempo de actividad del servicio
    if systemctl is-active --quiet nginx; then
        NGINX_UPTIME=$(systemctl show nginx --property=ActiveEnterTimestamp --value | xargs -I {} date -d {} +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Desconocido")
    else
        NGINX_UPTIME="No está ejecutándose"
    fi
    
    # Configuración nginx
    NGINX_CONFIG_TEST=$(nginx -t 2>&1)
    if echo "$NGINX_CONFIG_TEST" | grep -q "syntax is ok"; then
        NGINX_CONFIG_STATUS="válida"
        NGINX_CONFIG_COLOR="$GREEN"
        NGINX_CONFIG_ICON="✅"
    else
        NGINX_CONFIG_STATUS="con errores"
        NGINX_CONFIG_COLOR="$RED"
        NGINX_CONFIG_ICON="❌"
    fi
    
    # Número de sitios
    SITES_AVAILABLE=$(find /etc/nginx/sites-available -maxdepth 1 -type f | wc -l)
    SITES_ENABLED=$(find /etc/nginx/sites-enabled -maxdepth 1 -type l | wc -l)
    
    # Procesos nginx
    NGINX_PROCESSES=$(pgrep -c nginx 2>/dev/null || echo "0")
    
    # Puertos en uso
    NGINX_PORTS=$(netstat -tlnp 2>/dev/null | grep nginx | awk '{print $4}' | cut -d':' -f2 | sort -u | tr '\n' ' ' | xargs)
    if [ -z "$NGINX_PORTS" ]; then
        NGINX_PORTS="Ninguno"
    fi
}

# Función para obtener información de SSL
get_ssl_info() {
    SSL_CERTS_COUNT=0
    SSL_EXPIRING_SOON=0
    SSL_EXPIRED=0
    
    if [ -d "/etc/letsencrypt/live" ]; then
        for cert_dir in /etc/letsencrypt/live/*; do
            if [ -d "$cert_dir" ] && [ -f "$cert_dir/fullchain.pem" ]; then
                SSL_CERTS_COUNT=$((SSL_CERTS_COUNT + 1))
                
                # Verificar expiración
                expiry_date=$(openssl x509 -enddate -noout -in "$cert_dir/fullchain.pem" 2>/dev/null | cut -d= -f2)
                if [ -n "$expiry_date" ]; then
                    expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
                    current_timestamp=$(date +%s)
                    
                    if [ -n "$expiry_timestamp" ]; then
                        days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                        
                        if [ "$days_left" -lt 0 ]; then
                            SSL_EXPIRED=$((SSL_EXPIRED + 1))
                        elif [ "$days_left" -lt 30 ]; then
                            SSL_EXPIRING_SOON=$((SSL_EXPIRING_SOON + 1))
                        fi
                    fi
                fi
            fi
        done
    fi
}

# Función para obtener estadísticas de logs
get_log_stats() {
    # Logs de acceso del día actual
    if [ -f "/var/log/nginx/access.log" ]; then
        TODAY=$(date +"%d/%b/%Y")
        REQUESTS_TODAY=$(grep "$TODAY" /var/log/nginx/access.log 2>/dev/null | wc -l)
        
        # Últimas 24 horas
        REQUESTS_24H=$(find /var/log/nginx/ -name "*access*.log*" -mtime -1 -exec cat {} \; 2>/dev/null | wc -l)
        
        # Errores del día
        ERRORS_TODAY=$(grep "$TODAY" /var/log/nginx/error.log 2>/dev/null | wc -l)
    else
        REQUESTS_TODAY=0
        REQUESTS_24H=0
        ERRORS_TODAY=0
    fi
    
    # Tamaño de logs
    LOG_SIZE=$(du -sh /var/log/nginx/ 2>/dev/null | cut -f1 || echo "0B")
}

# Función para obtener información de seguridad
get_security_info() {
    # Estado de UFW
    if command -v ufw &> /dev/null; then
        UFW_STATUS=$(ufw status 2>/dev/null | grep "Status:" | cut -d' ' -f2)
        if [ "$UFW_STATUS" = "active" ]; then
            UFW_COLOR="$GREEN"
            UFW_ICON="✅"
        else
            UFW_COLOR="$RED"
            UFW_ICON="❌"
        fi
    else
        UFW_STATUS="no instalado"
        UFW_COLOR="$YELLOW"
        UFW_ICON="⚠️"
    fi
    
    # Estado de Fail2ban
    if command -v fail2ban-client &> /dev/null; then
        if systemctl is-active --quiet fail2ban; then
            FAIL2BAN_STATUS="activo"
            FAIL2BAN_COLOR="$GREEN"
            FAIL2BAN_ICON="✅"
            
            # Número de IPs bloqueadas
            BLOCKED_IPS=$(fail2ban-client status nginx-http-auth 2>/dev/null | grep "Banned IP list" | cut -d':' -f2 | wc -w 2>/dev/null || echo "0")
        else
            FAIL2BAN_STATUS="inactivo"
            FAIL2BAN_COLOR="$RED"
            FAIL2BAN_ICON="❌"
            BLOCKED_IPS=0
        fi
    else
        FAIL2BAN_STATUS="no instalado"
        FAIL2BAN_COLOR="$YELLOW"
        FAIL2BAN_ICON="⚠️"
        BLOCKED_IPS=0
    fi
}

# Función para mostrar el banner principal
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║            🌐 NGINX WEB SERVER - INFORMACIÓN 🌐              ║"
    echo "║                                                              ║"
    echo "║              Servidor Web Optimizado para Proxmox           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar información del sistema
show_system_info() {
    echo -e "${WHITE}🖥️  Información del Sistema${NC}"
    echo -e "   ${CYAN}Hostname:${NC} $HOSTNAME"
    echo -e "   ${CYAN}IP Address:${NC} $IP_ADDRESS"
    echo -e "   ${CYAN}Tipo:${NC} $CONTAINER_TYPE"
    echo -e "   ${CYAN}Uptime:${NC} $UPTIME"
    echo -e "   ${CYAN}Load Average:${NC} $LOAD_AVERAGE"
    echo -e "   ${CYAN}CPU:${NC} $CPU_CORES cores - $CPU_MODEL"
    echo -e "   ${CYAN}Memoria:${NC} $MEMORY_USED / $MEMORY_TOTAL (${MEMORY_PERCENT}%)"
    echo -e "   ${CYAN}Disco:${NC} $DISK_USED / $DISK_TOTAL ($DISK_PERCENT usado)"
    echo -e "   ${CYAN}Red:${NC} $NETWORK_INTERFACE"
    echo
}

# Función para mostrar información de nginx
show_nginx_info() {
    echo -e "${WHITE}🌐 Estado de Nginx${NC}"
    echo -e "   ${CYAN}Estado:${NC} ${NGINX_STATUS_COLOR}${NGINX_STATUS_ICON} $NGINX_STATUS${NC}"
    echo -e "   ${CYAN}Versión:${NC} $NGINX_VERSION"
    echo -e "   ${CYAN}Configuración:${NC} ${NGINX_CONFIG_COLOR}${NGINX_CONFIG_ICON} $NGINX_CONFIG_STATUS${NC}"
    echo -e "   ${CYAN}Procesos:${NC} $NGINX_PROCESSES"
    echo -e "   ${CYAN}Puertos:${NC} $NGINX_PORTS"
    echo -e "   ${CYAN}Iniciado:${NC} $NGINX_UPTIME"
    echo -e "   ${CYAN}Sitios disponibles:${NC} $SITES_AVAILABLE"
    echo -e "   ${CYAN}Sitios habilitados:${NC} $SITES_ENABLED"
    echo
}

# Función para mostrar información de SSL
show_ssl_info() {
    echo -e "${WHITE}🔒 Certificados SSL${NC}"
    echo -e "   ${CYAN}Certificados instalados:${NC} $SSL_CERTS_COUNT"
    
    if [ "$SSL_EXPIRED" -gt 0 ]; then
        echo -e "   ${CYAN}Certificados expirados:${NC} ${RED}$SSL_EXPIRED${NC}"
    fi
    
    if [ "$SSL_EXPIRING_SOON" -gt 0 ]; then
        echo -e "   ${CYAN}Expiran pronto (< 30 días):${NC} ${YELLOW}$SSL_EXPIRING_SOON${NC}"
    fi
    
    if [ "$SSL_CERTS_COUNT" -gt 0 ] && [ "$SSL_EXPIRED" -eq 0 ] && [ "$SSL_EXPIRING_SOON" -eq 0 ]; then
        echo -e "   ${CYAN}Estado:${NC} ${GREEN}✅ Todos los certificados están válidos${NC}"
    fi
    
    echo
}

# Función para mostrar estadísticas de logs
show_log_stats() {
    echo -e "${WHITE}📊 Estadísticas de Acceso${NC}"
    echo -e "   ${CYAN}Requests hoy:${NC} $REQUESTS_TODAY"
    echo -e "   ${CYAN}Requests 24h:${NC} $REQUESTS_24H"
    echo -e "   ${CYAN}Errores hoy:${NC} $ERRORS_TODAY"
    echo -e "   ${CYAN}Tamaño de logs:${NC} $LOG_SIZE"
    echo
}

# Función para mostrar información de seguridad
show_security_info() {
    echo -e "${WHITE}🔐 Seguridad${NC}"
    echo -e "   ${CYAN}Firewall (UFW):${NC} ${UFW_COLOR}${UFW_ICON} $UFW_STATUS${NC}"
    echo -e "   ${CYAN}Fail2ban:${NC} ${FAIL2BAN_COLOR}${FAIL2BAN_ICON} $FAIL2BAN_STATUS${NC}"
    if [ "$BLOCKED_IPS" -gt 0 ]; then
        echo -e "   ${CYAN}IPs bloqueadas:${NC} $BLOCKED_IPS"
    fi
    echo
}

# Función para mostrar acceso web
show_web_access() {
    echo -e "${WHITE}🌐 Acceso Web${NC}"
    echo -e "   ${CYAN}HTTP:${NC} http://$IP_ADDRESS"
    
    # Verificar si hay sitios con SSL
    if [ "$SSL_CERTS_COUNT" -gt 0 ]; then
        echo -e "   ${CYAN}HTTPS:${NC} https://$IP_ADDRESS"
    fi
    
    # Mostrar sitios configurados
    if [ "$SITES_ENABLED" -gt 0 ]; then
        echo -e "   ${CYAN}Sitios activos:${NC}"
        for site in /etc/nginx/sites-enabled/*; do
            if [ -L "$site" ]; then
                sitename=$(basename "$site")
                echo -e "     ${YELLOW}•${NC} $sitename"
            fi
        done
    fi
    echo
}

# Función para mostrar directorios importantes
show_directories() {
    echo -e "${WHITE}📂 Directorios Importantes${NC}"
    echo -e "   ${CYAN}Sitios web:${NC} /var/www/"
    echo -e "   ${CYAN}Configuración:${NC} /etc/nginx/"
    echo -e "   ${CYAN}Logs:${NC} /var/log/nginx/"
    echo -e "   ${CYAN}Certificados SSL:${NC} /etc/letsencrypt/"
    echo -e "   ${CYAN}Herramientas:${NC} /opt/nginx-server/"
    echo
}

# Función para mostrar comandos útiles
show_commands() {
    echo -e "${WHITE}🛠️  Comandos Útiles${NC}"
    echo -e "   ${YELLOW}nginx-info${NC}        - Mostrar esta información"
    echo -e "   ${YELLOW}nginx-manager${NC}     - Gestionar sitios web"
    echo -e "   ${YELLOW}ssl-manager${NC}       - Gestionar certificados SSL"
    echo -e "   ${YELLOW}nginx-status${NC}      - Ver estado del servicio"
    echo -e "   ${YELLOW}nginx-test${NC}        - Probar configuración"
    echo -e "   ${YELLOW}nginx-reload${NC}      - Recargar configuración"
    echo -e "   ${YELLOW}nginx-restart${NC}     - Reiniciar servicio"
    echo -e "   ${YELLOW}nginx-logs${NC}        - Ver logs de acceso"
    echo -e "   ${YELLOW}nginx-errors${NC}      - Ver logs de errores"
    echo
}

# Función para mostrar acceso rápido
show_quick_access() {
    echo -e "${WHITE}🔗 Acceso Rápido${NC}"
    echo -e "   ${CYAN}Sitio web:${NC} http://$IP_ADDRESS"
    
    # Obtener ID del contenedor si es LXC
    if [ "$CONTAINER_TYPE" = "LXC" ]; then
        # Intentar obtener el ID del contenedor desde el hostname o archivos del sistema
        CONTAINER_ID=$(hostname | grep -o '[0-9]\+' | head -1)
        if [ -n "$CONTAINER_ID" ]; then
            echo -e "   ${CYAN}Consola:${NC} pct enter $CONTAINER_ID"
        else
            echo -e "   ${CYAN}Consola:${NC} pct enter [ID]"
        fi
    fi
    
    echo -e "   ${CYAN}SSH:${NC} ssh root@$IP_ADDRESS"
    echo
}

# Función para mostrar alertas importantes
show_alerts() {
    alerts_shown=false
    
    # Alerta si nginx está inactivo
    if [ "$NGINX_STATUS" = "inactivo" ]; then
        echo -e "${RED}⚠️  ALERTA: Nginx está inactivo${NC}"
        alerts_shown=true
    fi
    
    # Alerta si hay errores en la configuración
    if [ "$NGINX_CONFIG_STATUS" = "con errores" ]; then
        echo -e "${RED}⚠️  ALERTA: Errores en la configuración de nginx${NC}"
        alerts_shown=true
    fi
    
    # Alerta si hay certificados expirados
    if [ "$SSL_EXPIRED" -gt 0 ]; then
        echo -e "${RED}⚠️  ALERTA: $SSL_EXPIRED certificado(s) SSL expirado(s)${NC}"
        alerts_shown=true
    fi
    
    # Alerta si hay certificados por expirar
    if [ "$SSL_EXPIRING_SOON" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  AVISO: $SSL_EXPIRING_SOON certificado(s) SSL expiran pronto${NC}"
        alerts_shown=true
    fi
    
    # Alerta si el firewall está inactivo
    if [ "$UFW_STATUS" = "inactive" ]; then
        echo -e "${YELLOW}⚠️  AVISO: Firewall (UFW) está inactivo${NC}"
        alerts_shown=true
    fi
    
    # Alerta si hay muchos errores
    if [ "$ERRORS_TODAY" -gt 10 ]; then
        echo -e "${YELLOW}⚠️  AVISO: $ERRORS_TODAY errores registrados hoy${NC}"
        alerts_shown=true
    fi
    
    if [ "$alerts_shown" = true ]; then
        echo
    fi
}

# Función para mostrar footer
show_footer() {
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}Desarrollado con ❤️  para la comunidad de Proxmox${NC}"
    echo -e "${PURPLE}Hecho en 🇵🇷 Puerto Rico con mucho ☕ café${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo
}

# Función principal
main() {
    # Obtener toda la información del sistema
    get_system_info
    get_nginx_info
    get_ssl_info
    get_log_stats
    get_security_info
    
    # Mostrar información completa
    show_banner
    show_alerts
    show_system_info
    show_nginx_info
    show_ssl_info
    show_log_stats
    show_security_info
    show_web_access
    show_directories
    show_commands
    show_quick_access
    show_footer
}

# Ejecutar función principal
main "$@" 