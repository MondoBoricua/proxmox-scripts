#!/bin/bash

# 💾 Backup Config - Herramientas de Backup y Restauración
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
BACKUP_DIR="/opt/nginx-server/backups"
NGINX_CONFIG_DIR="/etc/nginx"
WEB_ROOT="/var/www"
SSL_DIR="/etc/letsencrypt"
LOG_DIR="/var/log/nginx"

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
    echo "║            💾 BACKUP CONFIG - RESPALDO Y RESTAURACIÓN 💾     ║"
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

# Crear directorio de backups
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Directorio de backups creado: $BACKUP_DIR"
    fi
}

# Mostrar menú principal
show_menu() {
    echo -e "${WHITE}💾 Opciones de Backup Disponibles:${NC}"
    echo -e "   ${YELLOW}1.${NC} Crear backup completo"
    echo -e "   ${YELLOW}2.${NC} Backup solo configuraciones"
    echo -e "   ${YELLOW}3.${NC} Backup solo sitios web"
    echo -e "   ${YELLOW}4.${NC} Backup solo certificados SSL"
    echo -e "   ${YELLOW}5.${NC} Backup de logs"
    echo -e "   ${YELLOW}6.${NC} Listar backups disponibles"
    echo -e "   ${YELLOW}7.${NC} Restaurar backup"
    echo -e "   ${YELLOW}8.${NC} Eliminar backup"
    echo -e "   ${YELLOW}9.${NC} Configurar backup automático"
    echo -e "   ${YELLOW}10.${NC} Ver estado de backup automático"
    echo -e "   ${YELLOW}11.${NC} Verificar integridad de backup"
    echo -e "   ${YELLOW}12.${NC} Exportar backup a ubicación externa"
    echo -e "   ${YELLOW}0.${NC} Salir"
    echo
}

# Crear backup completo
create_full_backup() {
    log_step "Creando backup completo..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="nginx_full_backup_$timestamp"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    log_info "Creando backup completo: $backup_name"
    
    # Crear directorio temporal para el backup
    local temp_dir="/tmp/nginx_backup_$timestamp"
    mkdir -p "$temp_dir"
    
    # Copiar configuraciones de nginx
    if [ -d "$NGINX_CONFIG_DIR" ]; then
        log_info "Respaldando configuraciones de nginx..."
        cp -r "$NGINX_CONFIG_DIR" "$temp_dir/nginx_config"
    fi
    
    # Copiar sitios web
    if [ -d "$WEB_ROOT" ]; then
        log_info "Respaldando sitios web..."
        cp -r "$WEB_ROOT" "$temp_dir/web_root"
    fi
    
    # Copiar certificados SSL
    if [ -d "$SSL_DIR" ]; then
        log_info "Respaldando certificados SSL..."
        cp -r "$SSL_DIR" "$temp_dir/ssl_certs"
    fi
    
    # Copiar logs (solo los más recientes)
    if [ -d "$LOG_DIR" ]; then
        log_info "Respaldando logs recientes..."
        mkdir -p "$temp_dir/logs"
        find "$LOG_DIR" -name "*.log" -mtime -7 -exec cp {} "$temp_dir/logs/" \;
    fi
    
    # Crear archivo de información del backup
    cat > "$temp_dir/backup_info.txt" << EOF
Backup Information
==================
Backup Type: Full Backup
Created: $(date)
Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')
Nginx Version: $(nginx -v 2>&1 | cut -d'/' -f2)
System Info: $(uname -a)

Contents:
- Nginx configurations (/etc/nginx)
- Web sites (/var/www)
- SSL certificates (/etc/letsencrypt)
- Recent logs (last 7 days)

Backup created by nginx-server backup tool
EOF
    
    # Crear archivo tar comprimido
    log_info "Comprimiendo backup..."
    if tar -czf "$backup_file" -C "$temp_dir" .; then
        log_success "Backup completo creado: $backup_file"
        
        # Mostrar información del backup
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_info "Tamaño del backup: $backup_size"
        
        # Crear checksum para verificación de integridad
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $backup_name.tar.gz" > "$BACKUP_DIR/$backup_name.sha256"
        log_info "Checksum creado: $backup_name.sha256"
        
    else
        log_error "Error al crear el backup"
        return 1
    fi
    
    # Limpiar directorio temporal
    rm -rf "$temp_dir"
}

