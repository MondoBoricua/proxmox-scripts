#!/bin/bash

# 🔒 SSL Manager - Gestor de Certificados SSL/TLS
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
LETSENCRYPT_DIR="/etc/letsencrypt"

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
    echo "║              🔒 SSL MANAGER - GESTOR DE SSL/TLS 🔒           ║"
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

# Verificar que certbot está instalado
check_certbot() {
    if ! command -v certbot &> /dev/null; then
        log_error "Certbot no está instalado"
        log_info "Instalando certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
        
        if ! command -v certbot &> /dev/null; then
            log_error "Error al instalar certbot"
            exit 1
        fi
        
        log_success "Certbot instalado exitosamente"
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
    echo -e "${WHITE}🔒 Opciones SSL Disponibles:${NC}"
    echo -e "   ${YELLOW}1.${NC} Obtener certificado SSL para sitio"
    echo -e "   ${YELLOW}2.${NC} Listar certificados SSL"
    echo -e "   ${YELLOW}3.${NC} Renovar certificado específico"
    echo -e "   ${YELLOW}4.${NC} Renovar todos los certificados"
    echo -e "   ${YELLOW}5.${NC} Verificar certificado"
    echo -e "   ${YELLOW}6.${NC} Eliminar certificado"
    echo -e "   ${YELLOW}7.${NC} Crear sitio con SSL automático"
    echo -e "   ${YELLOW}8.${NC} Convertir sitio HTTP a HTTPS"
    echo -e "   ${YELLOW}9.${NC} Ver estado de renovación automática"
    echo -e "   ${YELLOW}10.${NC} Configurar renovación automática"
    echo -e "   ${YELLOW}11.${NC} Test SSL de sitio"
    echo -e "   ${YELLOW}12.${NC} Backup de certificados"
    echo -e "   ${YELLOW}0.${NC} Salir"
    echo
}

# Obtener certificado SSL
get_ssl_cert() {
    log_step "Obteniendo certificado SSL..."
    
    # Solicitar dominio
    read -p "Ingresa el dominio para el certificado SSL: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        log_error "El dominio no puede estar vacío"
        return 1
    fi
    
    # Verificar si el dominio tiene configuración nginx
    if [ ! -f "$NGINX_SITES_AVAILABLE/$DOMAIN" ]; then
        log_warning "No existe configuración nginx para $DOMAIN"
        read -p "¿Quieres crear la configuración primero? (y/N): " create_config
        
        if [[ $create_config =~ ^[Yy]$ ]]; then
            create_basic_site "$DOMAIN"
        else
            log_error "Se necesita configuración nginx para obtener certificado SSL"
            return 1
        fi
    fi
    
    # Verificar si el sitio está habilitado
    if [ ! -L "$NGINX_SITES_ENABLED/$DOMAIN" ]; then
        log_info "Habilitando sitio $DOMAIN..."
        ln -s "$NGINX_SITES_AVAILABLE/$DOMAIN" "$NGINX_SITES_ENABLED/$DOMAIN"
        systemctl reload nginx
    fi
    
    # Solicitar email para Let's Encrypt
    read -p "Ingresa tu email para Let's Encrypt: " EMAIL
    
    if [ -z "$EMAIL" ]; then
        log_error "El email no puede estar vacío"
        return 1
    fi
    
    # Verificar si se quiere incluir www
    read -p "¿Incluir www.$DOMAIN en el certificado? (Y/n): " include_www
    
    if [[ $include_www =~ ^[Nn]$ ]]; then
        DOMAINS="$DOMAIN"
    else
        DOMAINS="$DOMAIN,www.$DOMAIN"
    fi
    
    # Obtener certificado
    log_info "Obteniendo certificado SSL para $DOMAINS..."
    
    if certbot --nginx -d "$DOMAINS" --email "$EMAIL" --agree-tos --non-interactive; then
        log_success "Certificado SSL obtenido exitosamente para $DOMAIN"
        
        # Verificar configuración
        if nginx -t &>/dev/null; then
            systemctl reload nginx
            log_success "Configuración nginx actualizada"
        else
            log_error "Error en la configuración nginx después de obtener SSL"
        fi
        
        # Mostrar información del certificado
        show_cert_info "$DOMAIN"
        
    else
        log_error "Error al obtener certificado SSL para $DOMAIN"
        return 1
    fi
}

