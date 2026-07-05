#!/bin/bash

# 🔐 Security Utils - Configuraciones de Seguridad para Nginx
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

# Configurar firewall UFW
configure_ufw() {
    log_step "Configurando firewall UFW..."
    
    # Instalar UFW si no está instalado
    if ! command -v ufw &> /dev/null; then
        log_info "Instalando UFW..."
        apt update && apt install -y ufw
    fi
    
    # Configurar reglas básicas
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Permitir SSH
    ufw allow 22/tcp
    
    # Permitir HTTP y HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Permitir acceso local
    ufw allow from 127.0.0.1
    ufw allow from 10.0.0.0/8
    ufw allow from 172.16.0.0/12
    ufw allow from 192.168.0.0/16
    
    # Habilitar UFW
    ufw --force enable
    
    log_success "UFW configurado correctamente"
}

# Configurar Fail2ban
configure_fail2ban() {
    log_step "Configurando Fail2ban..."
    
    # Instalar Fail2ban si no está instalado
    if ! command -v fail2ban-client &> /dev/null; then
        log_info "Instalando Fail2ban..."
        apt update && apt install -y fail2ban
    fi
    
    # Crear configuración personalizada
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Configuración global de Fail2ban para nginx-server
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

# Configuración de notificaciones (opcional)
destemail = root@localhost
sendername = Fail2Ban
mta = sendmail

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 1800

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 6

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF
    
    # Crear filtros personalizados
    cat > /etc/fail2ban/filter.d/nginx-badbots.conf << 'EOF'
[Definition]
badbotscustom = EmailCollector|WebEMailExtrac|TrackBack/1\.02|sogou music spider
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*".*".*(<badbotscustom>|.*bot.*|.*spider.*|.*crawler.*)".*$
ignoreregex =
EOF
    
    cat > /etc/fail2ban/filter.d/nginx-noproxy.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*".*".*proxy.*".*$
ignoreregex =
EOF
    
    # Reiniciar y habilitar Fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    log_success "Fail2ban configurado correctamente"
}