# Crear backup de configuraciones
create_config_backup() {
    log_step "Creando backup de configuraciones..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="nginx_config_backup_$timestamp"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    if [ ! -d "$NGINX_CONFIG_DIR" ]; then
        log_error "Directorio de configuraciones nginx no encontrado"
        return 1
    fi
    
    # Crear backup de configuraciones
    if tar -czf "$backup_file" -C "$(dirname $NGINX_CONFIG_DIR)" "$(basename $NGINX_CONFIG_DIR)"; then
        log_success "Backup de configuraciones creado: $backup_file"
        
        # Crear checksum
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $backup_name.tar.gz" > "$BACKUP_DIR/$backup_name.sha256"
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_info "Tamaño del backup: $backup_size"
        
    else
        log_error "Error al crear backup de configuraciones"
        return 1
    fi
}

# Crear backup de sitios web
create_sites_backup() {
    log_step "Creando backup de sitios web..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="nginx_sites_backup_$timestamp"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    if [ ! -d "$WEB_ROOT" ]; then
        log_error "Directorio de sitios web no encontrado"
        return 1
    fi
    
    # Crear backup de sitios web
    if tar -czf "$backup_file" -C "$(dirname $WEB_ROOT)" "$(basename $WEB_ROOT)"; then
        log_success "Backup de sitios web creado: $backup_file"
        
        # Crear checksum
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $backup_name.tar.gz" > "$BACKUP_DIR/$backup_name.sha256"
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_info "Tamaño del backup: $backup_size"
        
    else
        log_error "Error al crear backup de sitios web"
        return 1
    fi
}

# Crear backup de certificados SSL
create_ssl_backup() {
    log_step "Creando backup de certificados SSL..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="nginx_ssl_backup_$timestamp"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    if [ ! -d "$SSL_DIR" ]; then
        log_warning "Directorio de certificados SSL no encontrado"
        return 1
    fi
    
    # Crear backup de certificados SSL
    if tar -czf "$backup_file" -C "$(dirname $SSL_DIR)" "$(basename $SSL_DIR)"; then
        log_success "Backup de certificados SSL creado: $backup_file"
        
        # Crear checksum
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $backup_name.tar.gz" > "$BACKUP_DIR/$backup_name.sha256"
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_info "Tamaño del backup: $backup_size"
        
    else
        log_error "Error al crear backup de certificados SSL"
        return 1
    fi
}

# Crear backup de logs
create_logs_backup() {
    log_step "Creando backup de logs..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="nginx_logs_backup_$timestamp"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    if [ ! -d "$LOG_DIR" ]; then
        log_error "Directorio de logs no encontrado"
        return 1
    fi
    
    # Crear backup de logs (solo los más recientes)
    local temp_dir="/tmp/nginx_logs_backup_$timestamp"
    mkdir -p "$temp_dir"
    
    # Copiar logs de los últimos 30 días
    find "$LOG_DIR" -name "*.log*" -mtime -30 -exec cp {} "$temp_dir/" \;
    
    if tar -czf "$backup_file" -C "$temp_dir" .; then
        log_success "Backup de logs creado: $backup_file"
        
        # Crear checksum
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $backup_name.tar.gz" > "$BACKUP_DIR/$backup_name.sha256"
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_info "Tamaño del backup: $backup_size"
        
    else
        log_error "Error al crear backup de logs"
        return 1
    fi
    
    # Limpiar directorio temporal
    rm -rf "$temp_dir"
}