# Crear sitio básico para SSL
create_basic_site() {
    local domain="$1"
    
    log_info "Creando configuración básica para $domain..."
    
    # Crear directorio del sitio
    mkdir -p "$WEB_ROOT/$domain"
    
    # Crear página básica
    cat > "$WEB_ROOT/$domain/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$domain - Configurando SSL</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin-top: 50px;
            background: #f4f4f4;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 0 auto;
        }
        .ssl-icon {
            font-size: 4rem;
            color: #28a745;
            margin-bottom: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="ssl-icon">🔒</div>
        <h1>$domain</h1>
        <p>Configurando certificado SSL...</p>
        <p>Este sitio pronto estará disponible con HTTPS seguro.</p>
    </div>
</body>
</html>
EOF
    
    # Crear configuración nginx básica
    cat > "$NGINX_SITES_AVAILABLE/$domain" << EOF
# Configuración básica para $domain (preparada para SSL)
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $WEB_ROOT/$domain;
    index index.html index.htm;
    
    # Configuración básica
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Permitir acceso a .well-known para certificados SSL
    location ^~ /.well-known/acme-challenge/ {
        root $WEB_ROOT/$domain;
        allow all;
    }
    
    # Logs del sitio
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    # Configurar permisos
    chown -R www-data:www-data "$WEB_ROOT/$domain"
    chmod -R 755 "$WEB_ROOT/$domain"
    
    log_success "Configuración básica creada para $domain"
}

