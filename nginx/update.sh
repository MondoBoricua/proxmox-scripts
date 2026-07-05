#!/bin/bash

# Nginx + PHP Server - Script de Actualización v3.0
# Ejecutar DENTRO del contenedor existente
# Desarrollado para la comunidad de Proxmox
# Hecho en Puerto Rico

# Silenciar warnings de locale
export LC_ALL=C
export LANG=C

# Variables
SCRIPT_VERSION="3.0"
INSTALL_PHP="no"
PHP_VERSION="8.2"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Funciones de utilidad
show_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
show_success() { echo -e "${GREEN}[OK]${NC} $1"; }
show_error() { echo -e "${RED}[ERROR]${NC} $1"; }
show_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
show_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# =============================================================================
# BANNER
# =============================================================================

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "||                                                              ||"
    echo "||          NGINX + PHP SERVER - UPDATE SCRIPT v${SCRIPT_VERSION}            ||"
    echo "||                                                              ||"
    echo "||              Actualizar contenedor existente                 ||"
    echo "||                                                              ||"
    echo "=================================================================="
    echo -e "${NC}"
    echo ""
}

# =============================================================================
# VERIFICACIONES
# =============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

check_nginx() {
    if ! command -v nginx &> /dev/null; then
        show_error "Nginx no esta instalado en este contenedor"
        show_info "Este script es para actualizar contenedores existentes con Nginx"
        exit 1
    fi
    show_success "Nginx detectado: $(nginx -v 2>&1 | cut -d'/' -f2)"
}

check_php() {
    if command -v php &> /dev/null; then
        PHP_CURRENT=$(php -v | head -1 | cut -d' ' -f2)
        show_info "PHP ya instalado: $PHP_CURRENT"
        return 0
    fi
    return 1
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        show_info "Sistema detectado: $DISTRO $DISTRO_VERSION"
    else
        show_error "No se pudo detectar la distribucion"
        exit 1
    fi
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo -e "${WHITE}Que deseas hacer?${NC}"
    echo ""
    echo "   1) Instalar PHP (si no esta instalado)"
    echo "   2) Actualizar herramientas de gestion"
    echo "   3) Actualizar pagina de bienvenida"
    echo "   4) Actualizar TODO (PHP + herramientas + pagina)"
    echo "   5) Solo actualizar configuracion de Nginx"
    echo "   0) Salir"
    echo ""
    echo -ne "${GREEN}>${NC} Opcion [4]: "
    read option
    option=${option:-4}
}

# =============================================================================
# INSTALACION DE PHP
# =============================================================================