# Listar backups disponibles
list_backups() {
    log_step "Listando backups disponibles..."
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        log_warning "No hay backups disponibles"
        return 1
    fi
    
    echo -e "${WHITE}📋 Backups Disponibles:${NC}"
    echo
    
    local backup_count=0
    for backup_file in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup_file" ]; then
            backup_count=$((backup_count + 1))
            local backup_name=$(basename "$backup_file" .tar.gz)
            local backup_size=$(du -h "$backup_file" | cut -f1)
            local backup_date=$(stat -c %y "$backup_file" | cut -d' ' -f1,2 | cut -d'.' -f1)
            
            # Determinar tipo de backup
            local backup_type=""
            if [[ "$backup_name" == *"full"* ]]; then
                backup_type="Completo"
            elif [[ "$backup_name" == *"config"* ]]; then
                backup_type="Configuraciones"
            elif [[ "$backup_name" == *"sites"* ]]; then
                backup_type="Sitios Web"
            elif [[ "$backup_name" == *"ssl"* ]]; then
                backup_type="Certificados SSL"
            elif [[ "$backup_name" == *"logs"* ]]; then
                backup_type="Logs"
            else
                backup_type="Desconocido"
            fi
            
            echo -e "   ${YELLOW}$backup_count.${NC} $backup_name"
            echo -e "      ${CYAN}Tipo:${NC} $backup_type"
            echo -e "      ${CYAN}Tamaño:${NC} $backup_size"
            echo -e "      ${CYAN}Fecha:${NC} $backup_date"
            
            # Verificar si existe checksum
            if [ -f "$BACKUP_DIR/$backup_name.sha256" ]; then
                echo -e "      ${CYAN}Checksum:${NC} ${GREEN}✓${NC}"
            else
                echo -e "      ${CYAN}Checksum:${NC} ${RED}✗${NC}"
            fi
            
            echo
        fi
    done
    
    if [ "$backup_count" -eq 0 ]; then
        log_warning "No se encontraron archivos de backup válidos"
    else
        log_info "Total de backups: $backup_count"
        local total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
        log_info "Espacio total usado: $total_size"
    fi
}

