#!/bin/bash

# Script para diagnosticar y corregir problemas de puertos en nginx
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

# Diagnosticar puertos
diagnose_ports() {
    log_step "Diagnosticando configuración de puertos..."
    
    echo -e "${WHITE}🔍 Verificando configuración de sitios:${NC}"
    
    # Verificar sitios disponibles
    if [ -d "/etc/nginx/sites-available" ]; then
        for site in /etc/nginx/sites-available/*; do
            if [ -f "$site" ]; then
                sitename=$(basename "$site")
                echo -e "\n${CYAN}📄 Sitio: $sitename${NC}"
                
                # Extraer puertos configurados
                ports=$(grep -o "listen [0-9]\{1,5\}" "$site" | awk '{print $2}' | sort -u)
                if [ -n "$ports" ]; then
                    echo -e "   Puertos configurados: $ports"
                else
                    echo -e "   ${YELLOW}No se encontraron puertos específicos${NC}"
                fi
                
                # Verificar si está habilitado
                if [ -L "/etc/nginx/sites-enabled/$sitename" ]; then
                    echo -e "   Estado: ${GREEN}✅ Habilitado${NC}"
                else
                    echo -e "   Estado: ${RED}❌ Deshabilitado${NC}"
                fi
            fi
        done
    fi
    
    echo -e "\n${WHITE}🌐 Verificando puertos en uso por nginx:${NC}"
    netstat -tuln | grep nginx || netstat -tuln | grep ":80\|:443\|:8080\|:8081\|:8082\|:8083\|:8084\|:8085"
    
    echo -e "\n${WHITE}🔧 Verificando configuración de nginx:${NC}"
    nginx -t
    
    echo -e "\n${WHITE}📋 Procesos nginx:${NC}"
    ps aux | grep nginx
}

# Corregir configuración de puertos
fix_port_config() {
    log_step "Corrigiendo configuración de puertos..."
    
    # Verificar si hay sitios por puerto que no estén funcionando
    for site in /etc/nginx/sites-available/*; do
        if [ -f "$site" ]; then
            sitename=$(basename "$site")
            
            # Verificar si es un sitio por puerto
            if grep -q "listen [0-9]\{4,5\}" "$site"; then
                port=$(grep "listen [0-9]\{4,5\}" "$site" | head -1 | awk '{print $2}' | sed 's/;//')
                
                log_info "Verificando sitio $sitename en puerto $port..."
                
                # Verificar si nginx está escuchando en este puerto
                if ! netstat -tuln | grep -q ":$port "; then
                    log_warning "Nginx no está escuchando en puerto $port"
                    
                    # Verificar si el sitio está habilitado
                    if [ ! -L "/etc/nginx/sites-enabled/$sitename" ]; then
                        log_info "Habilitando sitio $sitename..."
                        ln -sf "/etc/nginx/sites-available/$sitename" "/etc/nginx/sites-enabled/$sitename"
                    fi
                    
                    # Verificar configuración
                    if nginx -t &>/dev/null; then
                        log_info "Recargando nginx..."
                        systemctl reload nginx
                        sleep 2
                        
                        # Verificar nuevamente
                        if netstat -tuln | grep -q ":$port "; then
                            log_success "Puerto $port ahora está activo"
                        else
                            log_error "Puerto $port sigue sin funcionar"
                        fi
                    else
                        log_error "Error en configuración de nginx"
                        nginx -t
                    fi
                fi
            fi
        fi
    done
}

# Verificar firewall
check_firewall() {
    log_step "Verificando configuración del firewall..."
    
    # Verificar si ufw está activo
    if command -v ufw &> /dev/null; then
        ufw_status=$(ufw status | head -1)
        echo -e "${WHITE}UFW Status:${NC} $ufw_status"
        
        if echo "$ufw_status" | grep -q "active"; then
            log_info "Verificando reglas para puertos personalizados..."
            
            # Verificar puertos específicos
            for port in 8080 8081 8082 8083 8084 8085; do
                if [ -f "/etc/nginx/sites-enabled/site-$port" ] || ls /etc/nginx/sites-enabled/* 2>/dev/null | grep -q "$port"; then
                    if ! ufw status | grep -q "$port"; then
                        log_warning "Puerto $port no está permitido en firewall"
                        log_info "Agregando regla para puerto $port..."
                        ufw allow $port/tcp
                    fi
                fi
            done
        fi
    fi
}

# Crear sitio de prueba por puerto
create_test_site() {
    local test_port=${1:-8080}
    
    log_step "Creando sitio de prueba en puerto $test_port..."
    
    # Verificar si el puerto está en uso
    if netstat -tuln | grep -q ":$test_port "; then
        log_warning "Puerto $test_port ya está en uso"
        return 1
    fi
    
    # Crear directorio
    mkdir -p "/var/www/test-$test_port"
    
    # Crear página de prueba
    cat > "/var/www/test-$test_port/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Puerto $test_port</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin: 50px;
            background: linear-gradient(135deg, #ff6b6b 0%, #4ecdc4 100%);
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
        h1 { font-size: 3rem; margin-bottom: 20px; }
        .port { color: #ffff00; font-weight: bold; font-size: 2rem; }
        .status { color: #00ff00; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 Sitio de Prueba</h1>
        <p class="port">Puerto: $test_port</p>
        <p class="status">✅ FUNCIONANDO</p>
        <p>Este es un sitio de prueba para verificar que el puerto $test_port está funcionando correctamente.</p>
        <p>Hora: $(date)</p>
    </div>
</body>
</html>
EOF
    
    # Crear configuración
    cat > "/etc/nginx/sites-available/test-$test_port" << EOF
server {
    listen $test_port;
    listen [::]:$test_port;
    
    server_name _;
    
    root /var/www/test-$test_port;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/test-${test_port}_access.log;
    error_log /var/log/nginx/test-${test_port}_error.log;
}
EOF
    
    # Habilitar sitio
    ln -sf "/etc/nginx/sites-available/test-$test_port" "/etc/nginx/sites-enabled/test-$test_port"
    
    # Configurar permisos
    chown -R www-data:www-data "/var/www/test-$test_port"
    chmod -R 755 "/var/www/test-$test_port"
    
    # Permitir en firewall
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        ufw allow $test_port/tcp
    fi
    
    # Recargar nginx
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Sitio de prueba creado en puerto $test_port"
        
        # Verificar que funciona
        sleep 2
        if netstat -tuln | grep -q ":$test_port "; then
            log_success "Puerto $test_port está activo y funcionando"
            local server_ip=$(hostname -I | awk '{print $1}')
            log_info "Accede a: http://$server_ip:$test_port"
        else
            log_error "Puerto $test_port no está respondiendo"
        fi
    else
        log_error "Error en configuración de nginx"
        nginx -t
    fi
}

# Mostrar ayuda
show_help() {
    echo -e "${WHITE}🔧 Port Fix - Herramienta de diagnóstico de puertos${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
    echo
    echo "Uso: $0 [opción]"
    echo
    echo "Opciones:"
    echo "  diagnose    - Diagnosticar problemas de puertos"
    echo "  fix         - Corregir configuración de puertos"
    echo "  firewall    - Verificar configuración del firewall"
    echo "  test [PORT] - Crear sitio de prueba (puerto por defecto: 8080)"
    echo "  help        - Mostrar esta ayuda"
    echo
    echo "Ejemplos:"
    echo "  $0 diagnose"
    echo "  $0 fix"
    echo "  $0 test 8080"
    echo
}

# Función principal
main() {
    check_root
    
    case "${1:-diagnose}" in
        "diagnose")
            diagnose_ports
            ;;
        "fix")
            fix_port_config
            ;;
        "firewall")
            check_firewall
            ;;
        "test")
            create_test_site "${2:-8080}"
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@" 