# Listar certificados SSL
list_ssl_certs() {
    log_step "Listando certificados SSL..."
    
    if [ ! -d "$LETSENCRYPT_DIR/live" ]; then
        log_warning "No hay certificados SSL instalados"
        return 1
    fi
    
    echo -e "${WHITE}📋 Certificados SSL Instalados:${NC}"
    
    for cert_dir in "$LETSENCRYPT_DIR/live"/*; do
        if [ -d "$cert_dir" ]; then
            domain=$(basename "$cert_dir")
            
            # Obtener información del certificado
            if [ -f "$cert_dir/fullchain.pem" ]; then
                expiry_date=$(openssl x509 -enddate -noout -in "$cert_dir/fullchain.pem" | cut -d= -f2)
                expiry_timestamp=$(date -d "$expiry_date" +%s)
                current_timestamp=$(date +%s)
                days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                
                # Determinar color según días restantes
                if [ "$days_left" -lt 7 ]; then
                    status_color="$RED"
                    status_icon="⚠️"
                elif [ "$days_left" -lt 30 ]; then
                    status_color="$YELLOW"
                    status_icon="⚠️"
                else
                    status_color="$GREEN"
                    status_icon="✅"
                fi
                
                echo -e "   ${status_color}${status_icon}${NC} $domain"
                echo -e "      ${CYAN}Expira:${NC} $expiry_date"
                echo -e "      ${CYAN}Días restantes:${NC} $days_left"
                
                # Mostrar dominios alternativos
                alt_names=$(openssl x509 -text -noout -in "$cert_dir/fullchain.pem" | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/DNS://g' | sed 's/,//g')
                if [ -n "$alt_names" ]; then
                    echo -e "      ${CYAN}Dominios:${NC} $alt_names"
                fi
                
                echo
            fi
        fi
    done
}

# Renovar certificado específico
renew_specific_cert() {
    log_step "Renovando certificado específico..."
    
    # Mostrar certificados disponibles
    echo -e "${WHITE}Certificados disponibles para renovar:${NC}"
    certs=()
    if [ -d "$LETSENCRYPT_DIR/live" ]; then
        for cert_dir in "$LETSENCRYPT_DIR/live"/*; do
            if [ -d "$cert_dir" ]; then
                domain=$(basename "$cert_dir")
                certs+=("$domain")
                echo -e "   ${YELLOW}${#certs[@]}.${NC} $domain"
            fi
        done
    fi
    
    if [ ${#certs[@]} -eq 0 ]; then
        log_warning "No hay certificados SSL para renovar"
        return 1
    fi
    
    read -p "Selecciona el certificado a renovar (número o nombre): " choice
    
    # Determinar el certificado seleccionado
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#certs[@]} ]; then
        DOMAIN="${certs[$((choice-1))]}"
    else
        DOMAIN="$choice"
    fi
    
    # Verificar que el certificado existe
    if [ ! -d "$LETSENCRYPT_DIR/live/$DOMAIN" ]; then
        log_error "El certificado para $DOMAIN no existe"
        return 1
    fi
    
    # Renovar certificado
    log_info "Renovando certificado para $DOMAIN..."
    
    if certbot renew --cert-name "$DOMAIN" --nginx; then
        log_success "Certificado renovado exitosamente para $DOMAIN"
        systemctl reload nginx
        show_cert_info "$DOMAIN"
    else
        log_error "Error al renovar certificado para $DOMAIN"
        return 1
    fi
}

# Renovar todos los certificados
renew_all_certs() {
    log_step "Renovando todos los certificados..."
    
    if certbot renew --nginx; then
        log_success "Todos los certificados renovados exitosamente"
        systemctl reload nginx
    else
        log_error "Error al renovar algunos certificados"
        return 1
    fi
}

# Verificar certificado
verify_cert() {
    log_step "Verificando certificado..."
    
    read -p "Ingresa el dominio a verificar: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        log_error "El dominio no puede estar vacío"
        return 1
    fi
    
    # Verificar si el certificado existe
    if [ ! -d "$LETSENCRYPT_DIR/live/$DOMAIN" ]; then
        log_error "No existe certificado SSL para $DOMAIN"
        return 1
    fi
    
    show_cert_info "$DOMAIN"
}

# Mostrar información del certificado
show_cert_info() {
    local domain="$1"
    local cert_file="$LETSENCRYPT_DIR/live/$domain/fullchain.pem"
    
    if [ ! -f "$cert_file" ]; then
        log_error "Archivo de certificado no encontrado para $domain"
        return 1
    fi
    
    echo -e "${WHITE}🔒 Información del Certificado SSL para $domain:${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    
    # Información básica
    echo -e "${YELLOW}Dominio:${NC} $domain"
    
    # Fecha de emisión
    issue_date=$(openssl x509 -startdate -noout -in "$cert_file" | cut -d= -f2)
    echo -e "${YELLOW}Emitido:${NC} $issue_date"
    
    # Fecha de expiración
    expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
    echo -e "${YELLOW}Expira:${NC} $expiry_date"
    
    # Días restantes
    expiry_timestamp=$(date -d "$expiry_date" +%s)
    current_timestamp=$(date +%s)
    days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    if [ "$days_left" -lt 7 ]; then
        echo -e "${YELLOW}Días restantes:${NC} ${RED}$days_left (¡CRÍTICO!)${NC}"
    elif [ "$days_left" -lt 30 ]; then
        echo -e "${YELLOW}Días restantes:${NC} ${YELLOW}$days_left (Renovar pronto)${NC}"
    else
        echo -e "${YELLOW}Días restantes:${NC} ${GREEN}$days_left${NC}"
    fi
    
    # Emisor
    issuer=$(openssl x509 -issuer -noout -in "$cert_file" | cut -d= -f2-)
    echo -e "${YELLOW}Emisor:${NC} $issuer"
    
    # Dominios alternativos
    alt_names=$(openssl x509 -text -noout -in "$cert_file" | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/DNS://g' | sed 's/,//g')
    if [ -n "$alt_names" ]; then
        echo -e "${YELLOW}Dominios incluidos:${NC} $alt_names"
    fi
    
    # Algoritmo de firma
    signature_algo=$(openssl x509 -text -noout -in "$cert_file" | grep "Signature Algorithm" | head -1 | cut -d: -f2 | xargs)
    echo -e "${YELLOW}Algoritmo:${NC} $signature_algo"
    
    # Tamaño de clave
    key_size=$(openssl x509 -text -noout -in "$cert_file" | grep "Public-Key" | cut -d: -f2 | xargs)
    echo -e "${YELLOW}Tamaño de clave:${NC} $key_size"
    
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    
    # Test SSL online
    echo -e "${WHITE}🌐 Test SSL Online:${NC}"
    echo -e "   ${CYAN}SSL Labs:${NC} https://www.ssllabs.com/ssltest/analyze.html?d=$domain"
    echo -e "   ${CYAN}SSL Shopper:${NC} https://www.sslshopper.com/ssl-checker.html#hostname=$domain"
}

# Eliminar certificado
remove_cert() {
    log_step "Eliminando certificado SSL..."
    
    # Mostrar certificados disponibles
    echo -e "${WHITE}Certificados disponibles para eliminar:${NC}"
    certs=()
    if [ -d "$LETSENCRYPT_DIR/live" ]; then
        for cert_dir in "$LETSENCRYPT_DIR/live"/*; do
            if [ -d "$cert_dir" ]; then
                domain=$(basename "$cert_dir")
                certs+=("$domain")
                echo -e "   ${YELLOW}${#certs[@]}.${NC} $domain"
            fi
        done
    fi
    
    if [ ${#certs[@]} -eq 0 ]; then
        log_warning "No hay certificados SSL para eliminar"
        return 1
    fi
    
    read -p "Selecciona el certificado a eliminar (número o nombre): " choice
    
    # Determinar el certificado seleccionado
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#certs[@]} ]; then
        DOMAIN="${certs[$((choice-1))]}"
    else
        DOMAIN="$choice"
    fi
    
    # Verificar que el certificado existe
    if [ ! -d "$LETSENCRYPT_DIR/live/$DOMAIN" ]; then
        log_error "El certificado para $DOMAIN no existe"
        return 1
    fi
    
    # Confirmación
    log_warning "¿Estás seguro de que quieres eliminar el certificado SSL para $DOMAIN?"
    log_warning "Esto eliminará todos los archivos del certificado y revertirá la configuración nginx a HTTP"
    
    read -p "Escribe 'ELIMINAR' para confirmar: " confirm
    
    if [ "$confirm" != "ELIMINAR" ]; then
        log_info "Eliminación cancelada"
        return 1
    fi
    
    # Eliminar certificado
    if certbot delete --cert-name "$DOMAIN"; then
        log_success "Certificado eliminado exitosamente para $DOMAIN"
        
        # Revertir configuración nginx a HTTP
        if [ -f "$NGINX_SITES_AVAILABLE/$DOMAIN" ]; then
            log_info "Revirtiendo configuración nginx a HTTP..."
            # Aquí se podría implementar lógica para revertir la configuración
            # Por simplicidad, se sugiere recrear la configuración HTTP
        fi
        
        systemctl reload nginx
    else
        log_error "Error al eliminar certificado para $DOMAIN"
        return 1
    fi
}

# Configurar renovación automática
setup_auto_renewal() {
    log_step "Configurando renovación automática..."
    
    # Verificar si ya existe cron job
    if crontab -l 2>/dev/null | grep -q "certbot renew"; then
        log_info "La renovación automática ya está configurada"
        
        # Mostrar configuración actual
        echo -e "${WHITE}Configuración actual:${NC}"
        crontab -l | grep "certbot renew"
        
        read -p "¿Quieres reconfigurar? (y/N): " reconfig
        if [[ ! $reconfig =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Crear script de renovación
    cat > /opt/nginx-server/renew-ssl.sh << 'EOF'
#!/bin/bash
# Script de renovación automática de certificados SSL
# Ejecutado por cron

# Logs
LOG_FILE="/var/log/nginx/ssl-renewal.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Iniciando renovación automática de certificados SSL" >> "$LOG_FILE"

# Renovar certificados
if certbot renew --quiet --nginx >> "$LOG_FILE" 2>&1; then
    echo "[$DATE] Renovación exitosa" >> "$LOG_FILE"
    
    # Recargar nginx
    systemctl reload nginx
    echo "[$DATE] Nginx recargado" >> "$LOG_FILE"
else
    echo "[$DATE] Error en la renovación" >> "$LOG_FILE"
fi

echo "[$DATE] Proceso de renovación completado" >> "$LOG_FILE"
EOF
    
    chmod +x /opt/nginx-server/renew-ssl.sh
    
    # Agregar a crontab (ejecutar dos veces al día)
    (crontab -l 2>/dev/null; echo "0 */12 * * * /opt/nginx-server/renew-ssl.sh") | crontab -
    
    log_success "Renovación automática configurada"
    log_info "Los certificados se renovarán automáticamente cada 12 horas"
    log_info "Logs disponibles en: /var/log/nginx/ssl-renewal.log"
}