# Configurar headers de seguridad en nginx
configure_security_headers() {
    log_step "Configurando headers de seguridad..."
    
    # Crear archivo de configuración de seguridad
    cat > /etc/nginx/conf.d/security-headers.conf << 'EOF'
# Headers de seguridad para nginx-server
# Desarrollado con ❤️ para la comunidad de Proxmox

# Ocultar versión de nginx
server_tokens off;

# Headers de seguridad globales
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive" always;

# Content Security Policy básico
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; media-src 'self'; object-src 'none'; child-src 'self'; frame-ancestors 'self'; form-action 'self'; base-uri 'self';" always;

# Feature Policy
add_header Feature-Policy "geolocation 'none'; midi 'none'; notifications 'none'; push 'none'; sync-xhr 'none'; microphone 'none'; camera 'none'; magnetometer 'none'; gyroscope 'none'; speaker 'none'; vibrate 'none'; fullscreen 'self'; payment 'none';" always;

# Permissions Policy (nuevo estándar)
add_header Permissions-Policy "geolocation=(), midi=(), notifications=(), push=(), sync-xhr=(), microphone=(), camera=(), magnetometer=(), gyroscope=(), speaker=(), vibrate=(), fullscreen=(self), payment=()" always;
EOF
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Headers de seguridad configurados correctamente"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Configurar rate limiting avanzado
configure_rate_limiting() {
    log_step "Configurando rate limiting avanzado..."
    
    # Crear configuración de rate limiting
    cat > /etc/nginx/conf.d/rate-limiting.conf << 'EOF'
# Rate limiting para nginx-server
# Desarrollado con ❤️ para la comunidad de Proxmox

# Zonas de rate limiting
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;
limit_req_zone $binary_remote_addr zone=static:10m rate=20r/s;

# Zona para conexiones simultáneas
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

# Configuración global de rate limiting
limit_req_status 429;
limit_conn_status 429;

# Rate limiting para archivos estáticos
location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
    limit_req zone=static burst=10 nodelay;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Rate limiting para APIs
location /api/ {
    limit_req zone=api burst=20 nodelay;
    limit_conn conn_limit_per_ip 10;
}

# Rate limiting para login
location /login {
    limit_req zone=login burst=5 nodelay;
}

# Rate limiting general
location / {
    limit_req zone=general burst=10 nodelay;
    limit_conn conn_limit_per_ip 20;
}
EOF
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Rate limiting configurado correctamente"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Configurar SSL/TLS seguro
configure_ssl_security() {
    log_step "Configurando SSL/TLS seguro..."
    
    # Crear configuración SSL segura
    cat > /etc/nginx/conf.d/ssl-security.conf << 'EOF'
# Configuración SSL/TLS segura para nginx-server
# Desarrollado con ❤️ para la comunidad de Proxmox

# Protocolos SSL seguros
ssl_protocols TLSv1.2 TLSv1.3;

# Ciphers seguros
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

# Preferir ciphers del servidor
ssl_prefer_server_ciphers off;

# Configuración de sesión SSL
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;

# Resolver DNS
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# Diffie-Hellman parameters
ssl_dhparam /etc/nginx/dhparam.pem;
EOF
    
    # Generar parámetros Diffie-Hellman si no existen
    if [ ! -f /etc/nginx/dhparam.pem ]; then
        log_info "Generando parámetros Diffie-Hellman (esto puede tomar varios minutos)..."
        openssl dhparam -out /etc/nginx/dhparam.pem 2048
    fi
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "SSL/TLS configurado correctamente"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Configurar protección contra ataques
configure_attack_protection() {
    log_step "Configurando protección contra ataques..."
    
    # Crear configuración de protección
    cat > /etc/nginx/conf.d/attack-protection.conf << 'EOF'
# Protección contra ataques para nginx-server
# Desarrollado con ❤️ para la comunidad de Proxmox

# Bloquear user agents maliciosos
map $http_user_agent $bad_bot {
    default 0;
    ~*malicious 1;
    ~*bot 1;
    ~*crawler 1;
    ~*scanner 1;
    ~*script 1;
    ~*wget 1;
    ~*curl 1;
    ~*python 1;
    ~*nikto 1;
    ~*sqlmap 1;
    ~*nmap 1;
}

# Bloquear métodos HTTP no permitidos
map $request_method $bad_method {
    default 0;
    ~*^(TRACE|DELETE|TRACK) 1;
}

# Bloquear URLs sospechosas
map $request_uri $bad_uri {
    default 0;
    ~*(/\.|/wp-admin|/wp-login|/admin|/phpmyadmin|/xmlrpc) 1;
    ~*(\.php|\.asp|\.aspx|\.jsp)$ 1;
    ~*(union|select|insert|update|delete|drop|create|alter) 1;
    ~*(<script|javascript:|vbscript:|onload|onerror) 1;
}

# Configuración del servidor para bloquear ataques
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name "";
    
    # Bloquear bots maliciosos
    if ($bad_bot) {
        return 444;
    }
    
    # Bloquear métodos HTTP no permitidos
    if ($bad_method) {
        return 405;
    }
    
    # Bloquear URLs sospechosas
    if ($bad_uri) {
        return 403;
    }
    
    # Bloquear IPs que no envían Host header
    if ($host = "") {
        return 444;
    }
    
    # Bloquear requests con headers sospechosos
    if ($http_x_forwarded_for ~* "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.,.*(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)") {
        return 403;
    }
    
    return 444;
}
EOF
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Protección contra ataques configurada correctamente"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Configurar logging de seguridad
configure_security_logging() {
    log_step "Configurando logging de seguridad..."
    
    # Crear directorio de logs de seguridad
    mkdir -p /var/log/nginx/security
    
    # Configurar logrotate para logs de seguridad
    cat > /etc/logrotate.d/nginx-security << 'EOF'
/var/log/nginx/security/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 www-data adm
    sharedscripts
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi \
    endscript
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
EOF
    
    # Crear script de monitoreo de seguridad
    cat > /opt/nginx-server/security-monitor.sh << 'EOF'
#!/bin/bash
# Monitor de seguridad para nginx-server

LOG_FILE="/var/log/nginx/security/security-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Función de logging
log_security() {
    echo "[$DATE] $1" >> "$LOG_FILE"
}

# Verificar intentos de acceso sospechosos
SUSPICIOUS_IPS=$(tail -1000 /var/log/nginx/access.log | grep -E "(404|403|444)" | awk '{print $1}' | sort | uniq -c | sort -nr | head -10)

if [ -n "$SUSPICIOUS_IPS" ]; then
    log_security "IPs con actividad sospechosa detectadas:"
    echo "$SUSPICIOUS_IPS" >> "$LOG_FILE"
fi

# Verificar IPs bloqueadas por Fail2ban
if command -v fail2ban-client &> /dev/null; then
    BANNED_IPS=$(fail2ban-client status nginx-http-auth 2>/dev/null | grep "Banned IP list" | cut -d':' -f2)
    if [ -n "$BANNED_IPS" ]; then
        log_security "IPs bloqueadas por Fail2ban: $BANNED_IPS"
    fi
fi

# Verificar uso de CPU y memoria
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    log_security "ALERTA: Uso de CPU alto: $CPU_USAGE%"
fi

if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
    log_security "ALERTA: Uso de memoria alto: $MEM_USAGE%"
fi
EOF
    
    chmod +x /opt/nginx-server/security-monitor.sh
    
    # Agregar a crontab para ejecutar cada 15 minutos
    (crontab -l 2>/dev/null | grep -v "security-monitor.sh"; echo "*/15 * * * * /opt/nginx-server/security-monitor.sh") | crontab -
    
    log_success "Logging de seguridad configurado correctamente"
}

# Función principal de configuración de seguridad
configure_all_security() {
    log_step "Configurando todas las medidas de seguridad..."
    
    configure_ufw
    configure_fail2ban
    configure_security_headers
    configure_rate_limiting
    configure_ssl_security
    configure_attack_protection
    configure_security_logging
    
    log_success "Todas las configuraciones de seguridad aplicadas correctamente"
    log_info "Se recomienda reiniciar nginx para aplicar todos los cambios:"
    log_info "systemctl restart nginx"
}

# Función para verificar estado de seguridad
check_security_status() {
    log_step "Verificando estado de seguridad..."
    
    echo -e "${WHITE}🔐 Estado de Seguridad${NC}"
    
    # Verificar UFW
    if systemctl is-active --quiet ufw; then
        echo -e "   ${GREEN}✓${NC} UFW está activo"
    else
        echo -e "   ${RED}✗${NC} UFW está inactivo"
    fi
    
    # Verificar Fail2ban
    if systemctl is-active --quiet fail2ban; then
        echo -e "   ${GREEN}✓${NC} Fail2ban está activo"
    else
        echo -e "   ${RED}✗${NC} Fail2ban está inactivo"
    fi
    
    # Verificar configuración nginx
    if nginx -t &>/dev/null; then
        echo -e "   ${GREEN}✓${NC} Configuración nginx válida"
    else
        echo -e "   ${RED}✗${NC} Configuración nginx con errores"
    fi
    
    # Verificar SSL
    if [ -f /etc/nginx/dhparam.pem ]; then
        echo -e "   ${GREEN}✓${NC} Parámetros DH configurados"
    else
        echo -e "   ${YELLOW}⚠${NC} Parámetros DH no configurados"
    fi
    
    # Verificar logs de seguridad
    if [ -f /var/log/nginx/security/security-monitor.log ]; then
        echo -e "   ${GREEN}✓${NC} Monitoreo de seguridad activo"
    else
        echo -e "   ${YELLOW}⚠${NC} Monitoreo de seguridad no configurado"
    fi
}

# Función principal
main() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root"
        exit 1
    fi
    
    case "${1:-all}" in
        "ufw")
            configure_ufw
            ;;
        "fail2ban")
            configure_fail2ban
            ;;
        "headers")
            configure_security_headers
            ;;
        "rate-limit")
            configure_rate_limiting
            ;;
        "ssl")
            configure_ssl_security
            ;;
        "attack-protection")
            configure_attack_protection
            ;;
        "logging")
            configure_security_logging
            ;;
        "status")
            check_security_status
            ;;
        "all")
            configure_all_security
            ;;
        *)
            echo "Uso: $0 [ufw|fail2ban|headers|rate-limit|ssl|attack-protection|logging|status|all]"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@" 