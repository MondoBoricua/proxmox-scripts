#!/bin/bash

# 🌐 Nginx Manager - Herramienta de Gestión de Sitios Web
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

# Directorios importantes
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
WEB_ROOT="/var/www"
SSL_TEMPLATE="/opt/nginx-server/configs/ssl-template.conf"
NGINX_CONFIG="/etc/nginx/nginx.conf"

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

# Banner del programa
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🌐 NGINX MANAGER - GESTOR DE SITIOS 🌐          ║"
    echo "║                                                              ║"
    echo "║                    Versión 1.0                               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar permisos de root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Verificar que nginx está instalado
check_nginx() {
    if ! command -v nginx &> /dev/null; then
        log_error "Nginx no está instalado"
        exit 1
    fi
}

# Mostrar menú principal
show_menu() {
    echo -e "${WHITE}🛠️  Opciones Disponibles:${NC}"
    echo -e "   ${YELLOW}1.${NC} Crear nuevo sitio web (por dominio)"
    echo -e "   ${YELLOW}2.${NC} Crear nuevo sitio web (por puerto)"
    echo -e "   ${YELLOW}3.${NC} Listar sitios web"
    echo -e "   ${YELLOW}4.${NC} Habilitar sitio web"
    echo -e "   ${YELLOW}5.${NC} Deshabilitar sitio web"
    echo -e "   ${YELLOW}6.${NC} Eliminar sitio web"
    echo -e "   ${YELLOW}7.${NC} Ver configuración de sitio"
    echo -e "   ${YELLOW}8.${NC} Editar configuración de sitio"
    echo -e "   ${YELLOW}9.${NC} Verificar configuración nginx"
    echo -e "   ${YELLOW}10.${NC} Recargar nginx"
    echo -e "   ${YELLOW}11.${NC} Ver estado de nginx"
    echo -e "   ${YELLOW}12.${NC} Ver logs de acceso"
    echo -e "   ${YELLOW}13.${NC} Ver logs de errores"
    echo -e "   ${YELLOW}14.${NC} Optimizar rendimiento"
    echo -e "   ${YELLOW}15.${NC} Habilitar PHP para sitio"
    echo -e "   ${YELLOW}16.${NC} Crear sitio con SSL"
    echo -e "   ${YELLOW}0.${NC} Salir"
    echo
}