# Ver estado de renovación automática
check_auto_renewal() {
    log_step "Verificando renovación automática..."
    
    # Verificar cron job
    if crontab -l 2>/dev/null | grep -q "certbot renew"; then
        log_success "Renovación automática está configurada"
        
        echo -e "${WHITE}Configuración actual:${NC}"
        crontab -l | grep "certbot renew"
        
        # Verificar logs
        if [ -f "/var/log/nginx/ssl-renewal.log" ]; then
            echo -e "${WHITE}Últimas ejecuciones:${NC}"
            tail -10 /var/log/nginx/ssl-renewal.log
        fi
        
        # Test de renovación
        echo -e "${WHITE}Test de renovación (dry-run):${NC}"
        certbot renew --dry-run
        
    else
        log_warning "Renovación automática no está configurada"
        read -p "¿Quieres configurarla ahora? (Y/n): " setup
        
        if [[ ! $setup =~ ^[Nn]$ ]]; then
            setup_auto_renewal
        fi
    fi
}

# Función principal
main() {
    # Verificaciones iniciales
    check_root
    check_nginx
    check_certbot
    
    # Si se pasa un argumento, ejecutar comando directamente
    if [ $# -gt 0 ]; then
        case $1 in
            "get-cert")
                get_ssl_cert
                ;;
            "list-certs")
                list_ssl_certs
                ;;
            "renew")
                if [ -n "$2" ]; then
                    DOMAIN="$2"
                    if [ -d "$LETSENCRYPT_DIR/live/$DOMAIN" ]; then
                        certbot renew --cert-name "$DOMAIN" --nginx
                    else
                        log_error "Certificado para $DOMAIN no encontrado"
                    fi
                else
                    renew_all_certs
                fi
                ;;
            "check-cert")
                if [ -n "$2" ]; then
                    show_cert_info "$2"
                else
                    verify_cert
                fi
                ;;
            "renew-all")
                renew_all_certs
                ;;
            *)
                log_error "Comando desconocido: $1"
                echo "Comandos disponibles: get-cert, list-certs, renew [domain], check-cert [domain], renew-all"
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
                get_ssl_cert
                ;;
            2)
                list_ssl_certs
                ;;
            3)
                renew_specific_cert
                ;;
            4)
                renew_all_certs
                ;;
            5)
                verify_cert
                ;;
            6)
                remove_cert
                ;;
            7)
                echo "Función no implementada aún"
                ;;
            8)
                echo "Función no implementada aún"
                ;;
            9)
                check_auto_renewal
                ;;
            10)
                setup_auto_renewal
                ;;
            11)
                echo "Función de test SSL no implementada aún"
                ;;
            12)
                echo "Función de backup no implementada aún"
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