install_php() {
    if check_php; then
        echo ""
        echo -ne "${YELLOW}PHP ya esta instalado. Reinstalar/actualizar? [y/N]:${NC} "
        read reinstall
        if [[ ! "$reinstall" =~ ^[SsYy]$ ]]; then
            show_info "Saltando instalacion de PHP"
            return 0
        fi
    fi

    echo ""
    echo -e "${WHITE}Versiones de PHP disponibles:${NC}"
    echo "   1) PHP 8.1 (LTS - stable)"
    echo "   2) PHP 8.2 (recommended)"
    echo "   3) PHP 8.3 (latest)"
    echo ""
    echo -ne "${GREEN}>${NC} Version [2]: "
    read php_choice
    php_choice=${php_choice:-2}

    case "$php_choice" in
        1) PHP_VERSION="8.1" ;;
        3) PHP_VERSION="8.3" ;;
        *) PHP_VERSION="8.2" ;;
    esac

    show_step "Instalando PHP $PHP_VERSION..."

    # Agregar repositorio segun distro
    if [ "$DISTRO" = "ubuntu" ]; then
        show_info "Agregando repositorio ppa:ondrej/php..."
        apt install -y software-properties-common
        add-apt-repository -y ppa:ondrej/php
        apt update
    elif [ "$DISTRO" = "debian" ]; then
        show_info "Agregando repositorio sury.org..."
        apt install -y apt-transport-https lsb-release ca-certificates curl
        curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
        dpkg -i /tmp/debsuryorg-archive-keyring.deb
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
        apt update
    fi

    # Instalar PHP-FPM y modulos
    show_info "Instalando PHP-FPM y modulos..."
    apt install -y \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-imagick || true

    # Habilitar PHP-FPM
    systemctl enable php${PHP_VERSION}-fpm
    systemctl start php${PHP_VERSION}-fpm

    # Configurar PHP
    show_info "Optimizando configuracion de PHP..."
    PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
    if [ -f "$PHP_INI" ]; then
        sed -i 's/expose_php = On/expose_php = Off/' $PHP_INI
        sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHP_INI
        sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' $PHP_INI
        sed -i 's/post_max_size = 8M/post_max_size = 64M/' $PHP_INI
        sed -i 's/memory_limit = 128M/memory_limit = 256M/' $PHP_INI
        sed -i 's/max_execution_time = 30/max_execution_time = 300/' $PHP_INI
        sed -i 's/max_input_time = 60/max_input_time = 300/' $PHP_INI
        sed -i 's/;date.timezone =/date.timezone = UTC/' $PHP_INI
    fi

    # Configurar pool
    PHP_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    if [ -f "$PHP_POOL" ]; then
        sed -i 's/pm.max_children = 5/pm.max_children = 20/' $PHP_POOL
        sed -i 's/pm.start_servers = 2/pm.start_servers = 4/' $PHP_POOL
        sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 2/' $PHP_POOL
        sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 6/' $PHP_POOL
    fi

    systemctl restart php${PHP_VERSION}-fpm

    # Instalar Composer
    show_info "Instalando Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    show_success "PHP $PHP_VERSION instalado correctamente"
    INSTALL_PHP="yes"
}

# =============================================================================
# CONFIGURAR NGINX PARA PHP
# =============================================================================

configure_nginx_php() {
    # Detectar version de PHP instalada
    PHP_INSTALLED=$(ls /var/run/php/ 2>/dev/null | grep -oP 'php\K[0-9]+\.[0-9]+' | head -1)

    if [ -z "$PHP_INSTALLED" ]; then
        show_warning "PHP-FPM no detectado, saltando configuracion de Nginx"
        return 1
    fi

    show_step "Configurando Nginx para PHP $PHP_INSTALLED..."

    cat > /etc/nginx/sites-available/default << NGINXCONF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # PHP-FPM configuration
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_INSTALLED}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;

        # Timeouts
        fastcgi_connect_timeout 60;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Deny access to .htaccess
    location ~ /\.ht {
        deny all;
    }

    # Deny access to sensitive files
    location ~* \.(env|log|ini)\$ {
        deny all;
    }

    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|woff|woff2|ttf|svg)\$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml application/javascript application/json;
}
NGINXCONF

    nginx -t && systemctl reload nginx
    show_success "Nginx configurado para PHP"
}

# =============================================================================
# INSTALAR HERRAMIENTAS DE GESTION
# =============================================================================

install_tools() {
    show_step "Instalando herramientas de gestion..."

    mkdir -p /opt/nginx-server

    # Detectar si PHP esta instalado
    PHP_INSTALLED="no"
    if command -v php &> /dev/null; then
        PHP_INSTALLED="yes"
    fi

    # Crear welcome.sh
    cat > /opt/nginx-server/welcome.sh << 'WELCOMESCRIPT'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
NGINX_STATUS=$(systemctl is-active nginx)
NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
UPTIME=$(uptime -p)
MEMORY=$(free -h | grep Mem | awk '{print $3 "/" $2}')
DISK=$(df -h / | tail -1 | awk '{print $3 "/" $2}')

PHP_INSTALLED="no"
PHP_VERSION=""
if command -v php &> /dev/null; then
    PHP_INSTALLED="yes"
    PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2)
fi

