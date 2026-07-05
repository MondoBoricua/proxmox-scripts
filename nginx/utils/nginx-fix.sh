#!/bin/bash

# Script para verificar y corregir problemas de nginx
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

# Verificar si nginx está instalado
check_nginx_installed() {
    if ! command -v nginx &> /dev/null; then
        log_error "Nginx no está instalado"
        exit 1
    fi
}

# Verificar configuración de nginx
test_nginx_config() {
    log_step "Verificando configuración de nginx..."
    
    if nginx -t &>/dev/null; then
        log_success "Configuración de nginx es válida"
        return 0
    else
        log_error "Configuración de nginx tiene errores"
        nginx -t
        return 1
    fi
}

# Crear configuración mínima de emergencia
create_emergency_config() {
    log_step "Creando configuración mínima de emergencia..."
    
    # Backup de la configuración actual
    if [ -f /etc/nginx/nginx.conf ]; then
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
        log_info "Backup creado: /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Crear configuración mínima
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    
    # Logs básicos
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Incluir sitios
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
    
    # Servidor por defecto básico
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        
        root /var/www/html;
        index index.html index.htm;
        server_name _;
        
        location / {
            try_files $uri $uri/ =404;
        }
        
        # Archivos estáticos
        location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
            expires 1y;
            add_header Cache-Control "public";
        }
        
        # Ocultar archivos sensibles
        location ~ /\. {
            deny all;
        }
    }
}
EOF
    
    log_success "Configuración mínima creada"
}

# Crear directorio de sitios si no existe
create_sites_directories() {
    log_step "Verificando directorios de sitios..."
    
    # Crear directorios necesarios
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /var/www/html
    
    # Verificar permisos
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    log_success "Directorios de sitios verificados"
}

# Crear página de inicio básica
create_basic_index() {
    log_step "Creando página de inicio básica..."
    
    if [ ! -f /var/www/html/index.html ]; then
        cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Server - Funcionando</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 80vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 2.5rem; margin-bottom: 20px; }
        .status { color: #00ff00; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Nginx Server</h1>
        <p class="status">✅ FUNCIONANDO CORRECTAMENTE</p>
        <p>Tu servidor web está activo y funcionando.</p>
        <p>Hecho en 🇵🇷 Puerto Rico con mucho ☕ café</p>
    </div>
</body>
</html>
EOF
        
        chown www-data:www-data /var/www/html/index.html
        log_success "Página de inicio creada"
    else
        log_info "Página de inicio ya existe"
    fi
}

# Verificar y corregir permisos
fix_permissions() {
    log_step "Verificando permisos..."
    
    # Permisos de nginx
    chown -R www-data:www-data /var/www/
    chmod -R 755 /var/www/
    
    # Permisos de configuración
    chown -R root:root /etc/nginx/
    chmod -R 644 /etc/nginx/
    chmod 755 /etc/nginx/
    chmod 755 /etc/nginx/sites-available/
    chmod 755 /etc/nginx/sites-enabled/
    
    log_success "Permisos verificados"
}

# Reiniciar nginx de forma segura
restart_nginx() {
    log_step "Reiniciando nginx..."
    
    if test_nginx_config; then
        systemctl restart nginx
        if systemctl is-active --quiet nginx; then
            log_success "Nginx reiniciado exitosamente"
        else
            log_error "Error al reiniciar nginx"
            return 1
        fi
    else
        log_error "No se puede reiniciar nginx - configuración inválida"
        return 1
    fi
}

# Mostrar estado del servidor
show_server_status() {
    log_step "Estado del servidor:"
    
    echo -e "${WHITE}Nginx Status:${NC}"
    systemctl status nginx --no-pager -l
    
    echo -e "\n${WHITE}Puertos en uso:${NC}"
    netstat -tuln | grep :80
    
    echo -e "\n${WHITE}Sitios habilitados:${NC}"
    if [ -d /etc/nginx/sites-enabled ]; then
        ls -la /etc/nginx/sites-enabled/
    fi
    
    echo -e "\n${WHITE}Logs recientes:${NC}"
    tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No hay logs de error"
}

# Función principal
main() {
    echo -e "${WHITE}🔧 Nginx Fix - Herramienta de corrección automática${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
    
    check_root
    check_nginx_installed
    
    # Verificar configuración actual
    if ! test_nginx_config; then
        log_warning "Configuración actual tiene errores - aplicando correcciones..."
        
        create_sites_directories
        create_emergency_config
        create_basic_index
        fix_permissions
        
        if test_nginx_config; then
            restart_nginx
            log_success "¡Nginx corregido exitosamente!"
        else
            log_error "No se pudo corregir la configuración"
            exit 1
        fi
    else
        log_success "Configuración actual es válida"
        create_sites_directories
        create_basic_index
        fix_permissions
    fi
    
    show_server_status
    
    echo -e "\n${GREEN}✅ Proceso completado${NC}"
    echo -e "${WHITE}Para gestionar sitios usa: ./nginx-manager.sh${NC}"
}

# Ejecutar función principal
main "$@" 