# Restaurar backup
restore_backup() {
    log_step "Restaurando backup..."
    
    # Listar backups disponibles
    list_backups
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        log_error "No hay backups disponibles para restaurar"
        return 1
    fi
    
    echo -e "${WHITE}Selecciona el backup a restaurar:${NC}"
    local backups=()
    for backup_file in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup_file" ]; then
            backups+=("$(basename "$backup_file")")
            echo -e "   ${YELLOW}${#backups[@]}.${NC} $(basename "$backup_file")"
        fi
    done
    
    read -p "Selecciona el backup (número o nombre): " choice
    
    local selected_backup=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
        selected_backup="${backups[$((choice-1))]}"
    else
        selected_backup="$choice"
        if [[ ! "$selected_backup" == *.tar.gz ]]; then
            selected_backup="$selected_backup.tar.gz"
        fi
    fi
    
    local backup_path="$BACKUP_DIR/$selected_backup"
    
    if [ ! -f "$backup_path" ]; then
        log_error "Backup no encontrado: $selected_backup"
        return 1
    fi
    
    # Verificar integridad si existe checksum
    local checksum_file="$BACKUP_DIR/$(basename "$selected_backup" .tar.gz).sha256"
    if [ -f "$checksum_file" ]; then
        log_info "Verificando integridad del backup..."
        if cd "$BACKUP_DIR" && sha256sum -c "$(basename "$checksum_file")" &>/dev/null; then
            log_success "Integridad del backup verificada"
        else
            log_error "Error de integridad en el backup"
            read -p "¿Continuar con la restauración? (y/N): " continue_restore
            if [[ ! $continue_restore =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    fi
    
    # Confirmación de restauración
    log_warning "¿Estás seguro de que quieres restaurar este backup?"
    log_warning "Esto sobrescribirá la configuración actual"
    
    read -p "Escribe 'RESTAURAR' para confirmar: " confirm
    
    if [ "$confirm" != "RESTAURAR" ]; then
        log_info "Restauración cancelada"
        return 1
    fi
    
    # Crear backup de la configuración actual antes de restaurar
    log_info "Creando backup de seguridad de la configuración actual..."
    local safety_backup="$BACKUP_DIR/safety_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$safety_backup" -C / etc/nginx var/www 2>/dev/null || true
    
    # Restaurar backup
    log_info "Restaurando backup..."
    local temp_restore_dir="/tmp/nginx_restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$temp_restore_dir"
    
    if tar -xzf "$backup_path" -C "$temp_restore_dir"; then
        log_success "Backup extraído exitosamente"
        
        # Restaurar según el tipo de backup
        if [ -d "$temp_restore_dir/nginx_config" ]; then
            log_info "Restaurando configuraciones de nginx..."
            cp -r "$temp_restore_dir/nginx_config"/* "$NGINX_CONFIG_DIR/"
        fi
        
        if [ -d "$temp_restore_dir/web_root" ]; then
            log_info "Restaurando sitios web..."
            cp -r "$temp_restore_dir/web_root"/* "$WEB_ROOT/"
        fi
        
        if [ -d "$temp_restore_dir/ssl_certs" ]; then
            log_info "Restaurando certificados SSL..."
            cp -r "$temp_restore_dir/ssl_certs"/* "$SSL_DIR/"
        fi
        
        # Verificar configuración de nginx
        if nginx -t &>/dev/null; then
            log_success "Configuración de nginx válida"
            systemctl reload nginx
            log_success "Nginx recargado exitosamente"
        else
            log_error "Error en la configuración de nginx después de la restauración"
            log_warning "Revisa la configuración manualmente"
        fi
        
        log_success "Backup restaurado exitosamente"
        log_info "Backup de seguridad creado en: $safety_backup"
        
    else
        log_error "Error al extraer el backup"
        return 1
    fi
    
    # Limpiar directorio temporal
    rm -rf "$temp_restore_dir"
}

# Eliminar backup
delete_backup() {
    log_step "Eliminando backup..."
    
    # Listar backups disponibles
    list_backups
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        log_error "No hay backups disponibles para eliminar"
        return 1
    fi
    
    echo -e "${WHITE}Selecciona el backup a eliminar:${NC}"
    local backups=()
    for backup_file in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup_file" ]; then
            backups+=("$(basename "$backup_file")")
            echo -e "   ${YELLOW}${#backups[@]}.${NC} $(basename "$backup_file")"
        fi
    done
    
    read -p "Selecciona el backup (número o nombre): " choice
    
    local selected_backup=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
        selected_backup="${backups[$((choice-1))]}"
    else
        selected_backup="$choice"
        if [[ ! "$selected_backup" == *.tar.gz ]]; then
            selected_backup="$selected_backup.tar.gz"
        fi
    fi
    
    local backup_path="$BACKUP_DIR/$selected_backup"
    
    if [ ! -f "$backup_path" ]; then
        log_error "Backup no encontrado: $selected_backup"
        return 1
    fi
    
    # Confirmación
    log_warning "¿Estás seguro de que quieres eliminar este backup?"
    log_warning "Archivo: $selected_backup"
    
    read -p "Escribe 'ELIMINAR' para confirmar: " confirm
    
    if [ "$confirm" != "ELIMINAR" ]; then
        log_info "Eliminación cancelada"
        return 1
    fi
    
    # Eliminar backup y su checksum
    rm -f "$backup_path"
    rm -f "$BACKUP_DIR/$(basename "$selected_backup" .tar.gz).sha256"
    
    log_success "Backup eliminado exitosamente"
}

# Verificar integridad de backup
verify_backup() {
    log_step "Verificando integridad de backup..."
    
    # Listar backups disponibles
    list_backups
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        log_error "No hay backups disponibles para verificar"
        return 1
    fi
    
    echo -e "${WHITE}Selecciona el backup a verificar:${NC}"
    local backups=()
    for backup_file in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup_file" ]; then
            backups+=("$(basename "$backup_file")")
            echo -e "   ${YELLOW}${#backups[@]}.${NC} $(basename "$backup_file")"
        fi
    done
    
    read -p "Selecciona el backup (número o nombre): " choice
    
    local selected_backup=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
        selected_backup="${backups[$((choice-1))]}"
    else
        selected_backup="$choice"
        if [[ ! "$selected_backup" == *.tar.gz ]]; then
            selected_backup="$selected_backup.tar.gz"
        fi
    fi
    
    local backup_path="$BACKUP_DIR/$selected_backup"
    local checksum_file="$BACKUP_DIR/$(basename "$selected_backup" .tar.gz).sha256"
    
    if [ ! -f "$backup_path" ]; then
        log_error "Backup no encontrado: $selected_backup"
        return 1
    fi
    
    # Verificar integridad con checksum
    if [ -f "$checksum_file" ]; then
        log_info "Verificando checksum..."
        if cd "$BACKUP_DIR" && sha256sum -c "$(basename "$checksum_file")"; then
            log_success "Integridad del backup verificada correctamente"
        else
            log_error "Error de integridad en el backup"
            return 1
        fi
    else
        log_warning "No existe archivo de checksum para este backup"
        log_info "Creando checksum..."
        local checksum=$(sha256sum "$backup_path" | cut -d' ' -f1)
        echo "$checksum  $selected_backup" > "$checksum_file"
        log_success "Checksum creado: $(basename "$checksum_file")"
    fi
    
    # Verificar que el archivo tar es válido
    log_info "Verificando archivo tar..."
    if tar -tzf "$backup_path" &>/dev/null; then
        log_success "Archivo tar válido"
    else
        log_error "Archivo tar corrupto o inválido"
        return 1
    fi
    
    # Mostrar información del backup
    log_info "Información del backup:"
    echo -e "   ${CYAN}Archivo:${NC} $selected_backup"
    echo -e "   ${CYAN}Tamaño:${NC} $(du -h "$backup_path" | cut -f1)"
    echo -e "   ${CYAN}Fecha:${NC} $(stat -c %y "$backup_path" | cut -d'.' -f1)"
    echo -e "   ${CYAN}Archivos:${NC} $(tar -tzf "$backup_path" | wc -l)"
}

# Configurar backup automático
setup_auto_backup() {
    log_step "Configurando backup automático..."
    
    # Crear script de backup automático
    cat > /opt/nginx-server/auto-backup.sh << 'EOF'
#!/bin/bash
# Script de backup automático para nginx-server

# Configuración
BACKUP_DIR="/opt/nginx-server/backups"
MAX_BACKUPS=7  # Mantener solo los últimos 7 backups
LOG_FILE="/var/log/nginx/backup.log"

# Función de logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Iniciar backup
log_message "Iniciando backup automático"

# Crear backup completo
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_name="nginx_auto_backup_$timestamp"
backup_file="$BACKUP_DIR/$backup_name.tar.gz"

# Crear backup
if tar -czf "$backup_file" -C / etc/nginx var/www etc/letsencrypt 2>/dev/null; then
    log_message "Backup creado exitosamente: $backup_name.tar.gz"
    
    # Crear checksum
    checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
    echo "$checksum  $backup_name.tar.gz" > "$BACKUP_DIR/$backup_name.sha256"
    log_message "Checksum creado: $backup_name.sha256"
    
    # Limpiar backups antiguos
    cd "$BACKUP_DIR"
    ls -t nginx_auto_backup_*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f
    ls -t nginx_auto_backup_*.sha256 | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f
    
    log_message "Backup automático completado exitosamente"
else
    log_message "Error al crear backup automático"
fi
EOF
    
    chmod +x /opt/nginx-server/auto-backup.sh
    
    # Configurar cron job
    echo -e "${WHITE}Configuración de backup automático:${NC}"
    echo -e "   ${YELLOW}1.${NC} Diario (1:00 AM)"
    echo -e "   ${YELLOW}2.${NC} Semanal (Domingo 2:00 AM)"
    echo -e "   ${YELLOW}3.${NC} Personalizado"
    
    read -p "Selecciona la frecuencia: " frequency
    
    case $frequency in
        1)
            cron_schedule="0 1 * * *"
            schedule_desc="Diario a la 1:00 AM"
            ;;
        2)
            cron_schedule="0 2 * * 0"
            schedule_desc="Semanal (Domingo 2:00 AM)"
            ;;
        3)
            echo -e "${WHITE}Formato cron: minuto hora día mes día_semana${NC}"
            echo -e "Ejemplo: 0 3 * * * (todos los días a las 3:00 AM)"
            read -p "Ingresa el schedule cron: " cron_schedule
            schedule_desc="Personalizado: $cron_schedule"
            ;;
        *)
            log_error "Opción inválida"
            return 1
            ;;
    esac
    
    # Agregar a crontab
    (crontab -l 2>/dev/null | grep -v "nginx-server/auto-backup.sh"; echo "$cron_schedule /opt/nginx-server/auto-backup.sh") | crontab -
    
    log_success "Backup automático configurado"
    log_info "Frecuencia: $schedule_desc"
    log_info "Script: /opt/nginx-server/auto-backup.sh"
    log_info "Logs: /var/log/nginx/backup.log"
}

# Ver estado de backup automático
check_auto_backup() {
    log_step "Verificando estado de backup automático..."
    
    # Verificar si existe el script
    if [ -f "/opt/nginx-server/auto-backup.sh" ]; then
        log_success "Script de backup automático encontrado"
        
        # Verificar cron job
        if crontab -l 2>/dev/null | grep -q "auto-backup.sh"; then
            log_success "Cron job configurado"
            
            echo -e "${WHITE}Configuración actual:${NC}"
            crontab -l | grep "auto-backup.sh"
            
            # Verificar logs
            if [ -f "/var/log/nginx/backup.log" ]; then
                echo -e "${WHITE}Últimas ejecuciones:${NC}"
                tail -10 /var/log/nginx/backup.log
            else
                log_info "No hay logs de backup disponibles aún"
            fi
            
        else
            log_warning "Cron job no configurado"
            read -p "¿Quieres configurar el backup automático? (Y/n): " setup
            
            if [[ ! $setup =~ ^[Nn]$ ]]; then
                setup_auto_backup
            fi
        fi
        
    else
        log_warning "Script de backup automático no encontrado"
        read -p "¿Quieres configurar el backup automático? (Y/n): " setup
        
        if [[ ! $setup =~ ^[Nn]$ ]]; then
            setup_auto_backup
        fi
    fi
}

# Función principal
main() {
    # Verificaciones iniciales
    check_root
    create_backup_dir
    
    # Si se pasa un argumento, ejecutar comando directamente
    if [ $# -gt 0 ]; then
        case $1 in
            "full")
                create_full_backup
                ;;
            "config")
                create_config_backup
                ;;
            "sites")
                create_sites_backup
                ;;
            "ssl")
                create_ssl_backup
                ;;
            "logs")
                create_logs_backup
                ;;
            "list")
                list_backups
                ;;
            "restore")
                restore_backup
                ;;
            *)
                log_error "Comando desconocido: $1"
                echo "Comandos disponibles: full, config, sites, ssl, logs, list, restore"
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
                create_full_backup
                ;;
            2)
                create_config_backup
                ;;
            3)
                create_sites_backup
                ;;
            4)
                create_ssl_backup
                ;;
            5)
                create_logs_backup
                ;;
            6)
                list_backups
                ;;
            7)
                restore_backup
                ;;
            8)
                delete_backup
                ;;
            9)
                setup_auto_backup
                ;;
            10)
                check_auto_backup
                ;;
            11)
                verify_backup
                ;;
            12)
                echo "Función de exportación no implementada aún"
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