clear
echo -e "${CYAN}"
echo "=================================================================="
echo "||                                                              ||"
echo "||              NGINX + PHP WEB SERVER - INFO                   ||"
echo "||                                                              ||"
echo "=================================================================="
echo -e "${NC}"

echo -e "${WHITE}Server Information${NC}"
echo -e "   ${CYAN}Hostname:${NC} $HOSTNAME"
echo -e "   ${CYAN}IP Address:${NC} $IP_ADDRESS"
echo -e "   ${CYAN}Uptime:${NC} $UPTIME"
echo -e "   ${CYAN}Memory:${NC} $MEMORY"
echo -e "   ${CYAN}Disk:${NC} $DISK"
echo

echo -e "${WHITE}Services Status${NC}"
if [ "$NGINX_STATUS" = "active" ]; then
    echo -e "   ${GREEN}[OK]${NC} Nginx $NGINX_VERSION"
else
    echo -e "   ${RED}[X]${NC} Nginx (inactive)"
fi

if [ "$PHP_INSTALLED" = "yes" ]; then
    PHP_FPM_STATUS=$(systemctl is-active php*-fpm 2>/dev/null || echo "inactive")
    if [ "$PHP_FPM_STATUS" = "active" ]; then
        echo -e "   ${GREEN}[OK]${NC} PHP-FPM $PHP_VERSION"
    else
        echo -e "   ${RED}[X]${NC} PHP-FPM (inactive)"
    fi

    if command -v composer &> /dev/null; then
        COMPOSER_VER=$(composer --version 2>/dev/null | awk '{print $3}')
        echo -e "   ${GREEN}[OK]${NC} Composer $COMPOSER_VER"
    fi
fi
echo

echo -e "${WHITE}Important Directories${NC}"
echo -e "   ${CYAN}Web root:${NC} /var/www/html"
echo -e "   ${CYAN}Nginx config:${NC} /etc/nginx/"
echo -e "   ${CYAN}Sites available:${NC} /etc/nginx/sites-available/"
echo -e "   ${CYAN}Logs:${NC} /var/log/nginx/"
if [ "$PHP_INSTALLED" = "yes" ]; then
    echo -e "   ${CYAN}PHP config:${NC} /etc/php/"
fi
echo

echo -e "${WHITE}Useful Commands${NC}"
echo -e "   ${YELLOW}nginx-info${NC}      - Show this information"
echo -e "   ${YELLOW}nginx-manager${NC}   - Manage web sites"
echo -e "   ${YELLOW}ssl-manager${NC}     - Manage SSL certificates"
echo -e "   ${YELLOW}nginx-status${NC}    - Show nginx status"
echo -e "   ${YELLOW}nginx-test${NC}      - Test configuration"
echo -e "   ${YELLOW}nginx-reload${NC}    - Reload configuration"
if [ "$PHP_INSTALLED" = "yes" ]; then
    echo -e "   ${YELLOW}php-manager${NC}     - Manage PHP settings"
    echo -e "   ${YELLOW}php-status${NC}      - Show PHP-FPM status"
fi
echo