# Crear nuevo sitio web
create_site() {
    log_step "Creando nuevo sitio web..."
    
    # Solicitar nombre del dominio
    read -p "Ingresa el nombre del dominio (ej: ejemplo.com): " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        log_error "El dominio no puede estar vacío"
        return 1
    fi
    
    # Verificar si el sitio ya existe
    if [ -f "$NGINX_SITES_AVAILABLE/$DOMAIN" ]; then
        log_error "El sitio $DOMAIN ya existe"
        return 1
    fi
    
    # Crear directorio del sitio
    mkdir -p "$WEB_ROOT/$DOMAIN"
    
    # Crear página de ejemplo
    cat > "$WEB_ROOT/$DOMAIN/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$DOMAIN - ¡Sitio Funcionando!</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        
        .container {
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        
        .logo {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        
        .domain {
            font-size: 1.5rem;
            color: #ffd700;
            margin-bottom: 2rem;
        }
        
        .status {
            display: inline-block;
            padding: 0.5rem 1rem;
            background: #28a745;
            color: white;
            border-radius: 25px;
            font-weight: bold;
            margin: 1rem 0;
        }
        
        .footer {
            margin-top: 2rem;
            padding-top: 2rem;
            border-top: 1px solid rgba(255, 255, 255, 0.2);
            opacity: 0.8;
        }
        
        .flag {
            font-size: 1.5rem;
            margin: 0 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌐</div>
        <h1>¡Sitio Web Funcionando!</h1>
        <div class="domain">$DOMAIN</div>
        
        <div class="status">✅ ACTIVO</div>
        
        <p>Tu sitio web está correctamente configurado y funcionando.</p>
        <p>Puedes comenzar a subir tu contenido al directorio:</p>
        <p><strong>/var/www/$DOMAIN</strong></p>
        
        <div class="footer">
            <p>Desarrollado con ❤️ para la comunidad de Proxmox</p>
            <p>Hecho en <span class="flag">🇵🇷</span> Puerto Rico con mucho <span class="flag">☕</span> café</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Crear configuración del sitio
    cat > "$NGINX_SITES_AVAILABLE/$DOMAIN" << EOF
# Configuración para $DOMAIN
# Creado automáticamente por nginx-manager

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    root $WEB_ROOT/$DOMAIN;
    index index.html index.htm index.php;
    
    # Configuración principal
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Configuración para archivos PHP (si está instalado)
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Configuración para archivos estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|tar|gz|zip|mp4|webm|ogg|mp3|wav|flac|aac|woff|woff2|ttf|eot|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        log_not_found off;
    }
    
    # Denegar acceso a archivos ocultos
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Logs específicos del sitio
    access_log /var/log/nginx/${DOMAIN}_access.log main;
    error_log /var/log/nginx/${DOMAIN}_error.log warn;
    
    # Headers de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Served-By "Nginx-Server-Proxmox" always;
}
EOF
    
    # Configurar permisos
    chown -R www-data:www-data "$WEB_ROOT/$DOMAIN"
    chmod -R 755 "$WEB_ROOT/$DOMAIN"
    
    # Habilitar el sitio
    ln -s "$NGINX_SITES_AVAILABLE/$DOMAIN" "$NGINX_SITES_ENABLED/$DOMAIN"
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Sitio $DOMAIN creado y habilitado exitosamente"
        log_info "Directorio: $WEB_ROOT/$DOMAIN"
        log_info "Configuración: $NGINX_SITES_AVAILABLE/$DOMAIN"
    else
        log_error "Error en la configuración de nginx"
        rm -f "$NGINX_SITES_ENABLED/$DOMAIN"
        return 1
    fi
}

# Crear sitio web por puerto - ¡Mucho más fácil pana!
create_site_by_port() {
    log_step "Creando sitio web por puerto..."
    
    # Obtener el siguiente puerto disponible automáticamente
    get_next_port() {
        local start_port=8080
        local current_port=$start_port
        
        # Buscar puertos ya en uso en nginx
        while netstat -tuln 2>/dev/null | grep -q ":$current_port " || \
              grep -r "listen.*$current_port" /etc/nginx/sites-* 2>/dev/null | grep -q .; do
            current_port=$((current_port + 1))
            # Evitar puertos reservados del sistema
            if [ $current_port -gt 9000 ]; then
                log_error "No se encontró un puerto disponible"
                return 1
            fi
        done
        
        echo $current_port
    }
    
    # Obtener el siguiente puerto disponible
    PORT=$(get_next_port)
    if [ -z "$PORT" ]; then
        log_error "No se pudo obtener un puerto disponible"
        return 1
    fi
    
    # Solicitar nombre del sitio (opcional)
    read -p "Nombre del sitio (opcional, por defecto: site-$PORT): " SITE_NAME
    
    if [ -z "$SITE_NAME" ]; then
        SITE_NAME="site-$PORT"
    fi
    
    # Verificar si el sitio ya existe
    if [ -f "$NGINX_SITES_AVAILABLE/$SITE_NAME" ]; then
        log_error "El sitio $SITE_NAME ya existe"
        return 1
    fi
    
    # Crear directorio del sitio
    mkdir -p "$WEB_ROOT/$SITE_NAME"
    
    # Crear página de ejemplo con info del puerto
    cat > "$WEB_ROOT/$SITE_NAME/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$SITE_NAME - Puerto $PORT</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        
        .container {
            max-width: 700px;
            padding: 3rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        
        .logo {
            font-size: 4rem;
            margin-bottom: 1rem;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        
        .port-info {
            font-size: 2rem;
            color: #ffd700;
            margin: 1rem 0;
            background: rgba(255, 215, 0, 0.2);
            padding: 1rem;
            border-radius: 15px;
            border: 2px solid #ffd700;
        }
        
        .site-name {
            font-size: 1.5rem;
            color: #87ceeb;
            margin-bottom: 2rem;
        }
        
        .status {
            display: inline-block;
            padding: 0.5rem 1rem;
            background: #28a745;
            color: white;
            border-radius: 25px;
            font-weight: bold;
            margin: 1rem 0;
        }
        
        .access-info {
            background: rgba(255, 255, 255, 0.1);
            padding: 1.5rem;
            border-radius: 15px;
            margin: 2rem 0;
            border-left: 4px solid #ffd700;
        }
        
        .access-info h3 {
            color: #ffd700;
            margin-bottom: 1rem;
        }
        
        .access-url {
            font-family: 'Courier New', monospace;
            background: rgba(0, 0, 0, 0.3);
            padding: 0.5rem 1rem;
            border-radius: 8px;
            margin: 0.5rem 0;
            font-size: 1.1rem;
        }
        
        .footer {
            margin-top: 2rem;
            padding-top: 2rem;
            border-top: 1px solid rgba(255, 255, 255, 0.2);
            opacity: 0.8;
        }
        
        .flag {
            font-size: 1.5rem;
            margin: 0 0.5rem;
        }
        
        .port-badge {
            display: inline-block;
            background: #ff6b6b;
            color: white;
            padding: 0.3rem 0.8rem;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: bold;
            margin: 0 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1>¡Sitio Web Activo!</h1>
        
        <div class="port-info">
            <strong>Puerto: $PORT</strong>
        </div>
        
        <div class="site-name">$SITE_NAME</div>
        
        <div class="status">✅ FUNCIONANDO</div>
        
        <div class="access-info">
            <h3>🌐 Cómo acceder:</h3>
            <div class="access-url">http://IP_DEL_SERVIDOR:$PORT</div>
            <div class="access-url">http://localhost:$PORT</div>
            <p style="margin-top: 1rem; font-size: 0.9rem; opacity: 0.8;">
                Reemplaza "IP_DEL_SERVIDOR" con la IP real de tu servidor
            </p>
        </div>
        
        <p>Tu sitio web está correctamente configurado y escuchando en el puerto <span class="port-badge">$PORT</span></p>
        <p>Puedes comenzar a subir tu contenido al directorio:</p>
        <p><strong>/var/www/$SITE_NAME</strong></p>
        
        <div class="footer">
            <p>🎯 Gestión por puertos - ¡Fácil y directo!</p>
            <p>Desarrollado con ❤️ para la comunidad de Proxmox</p>
            <p>Hecho en <span class="flag">🇵🇷</span> Puerto Rico con mucho <span class="flag">☕</span> café</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Crear configuración del sitio por puerto
    cat > "$NGINX_SITES_AVAILABLE/$SITE_NAME" << EOF
# Configuración para $SITE_NAME (Puerto $PORT)
# Creado automáticamente por nginx-manager
# Sitio accesible en: http://IP_SERVIDOR:$PORT

server {
    listen $PORT;
    listen [::]:$PORT;
    
    # No necesitamos server_name específico para sitios por puerto
    server_name _;
    
    root $WEB_ROOT/$SITE_NAME;
    index index.html index.htm index.php;
    
    # Configuración principal
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Configuración para archivos PHP (si está instalado)
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Configuración para archivos estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|tar|gz|zip|mp4|webm|ogg|mp3|wav|flac|aac|woff|woff2|ttf|eot|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        log_not_found off;
    }
    
    # Denegar acceso a archivos ocultos
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Logs específicos del sitio
    access_log /var/log/nginx/${SITE_NAME}_port${PORT}_access.log main;
    error_log /var/log/nginx/${SITE_NAME}_port${PORT}_error.log warn;
    
    # Headers de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Served-By "Nginx-Server-Proxmox-Port-$PORT" always;
    add_header X-Port "$PORT" always;
}
EOF
    
    # Configurar permisos
    chown -R www-data:www-data "$WEB_ROOT/$SITE_NAME"
    chmod -R 755 "$WEB_ROOT/$SITE_NAME"
    
    # Habilitar el sitio
    ln -s "$NGINX_SITES_AVAILABLE/$SITE_NAME" "$NGINX_SITES_ENABLED/$SITE_NAME"
    
    # Abrir puerto en firewall automáticamente
    if command -v ufw &> /dev/null; then
        ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "active"; then
            log_info "Abriendo puerto $PORT en firewall..."
            ufw allow $PORT/tcp
            log_success "Puerto $PORT permitido en firewall"
        fi
    fi
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        # Usar restart en lugar de reload para asegurar que los puertos se abran
        log_info "Reiniciando nginx para aplicar cambios..."
        systemctl restart nginx
        sleep 2
        
        # Verificar que el puerto esté activo
        if netstat -tuln | grep -q ":$PORT "; then
            log_success "Sitio $SITE_NAME creado y habilitado exitosamente"
            log_info "Puerto: $PORT"
            log_info "Directorio: $WEB_ROOT/$SITE_NAME"
            log_info "Configuración: $NGINX_SITES_AVAILABLE/$SITE_NAME"
            echo
            log_info "🌐 Accede a tu sitio en:"
            log_info "   http://$(hostname -I | awk '{print $1}'):$PORT"
            log_info "   http://localhost:$PORT (desde el servidor)"
        else
            log_warning "Sitio creado pero puerto $PORT no está respondiendo"
            log_info "Intenta: systemctl restart nginx && ufw allow $PORT/tcp"
        fi
    else
        log_error "Error en la configuración de nginx"
        rm -f "$NGINX_SITES_ENABLED/$SITE_NAME"
        return 1
    fi
}

# Listar sitios web - Ahora con info de puertos, ¡qué brutal!
list_sites() {
    log_step "Listando sitios web..."
    
    echo -e "${WHITE}📂 Sitios Disponibles:${NC}"
    if [ -d "$NGINX_SITES_AVAILABLE" ] && [ "$(ls -A $NGINX_SITES_AVAILABLE)" ]; then
        for site in "$NGINX_SITES_AVAILABLE"/*; do
            if [ -f "$site" ]; then
                sitename=$(basename "$site")
                
                # Extraer información del puerto si existe
                port_info=""
                if grep -q "listen.*[0-9]\{4,5\}" "$site"; then
                    port=$(grep "listen.*[0-9]\{4,5\}" "$site" | head -1 | grep -o '[0-9]\{4,5\}' | head -1)
                    port_info=" ${CYAN}(Puerto: $port)${NC}"
                fi
                
                # Extraer información del dominio si existe
                domain_info=""
                if grep -q "server_name.*[a-zA-Z]" "$site"; then
                    domain=$(grep "server_name" "$site" | head -1 | awk '{print $2}' | sed 's/;//')
                    if [ "$domain" != "_" ]; then
                        domain_info=" ${BLUE}(Dominio: $domain)${NC}"
                    fi
                fi
                
                if [ -L "$NGINX_SITES_ENABLED/$sitename" ]; then
                    echo -e "   ${GREEN}✓${NC} $sitename${port_info}${domain_info} ${GREEN}(habilitado)${NC}"
                else
                    echo -e "   ${RED}✗${NC} $sitename${port_info}${domain_info} ${RED}(deshabilitado)${NC}"
                fi
            fi
        done
    else
        echo -e "   ${YELLOW}No hay sitios configurados${NC}"
    fi
    
    echo
    echo -e "${WHITE}🌐 Sitios Activos:${NC}"
    if [ -d "$NGINX_SITES_ENABLED" ] && [ "$(ls -A $NGINX_SITES_ENABLED)" ]; then
        for site in "$NGINX_SITES_ENABLED"/*; do
            if [ -L "$site" ]; then
                sitename=$(basename "$site")
                site_config="$NGINX_SITES_AVAILABLE/$sitename"
                
                # Obtener información de acceso
                access_info=""
                if [ -f "$site_config" ]; then
                    if grep -q "listen.*[0-9]\{4,5\}" "$site_config"; then
                        port=$(grep "listen.*[0-9]\{4,5\}" "$site_config" | head -1 | grep -o '[0-9]\{4,5\}' | head -1)
                        server_ip=$(hostname -I | awk '{print $1}')
                        access_info=" ${CYAN}→ http://$server_ip:$port${NC}"
                    elif grep -q "server_name.*[a-zA-Z]" "$site_config"; then
                        domain=$(grep "server_name" "$site_config" | head -1 | awk '{print $2}' | sed 's/;//')
                        if [ "$domain" != "_" ]; then
                            access_info=" ${CYAN}→ http://$domain${NC}"
                        fi
                    fi
                fi
                
                echo -e "   ${GREEN}●${NC} $sitename$access_info"
            fi
        done
    else
        echo -e "   ${YELLOW}No hay sitios habilitados${NC}"
    fi
    
    echo
    echo -e "${WHITE}📊 Resumen:${NC}"
    total_sites=$(ls -1 "$NGINX_SITES_AVAILABLE" 2>/dev/null | wc -l)
    enabled_sites=$(ls -1 "$NGINX_SITES_ENABLED" 2>/dev/null | wc -l)
    echo -e "   Total de sitios: ${YELLOW}$total_sites${NC}"
    echo -e "   Sitios habilitados: ${GREEN}$enabled_sites${NC}"
    echo -e "   Sitios deshabilitados: ${RED}$((total_sites - enabled_sites))${NC}"
}

# Habilitar sitio web
enable_site() {
    log_step "Habilitando sitio web..."
    
    # Mostrar sitios disponibles
    echo -e "${WHITE}Sitios disponibles para habilitar:${NC}"
    available_sites=()
    if [ -d "$NGINX_SITES_AVAILABLE" ]; then
        for site in "$NGINX_SITES_AVAILABLE"/*; do
            if [ -f "$site" ]; then
                sitename=$(basename "$site")
                if [ ! -L "$NGINX_SITES_ENABLED/$sitename" ]; then
                    available_sites+=("$sitename")
                    echo -e "   ${YELLOW}${#available_sites[@]}.${NC} $sitename"
                fi
            fi
        done
    fi
    
    if [ ${#available_sites[@]} -eq 0 ]; then
        log_warning "No hay sitios disponibles para habilitar"
        return 1
    fi
    
    read -p "Selecciona el sitio a habilitar (número o nombre): " choice
    
    # Determinar el sitio seleccionado
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#available_sites[@]} ]; then
        SITE="${available_sites[$((choice-1))]}"
    else
        SITE="$choice"
    fi
    
    # Verificar que el sitio existe
    if [ ! -f "$NGINX_SITES_AVAILABLE/$SITE" ]; then
        log_error "El sitio $SITE no existe"
        return 1
    fi
    
    # Habilitar el sitio
    ln -s "$NGINX_SITES_AVAILABLE/$SITE" "$NGINX_SITES_ENABLED/$SITE"
    
    # Verificar configuración
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Sitio $SITE habilitado exitosamente"
    else
        log_error "Error en la configuración de nginx"
        rm -f "$NGINX_SITES_ENABLED/$SITE"
        return 1
    fi
}

# Deshabilitar sitio web
disable_site() {
    log_step "Deshabilitando sitio web..."
    
    # Mostrar sitios habilitados
    echo -e "${WHITE}Sitios habilitados:${NC}"
    enabled_sites=()
    if [ -d "$NGINX_SITES_ENABLED" ]; then
        for site in "$NGINX_SITES_ENABLED"/*; do
            if [ -L "$site" ]; then
                sitename=$(basename "$site")
                enabled_sites+=("$sitename")
                echo -e "   ${YELLOW}${#enabled_sites[@]}.${NC} $sitename"
            fi
        done
    fi
    
    if [ ${#enabled_sites[@]} -eq 0 ]; then
        log_warning "No hay sitios habilitados para deshabilitar"
        return 1
    fi
    
    read -p "Selecciona el sitio a deshabilitar (número o nombre): " choice
    
    # Determinar el sitio seleccionado
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#enabled_sites[@]} ]; then
        SITE="${enabled_sites[$((choice-1))]}"
    else
        SITE="$choice"
    fi
    
    # Verificar que el sitio está habilitado
    if [ ! -L "$NGINX_SITES_ENABLED/$SITE" ]; then
        log_error "El sitio $SITE no está habilitado"
        return 1
    fi
    
    # Deshabilitar el sitio
    rm -f "$NGINX_SITES_ENABLED/$SITE"
    
    # Recargar nginx
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Sitio $SITE deshabilitado exitosamente"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Eliminar sitio web
remove_site() {
    log_step "Eliminando sitio web..."
    
    # Mostrar sitios disponibles
    echo -e "${WHITE}Sitios disponibles para eliminar:${NC}"
    available_sites=()
    if [ -d "$NGINX_SITES_AVAILABLE" ]; then
        for site in "$NGINX_SITES_AVAILABLE"/*; do
            if [ -f "$site" ]; then
                sitename=$(basename "$site")
                available_sites+=("$sitename")
                echo -e "   ${YELLOW}${#available_sites[@]}.${NC} $sitename"
            fi
        done
    fi
    
    if [ ${#available_sites[@]} -eq 0 ]; then
        log_warning "No hay sitios disponibles para eliminar"
        return 1
    fi
    
    read -p "Selecciona el sitio a eliminar (número o nombre): " choice
    
    # Determinar el sitio seleccionado
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#available_sites[@]} ]; then
        SITE="${available_sites[$((choice-1))]}"
    else
        SITE="$choice"
    fi
    
    # Verificar que el sitio existe
    if [ ! -f "$NGINX_SITES_AVAILABLE/$SITE" ]; then
        log_error "El sitio $SITE no existe"
        return 1
    fi
    
    # Confirmación
    log_warning "¿Estás seguro de que quieres eliminar el sitio $SITE?"
    log_warning "Esto eliminará:"
    log_warning "- Configuración: $NGINX_SITES_AVAILABLE/$SITE"
    log_warning "- Archivos web: $WEB_ROOT/$SITE"
    log_warning "- Logs: /var/log/nginx/${SITE}_*.log"
    
    read -p "Escribe 'ELIMINAR' para confirmar: " confirm
    
    if [ "$confirm" != "ELIMINAR" ]; then
        log_info "Eliminación cancelada"
        return 1
    fi
    
    # Deshabilitar el sitio si está habilitado
    if [ -L "$NGINX_SITES_ENABLED/$SITE" ]; then
        rm -f "$NGINX_SITES_ENABLED/$SITE"
    fi
    
    # Eliminar configuración
    rm -f "$NGINX_SITES_AVAILABLE/$SITE"
    
    # Eliminar archivos web
    if [ -d "$WEB_ROOT/$SITE" ]; then
        rm -rf "$WEB_ROOT/$SITE"
    fi
    
    # Eliminar logs
    rm -f "/var/log/nginx/${SITE}_"*.log
    
    # Recargar nginx
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Sitio $SITE eliminado exitosamente"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Ver configuración de sitio
view_site_config() {
    log_step "Viendo configuración de sitio..."
    
    # Mostrar sitios disponibles
    echo -e "${WHITE}Sitios disponibles:${NC}"
    available_sites=()
    if [ -d "$NGINX_SITES_AVAILABLE" ]; then
        for site in "$NGINX_SITES_AVAILABLE"/*; do
            if [ -f "$site" ]; then
                sitename=$(basename "$site")
                available_sites+=("$sitename")
                echo -e "   ${YELLOW}${#available_sites[@]}.${NC} $sitename"
            fi
        done
    fi
    
    if [ ${#available_sites[@]} -eq 0 ]; then
        log_warning "No hay sitios configurados"
        return 1
    fi
    
    read -p "Selecciona el sitio (número o nombre): " choice
    
    # Determinar el sitio seleccionado
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#available_sites[@]} ]; then
        SITE="${available_sites[$((choice-1))]}"
    else
        SITE="$choice"
    fi
    
    # Verificar que el sitio existe
    if [ ! -f "$NGINX_SITES_AVAILABLE/$SITE" ]; then
        log_error "El sitio $SITE no existe"
        return 1
    fi
    
    # Mostrar configuración
    echo -e "${WHITE}Configuración de $SITE:${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    cat "$NGINX_SITES_AVAILABLE/$SITE"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
}

# Verificar configuración nginx
test_nginx_config() {
    log_step "Verificando configuración de nginx..."
    
    if nginx -t; then
        log_success "Configuración de nginx es válida"
    else
        log_error "Error en la configuración de nginx"
        return 1
    fi
}

# Recargar nginx
reload_nginx() {
    log_step "Recargando nginx..."
    
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Nginx recargado exitosamente"
    else
        log_error "Error en la configuración de nginx. No se puede recargar."
        return 1
    fi
}

# Ver estado de nginx
nginx_status() {
    log_step "Verificando estado de nginx..."
    
    systemctl status nginx --no-pager
}

# Ver logs de acceso
view_access_logs() {
    log_step "Viendo logs de acceso..."
    
    echo -e "${WHITE}Logs de acceso disponibles:${NC}"
    echo -e "   ${YELLOW}1.${NC} Logs generales (/var/log/nginx/access.log)"
    echo -e "   ${YELLOW}2.${NC} Logs de sitio específico"
    
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1)
            log_info "Mostrando logs generales de acceso..."
            tail -f /var/log/nginx/access.log
            ;;
        2)
            # Mostrar sitios con logs
            echo -e "${WHITE}Sitios con logs:${NC}"
            log_files=($(ls /var/log/nginx/*_access.log 2>/dev/null))
            if [ ${#log_files[@]} -eq 0 ]; then
                log_warning "No hay logs de sitios específicos"
                return 1
            fi
            
            for i in "${!log_files[@]}"; do
                sitename=$(basename "${log_files[$i]}" _access.log)
                echo -e "   ${YELLOW}$((i+1)).${NC} $sitename"
            done
            
            read -p "Selecciona el sitio: " site_choice
            if [[ "$site_choice" =~ ^[0-9]+$ ]] && [ "$site_choice" -ge 1 ] && [ "$site_choice" -le ${#log_files[@]} ]; then
                selected_log="${log_files[$((site_choice-1))]}"
                log_info "Mostrando logs de $(basename "$selected_log" _access.log)..."
                tail -f "$selected_log"
            else
                log_error "Selección inválida"
            fi
            ;;
        *)
            log_error "Opción inválida"
            ;;
    esac
}

# Ver logs de errores
view_error_logs() {
    log_step "Viendo logs de errores..."
    
    echo -e "${WHITE}Logs de errores disponibles:${NC}"
    echo -e "   ${YELLOW}1.${NC} Logs generales (/var/log/nginx/error.log)"
    echo -e "   ${YELLOW}2.${NC} Logs de sitio específico"
    
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1)
            log_info "Mostrando logs generales de errores..."
            tail -f /var/log/nginx/error.log
            ;;
        2)
            # Mostrar sitios con logs
            echo -e "${WHITE}Sitios con logs:${NC}"
            log_files=($(ls /var/log/nginx/*_error.log 2>/dev/null))
            if [ ${#log_files[@]} -eq 0 ]; then
                log_warning "No hay logs de errores de sitios específicos"
                return 1
            fi
            
            for i in "${!log_files[@]}"; do
                sitename=$(basename "${log_files[$i]}" _error.log)
                echo -e "   ${YELLOW}$((i+1)).${NC} $sitename"
            done
            
            read -p "Selecciona el sitio: " site_choice
            if [[ "$site_choice" =~ ^[0-9]+$ ]] && [ "$site_choice" -ge 1 ] && [ "$site_choice" -le ${#log_files[@]} ]; then
                selected_log="${log_files[$((site_choice-1))]}"
                log_info "Mostrando logs de errores de $(basename "$selected_log" _error.log)..."
                tail -f "$selected_log"
            else
                log_error "Selección inválida"
            fi
            ;;
        *)
            log_error "Opción inválida"
            ;;
    esac
}

# Función principal
main() {
    # Verificaciones iniciales
    check_root
    check_nginx
    
    # Si se pasa un argumento, ejecutar comando directamente
    if [ $# -gt 0 ]; then
        case $1 in
            "create-site")
                create_site
                ;;
            "create-site-port")
                create_site_by_port
                ;;
            "list-sites")
                list_sites
                ;;
            "enable-site")
                enable_site
                ;;
            "disable-site")
                disable_site
                ;;
            "remove-site")
                remove_site
                ;;
            "status")
                nginx_status
                ;;
            "reload")
                reload_nginx
                ;;
            "test")
                test_nginx_config
                ;;
            *)
                log_error "Comando desconocido: $1"
                echo "Comandos disponibles: create-site, create-site-port, list-sites, enable-site, disable-site, remove-site, status, reload, test"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # Menú interactivo
    while true; do
        show_banner
        show_menu
        
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1)
                create_site
                ;;
            2)
                create_site_by_port
                ;;
            3)
                list_sites
                ;;
            4)
                enable_site
                ;;
            5)
                disable_site
                ;;
            6)
                remove_site
                ;;
            7)
                view_site_config
                ;;
            8)
                echo "Función de edición no implementada aún"
                ;;
            9)
                test_nginx_config
                ;;
            10)
                reload_nginx
                ;;
            11)
                nginx_status
                ;;
            12)
                view_access_logs
                ;;
            13)
                view_error_logs
                ;;
            14)
                echo "Función de optimización no implementada aún"
                ;;
            15)
                echo "Función de PHP no implementada aún"
                ;;
            16)
                echo "Función de SSL no implementada aún (usar ssl-manager)"
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
}

# Ejecutar función principal
main "$@" 