echo -e "${WHITE}Quick Access${NC}"
for site in /etc/nginx/sites-enabled/*; do
    if [ -f "$site" ]; then
        site_name=$(basename "$site")
        site_port=$(grep -E "^\s*listen\s+" "$site" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)
        site_port=${site_port:-80}
        if [ "$site_port" = "80" ]; then
            echo -e "   ${CYAN}${site_name}:${NC} http://$IP_ADDRESS"
        else
            echo -e "   ${CYAN}${site_name}:${NC} http://$IP_ADDRESS:$site_port"
        fi
    fi
done
if [ "$PHP_INSTALLED" = "yes" ]; then
    echo -e "   ${CYAN}PHP Info:${NC} http://$IP_ADDRESS/info.php"
fi
echo

echo -e "${PURPLE}Developed for the Proxmox community${NC}"
echo -e "${PURPLE}Made in Puerto Rico${NC}"
echo
WELCOMESCRIPT

    chmod +x /opt/nginx-server/welcome.sh

    # Crear php-manager.sh
    cat > /opt/nginx-server/php-manager.sh << 'PHPMANAGER'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

if ! command -v php &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} PHP no esta instalado"
    exit 1
fi

PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)

show_menu() {
    clear
    echo -e "${CYAN}"
    echo "================================================"
    echo "           PHP Manager - v1.0"
    echo "================================================"
    echo -e "${NC}"
    echo ""
    echo "   1) Show PHP info"
    echo "   2) Show installed modules"
    echo "   3) Restart PHP-FPM"
    echo "   4) View PHP-FPM status"
    echo "   5) Edit php.ini"
    echo "   6) View PHP-FPM logs"
    echo "   7) Clear OPcache"
    echo "   8) Update Composer"
    echo "   0) Exit"
    echo ""
    echo -ne "${GREEN}>${NC} Select option: "
}

while true; do
    show_menu
    read option

    case $option in
        1)
            echo ""
            php -v
            echo ""
            echo "Config file: $(php --ini | grep 'Loaded Configuration' | cut -d':' -f2)"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            php -m
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            systemctl restart php${PHP_VERSION}-fpm
            echo -e "${GREEN}[OK]${NC} PHP-FPM restarted"
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            systemctl status php${PHP_VERSION}-fpm
            read -p "Press Enter to continue..."
            ;;
        5)
            nano /etc/php/${PHP_VERSION}/fpm/php.ini
            echo ""
            echo -ne "Restart PHP-FPM? (y/n): "
            read restart
            if [[ "$restart" =~ ^[Yy]$ ]]; then
                systemctl restart php${PHP_VERSION}-fpm
                echo -e "${GREEN}[OK]${NC} PHP-FPM restarted"
            fi
            ;;
        6)
            echo ""
            journalctl -u php${PHP_VERSION}-fpm -n 50
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            if php -r "opcache_reset();" 2>/dev/null; then
                echo -e "${GREEN}[OK]${NC} OPcache cleared"
            else
                echo -e "${YELLOW}[WARN]${NC} Could not clear OPcache"
            fi
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            composer self-update
            read -p "Press Enter to continue..."
            ;;
        0)
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done
PHPMANAGER

    chmod +x /opt/nginx-server/php-manager.sh

    # Crear nginx-manager.sh
    cat > /opt/nginx-server/nginx-manager.sh << 'NGINXMANAGER'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${CYAN}"
    echo "================================================"
    echo "           Nginx Manager - v1.0"
    echo "================================================"
    echo -e "${NC}"
    echo ""
    echo "   1) List sites"
    echo "   2) Enable site"
    echo "   3) Disable site"
    echo "   4) Create new site"
    echo "   5) Test configuration"
    echo "   6) Reload Nginx"
    echo "   7) View access logs"
    echo "   8) View error logs"
    echo "   0) Exit"
    echo ""
    echo -ne "${GREEN}>${NC} Select option: "
}

list_sites() {
    local IP=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${WHITE}Enabled Sites:${NC}"
    echo ""

    for site in /etc/nginx/sites-enabled/*; do
        if [ -f "$site" ]; then
            local name=$(basename "$site")
            local port=$(grep -E "^\s*listen\s+" "$site" | head -1 | grep -oE '[0-9]+' | head -1)
            port=${port:-80}
            local root=$(grep -E "^\s*root\s+" "$site" | head -1 | awk '{print $2}' | tr -d ';')

            if [ "$port" = "80" ]; then
                echo -e "   ${GREEN}[ON]${NC} $name"
                echo -e "        ${CYAN}http://${IP}${NC}"
            else
                echo -e "   ${GREEN}[ON]${NC} $name"
                echo -e "        ${CYAN}http://${IP}:${port}${NC}"
            fi
            [ -n "$root" ] && echo -e "        Root: $root"
            echo ""
        fi
    done

    echo -e "${WHITE}Available (disabled):${NC}"
    echo ""
    for site in /etc/nginx/sites-available/*; do
        if [ -f "$site" ]; then
            local name=$(basename "$site")
            if [ ! -f "/etc/nginx/sites-enabled/$name" ]; then
                local port=$(grep -E "^\s*listen\s+" "$site" | head -1 | grep -oE '[0-9]+' | head -1)
                port=${port:-80}
                echo -e "   ${RED}[OFF]${NC} $name (port $port)"
            fi
        fi
    done
    echo ""
}

while true; do
    show_menu
    read option

    case $option in
        1)
            list_sites
            read -p "Press Enter to continue..."
            ;;
        2)
            list_sites
            echo -ne "Site name to enable: "
            read site
            if [ -f "/etc/nginx/sites-available/$site" ]; then
                ln -sf /etc/nginx/sites-available/$site /etc/nginx/sites-enabled/
                nginx -t && systemctl reload nginx
                echo -e "${GREEN}[OK]${NC} Site enabled"
            else
                echo -e "${RED}[ERROR]${NC} Site not found"
            fi
            read -p "Press Enter to continue..."
            ;;
        3)
            list_sites
            echo -ne "Site name to disable: "
            read site
            if [ -f "/etc/nginx/sites-enabled/$site" ]; then
                rm /etc/nginx/sites-enabled/$site
                systemctl reload nginx
                echo -e "${GREEN}[OK]${NC} Site disabled"
            else
                echo -e "${RED}[ERROR]${NC} Site not enabled"
            fi
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            echo "   1) Create site by PORT (recommended for multiple sites)"
            echo "   2) Create site by DOMAIN"
            echo ""
            echo -ne "${GREEN}>${NC} Option [1]: "
            read site_type
            site_type=${site_type:-1}

            # Detectar PHP
            PHP_SOCK=""
            if ls /var/run/php/php*-fpm.sock &>/dev/null; then
                PHP_SOCK=$(ls /var/run/php/php*-fpm.sock | head -1)
            fi

            if [ "$site_type" = "1" ]; then
                # Crear por puerto - detectar siguiente puerto disponible
                last_port=$(ls /etc/nginx/sites-available/ 2>/dev/null | grep -oP 'site-\K[0-9]+' | sort -n | tail -1)
                if [ -n "$last_port" ]; then
                    next_port=$((last_port + 1))
                else
                    next_port=8080
                fi

                echo -ne "Port number [${next_port}]: "
                read port
                port=${port:-$next_port}

                if [ -z "$port" ]; then
                    echo -e "${RED}[ERROR]${NC} Port is required"
                    read -p "Press Enter to continue..."
                    continue
                fi

                site_name="site-${port}"
                docroot="/var/www/${site_name}"

                mkdir -p $docroot
                chown -R www-data:www-data $docroot

                # Crear index.html por defecto
                cat > $docroot/index.html << INDEXHTML
<!DOCTYPE html>
<html>
<head>
    <title>Site ${port}</title>
    <style>
        body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: linear-gradient(135deg, #1a1a2e, #16213e); color: white; }
        .container { text-align: center; }
        h1 { font-size: 3rem; }
        p { color: #9ca3af; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Site :${port}</h1>
        <p>Your site is ready at port ${port}</p>
        <p>Document root: ${docroot}</p>
    </div>
</body>
</html>
INDEXHTML

                cat > /etc/nginx/sites-available/$site_name << SITECONF
server {
    listen ${port};
    listen [::]:${port};

    root ${docroot};
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK:-/var/run/php/php-fpm.sock};
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
SITECONF

                # Abrir puerto en firewall
                ufw allow ${port}/tcp 2>/dev/null

                echo -e "${GREEN}[OK]${NC} Site created: $site_name"
                local IP=$(hostname -I | awk '{print $1}')
                echo -e "${CYAN}URL: http://${IP}:${port}${NC}"
                echo -e "Root: $docroot"

                ln -sf /etc/nginx/sites-available/$site_name /etc/nginx/sites-enabled/
                nginx -t && systemctl reload nginx
                echo -e "${GREEN}[OK]${NC} Site enabled"

            else
                # Crear por dominio
                echo -ne "Domain name: "
                read domain
                echo -ne "Document root [/var/www/$domain]: "
                read docroot
                docroot=${docroot:-/var/www/$domain}

                mkdir -p $docroot
                chown -R www-data:www-data $docroot

                cat > /etc/nginx/sites-available/$domain << SITECONF
server {
    listen 80;
    server_name $domain www.$domain;
    root $docroot;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK:-/var/run/php/php-fpm.sock};
    }

    location ~ /\.ht {
        deny all;
    }
}
SITECONF

                echo -e "${GREEN}[OK]${NC} Site created: /etc/nginx/sites-available/$domain"
                echo -ne "Enable now? (y/n): "
                read enable
                if [[ "$enable" =~ ^[Yy]$ ]]; then
                    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
                    nginx -t && systemctl reload nginx
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        5)
            echo ""
            nginx -t
            read -p "Press Enter to continue..."
            ;;
        6)
            systemctl reload nginx
            echo -e "${GREEN}[OK]${NC} Nginx reloaded"
            read -p "Press Enter to continue..."
            ;;
        7)
            tail -f /var/log/nginx/access.log
            ;;
        8)
            tail -f /var/log/nginx/error.log
            ;;
        0)
            exit 0
            ;;
    esac
done
NGINXMANAGER

    chmod +x /opt/nginx-server/nginx-manager.sh

    # Crear ssl-manager.sh
    cat > /opt/nginx-server/ssl-manager.sh << 'SSLMANAGER'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "================================================"
echo "           SSL Manager - v1.0"
echo "================================================"
echo -e "${NC}"
echo ""
echo "   1) Request SSL certificate"
echo "   2) Renew all certificates"
echo "   3) List certificates"
echo "   0) Exit"
echo ""
echo -ne "${GREEN}>${NC} Select option: "
read option

case $option in
    1)
        echo -ne "Domain name: "
        read domain
        echo -ne "Email for Let's Encrypt: "
        read email
        certbot --nginx -d $domain -d www.$domain --email $email --agree-tos --non-interactive
        ;;
    2)
        certbot renew
        ;;
    3)
        certbot certificates
        ;;
    0)
        exit 0
        ;;
esac
SSLMANAGER

    chmod +x /opt/nginx-server/ssl-manager.sh

    # Actualizar aliases en .bashrc
    show_info "Actualizando aliases..."

    # Remover aliases antiguos si existen (linea por linea, mas seguro)
    grep -v "# Nginx + PHP Server Aliases" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "# PHP Aliases" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-info=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-manager=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-logs=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-errors=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-test=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-reload=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-restart=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias nginx-status=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias ssl-manager=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias php-manager=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias php-status=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias php-restart=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "alias php-logs=" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "# Show welcome on login" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc
    grep -v "/opt/nginx-server/welcome.sh" /root/.bashrc > /tmp/.bashrc.tmp && mv /tmp/.bashrc.tmp /root/.bashrc

    # Agregar nuevos aliases al final
    cat >> /root/.bashrc << 'BASHALIASES'

# Nginx + PHP Server Aliases
alias nginx-info='/opt/nginx-server/welcome.sh'
alias nginx-manager='/opt/nginx-server/nginx-manager.sh'
alias ssl-manager='/opt/nginx-server/ssl-manager.sh'
alias nginx-logs='tail -f /var/log/nginx/access.log'
alias nginx-errors='tail -f /var/log/nginx/error.log'
alias nginx-test='nginx -t'
alias nginx-reload='systemctl reload nginx'
alias nginx-restart='systemctl restart nginx'
alias nginx-status='systemctl status nginx'

# PHP Aliases
alias php-manager='/opt/nginx-server/php-manager.sh'
alias php-status='systemctl status php*-fpm'
alias php-restart='systemctl restart php*-fpm'
alias php-logs='journalctl -u php*-fpm -f'

# Show welcome on login
/opt/nginx-server/welcome.sh
BASHALIASES

    show_success "Herramientas instaladas"
}

# =============================================================================
# ACTUALIZAR PAGINA DE BIENVENIDA
# =============================================================================

update_welcome_page() {
    show_step "Actualizando pagina de bienvenida..."

    # Detectar si PHP esta instalado
    if command -v php &> /dev/null; then
        # Pagina PHP dinamica
        cat > /var/www/html/index.php << 'PHPHTML'
<?php
$hostname = gethostname();
$ip = shell_exec("hostname -I | awk '{print $1}'");
$phpVersion = phpversion();
$nginxVersion = shell_exec("nginx -v 2>&1 | cut -d'/' -f2");
$uptime = shell_exec("uptime -p");
$memory = shell_exec("free -h | grep Mem | awk '{print $3 \"/\" $2}'");
$disk = shell_exec("df -h / | tail -1 | awk '{print $3 \"/\" $2}'");
$loadAvg = sys_getloadavg();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx + PHP Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            padding: 2rem;
        }
        .header { text-align: center; margin-bottom: 2rem; }
        .logo { font-size: 4rem; margin-bottom: 1rem; }
        h1 { font-size: 2rem; margin-bottom: 0.5rem; color: #4ade80; }
        .subtitle { color: #9ca3af; margin-bottom: 1rem; }
        .status {
            display: inline-block;
            padding: 0.5rem 1.5rem;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            border-radius: 25px;
            font-weight: bold;
            color: white;
        }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin: 2rem 0; }
        .card {
            background: rgba(255, 255, 255, 0.05);
            padding: 1.5rem;
            border-radius: 15px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            text-align: center;
        }
        .card h3 { color: #60a5fa; margin-bottom: 0.5rem; font-size: 0.9rem; }
        .card p { font-size: 1.2rem; font-weight: bold; }
        .card small { color: #9ca3af; font-size: 0.8rem; }
        .commands {
            background: rgba(0, 0, 0, 0.3);
            padding: 1.5rem;
            border-radius: 15px;
            margin: 2rem 0;
        }
        .commands h3 { color: #fbbf24; margin-bottom: 1rem; text-align: center; }
        .cmd-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 0.5rem; }
        code {
            display: block;
            background: rgba(0, 0, 0, 0.5);
            padding: 0.5rem;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            font-size: 0.85rem;
            color: #a5f3fc;
        }
        .footer { text-align: center; margin-top: 2rem; padding-top: 1rem; border-top: 1px solid rgba(255, 255, 255, 0.1); color: #9ca3af; }
        .tech-badge {
            display: inline-block;
            padding: 0.3rem 0.8rem;
            margin: 0.2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            font-size: 0.8rem;
        }
        .php-badge { background: #4f46e5; }
        .nginx-badge { background: #059669; }
        a { color: #60a5fa; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">[Web]</div>
            <h1>Nginx + PHP Server</h1>
            <p class="subtitle">Your web server is ready to serve content</p>
            <div class="status">[OK] ACTIVE</div>
            <div style="margin-top: 1rem;">
                <span class="tech-badge nginx-badge">Nginx <?= trim($nginxVersion) ?></span>
                <span class="tech-badge php-badge">PHP <?= $phpVersion ?></span>
            </div>
        </div>

        <div class="grid">
            <div class="card">
                <h3>HOSTNAME</h3>
                <p><?= $hostname ?></p>
            </div>
            <div class="card">
                <h3>IP ADDRESS</h3>
                <p><?= trim($ip) ?></p>
            </div>
            <div class="card">
                <h3>MEMORY</h3>
                <p><?= trim($memory) ?></p>
            </div>
            <div class="card">
                <h3>DISK</h3>
                <p><?= trim($disk) ?></p>
            </div>
            <div class="card">
                <h3>LOAD AVG</h3>
                <p><?= number_format($loadAvg[0], 2) ?></p>
                <small>1 min avg</small>
            </div>
            <div class="card">
                <h3>UPTIME</h3>
                <p style="font-size: 0.9rem;"><?= trim($uptime) ?></p>
            </div>
        </div>

        <div class="commands">
            <h3>Useful Commands</h3>
            <div class="cmd-grid">
                <code>nginx-info</code>
                <code>nginx-manager</code>
                <code>ssl-manager</code>
                <code>php-manager</code>
                <code>nginx-status</code>
                <code>nginx-reload</code>
                <code>composer --version</code>
                <code>php -v</code>
            </div>
        </div>

        <div style="text-align: center; margin: 1rem 0;">
            <p><a href="/info.php">View PHP Info</a></p>
        </div>

        <div class="footer">
            <p>Developed with care for the Proxmox community</p>
            <p>Made in Puerto Rico</p>
        </div>
    </div>
</body>
</html>
PHPHTML

        # Crear info.php
        cat > /var/www/html/info.php << 'PHPINFO'
<?php
phpinfo();
PHPINFO

        # Eliminar index.html si existe
        rm -f /var/www/html/index.html 2>/dev/null

    else
        # Pagina HTML estatica
        cat > /var/www/html/index.html << 'HTMLONLY'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Web Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            padding: 2rem;
            text-align: center;
        }
        .logo { font-size: 4rem; margin-bottom: 1rem; }
        h1 { font-size: 2rem; margin-bottom: 0.5rem; color: #4ade80; }
        .subtitle { color: #9ca3af; margin-bottom: 1rem; }
        .status {
            display: inline-block;
            padding: 0.5rem 1.5rem;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            border-radius: 25px;
            font-weight: bold;
            color: white;
            margin: 1rem 0;
        }
        .info {
            background: rgba(0, 0, 0, 0.3);
            padding: 1.5rem;
            border-radius: 15px;
            margin: 2rem 0;
            text-align: left;
        }
        .info h3 { color: #fbbf24; margin-bottom: 1rem; text-align: center; }
        code {
            display: block;
            background: rgba(0, 0, 0, 0.5);
            padding: 0.5rem;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            margin: 0.5rem 0;
            color: #a5f3fc;
        }
        .footer { margin-top: 2rem; padding-top: 1rem; border-top: 1px solid rgba(255, 255, 255, 0.1); color: #9ca3af; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">[Web]</div>
        <h1>Nginx Web Server</h1>
        <p class="subtitle">Your web server is ready to serve content</p>
        <div class="status">[OK] ACTIVE</div>

        <div class="info">
            <h3>Useful Commands</h3>
            <code>nginx-info</code>
            <code>nginx-manager</code>
            <code>ssl-manager</code>
            <code>nginx-status</code>
            <code>nginx-reload</code>
        </div>

        <div class="footer">
            <p>Developed with care for the Proxmox community</p>
            <p>Made in Puerto Rico</p>
        </div>
    </div>
</body>
</html>
HTMLONLY
    fi

    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/

    show_success "Pagina de bienvenida actualizada"
}

# =============================================================================
# FUNCION PRINCIPAL
# =============================================================================

main() {
    show_banner
    check_root
    detect_distro
    check_nginx
    echo ""

    show_menu

    case $option in
        1)
            install_php
            configure_nginx_php
            ;;
        2)
            install_tools
            ;;
        3)
            update_welcome_page
            ;;
        4)
            install_php
            configure_nginx_php
            install_tools
            update_welcome_page
            ;;
        5)
            configure_nginx_php
            ;;
        0)
            echo "Bye!"
            exit 0
            ;;
        *)
            show_error "Opcion invalida"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}=================================================================="
    echo -e "||              [OK] ACTUALIZACION COMPLETADA                  ||"
    echo -e "==================================================================${NC}"
    echo ""
    echo -e "${CYAN}Ejecuta 'source ~/.bashrc' o reconecta para usar los nuevos comandos${NC}"
    echo ""
}

main "$@"
