#!/bin/bash

# 🛠️ Gestor de Samba - Herramienta de administración completa
# Desarrollado por MondoBoricua para la comunidad de Proxmox
# Versión: 1.0

set -e  # Salir si hay algún error

# Colores pa' que se vea chévere
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                🛠️  GESTOR DE SAMBA LXC                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

# Verificar que el script se ejecute como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Verificar que Samba esté instalado
check_samba() {
    if ! command -v smbpasswd &> /dev/null; then
        print_error "Samba no está instalado en este sistema"
        exit 1
    fi
}

show_menu() {
    clear
    print_header
    echo -e "${CYAN}Selecciona una opción:${NC}"
    echo
    echo -e " ${GREEN}👥 GESTIÓN DE USUARIOS${NC}"
    echo "  1. Listar usuarios de Samba"
    echo "  2. Agregar nuevo usuario"
    echo "  3. Cambiar contraseña de usuario"
    echo "  4. Habilitar/Deshabilitar usuario"
    echo "  5. Eliminar usuario"
    echo
    echo -e " ${GREEN}📂 GESTIÓN DE RECURSOS COMPARTIDOS${NC}"
    echo "  6. Mostrar recursos compartidos"
    echo "  7. Agregar nuevo recurso compartido"
    echo "  8. Modificar permisos de recurso"
    echo "  9. Eliminar recurso compartido"
    echo
    echo -e " ${GREEN}🔧 ADMINISTRACIÓN DEL SISTEMA${NC}"
    echo " 10. Ver conexiones activas"
    echo " 11. Verificar configuración"
    echo " 12. Reiniciar servicios"
    echo " 13. Ver logs del sistema"
    echo " 14. Backup de configuración"
    echo " 15. Restaurar configuración"
    echo
    echo -e " ${GREEN}📊 INFORMACIÓN Y MONITOREO${NC}"
    echo " 16. Estado de servicios"
    echo " 17. Estadísticas de uso"
    echo " 18. Información del servidor"
    echo
    echo " 19. Configuración avanzada"
    echo "  0. Salir"
    echo
    read -p "Selecciona una opción (0-19): " choice
}

# === FUNCIONES DE GESTIÓN DE USUARIOS ===

list_users() {
    print_header
    echo -e "${CYAN}👥 USUARIOS DE SAMBA${NC}"
    echo
    
    if ! command -v pdbedit &> /dev/null; then
        print_error "Comando pdbedit no disponible"
        return
    fi
    
    users=$(pdbedit -L 2>/dev/null || echo "")
    
    if [ -n "$users" ]; then
        echo -e "${GREEN}Usuarios configurados:${NC}"
        echo "════════════════════════════════════════"
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                username=$(echo "$line" | cut -d: -f1)
                uid=$(echo "$line" | cut -d: -f2)
                
                # Verificar si el usuario está habilitado
                if pdbedit -L -v "$username" 2>/dev/null | grep -q "Account Flags.*\[U"; then
                    status="${GREEN}✅ Activo${NC}"
                else
                    status="${RED}❌ Deshabilitado${NC}"
                fi
                
                echo -e "👤 ${GREEN}$username${NC} (UID: $uid) - Estado: $status"
                
                # Mostrar grupos del usuario
                groups=$(groups "$username" 2>/dev/null | cut -d: -f2 | sed 's/^ *//' || echo "N/A")
                echo -e "   Grupos: $groups"
                
                # Mostrar directorio home si existe
                if [ -d "/srv/samba/users/$username" ]; then
                    echo -e "   Directorio: ${GREEN}/srv/samba/users/$username${NC}"
                fi
                echo
            fi
        done <<< "$users"
    else
        print_warning "No hay usuarios de Samba configurados"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

add_user() {
    print_header
    echo -e "${CYAN}➕ AGREGAR NUEVO USUARIO${NC}"
    echo
    
    read -p "Nombre del nuevo usuario: " username
    if [ -z "$username" ]; then
        print_error "El nombre de usuario no puede estar vacío"
        return
    fi
    
    # Verificar si el usuario ya existe en Samba
    if pdbedit -L | grep -q "^$username:"; then
        print_error "El usuario $username ya existe en Samba"
        return
    fi
    
    # Verificar si el usuario existe en el sistema
    if ! id "$username" &>/dev/null; then
        print_message "Creando usuario del sistema..."
        
        read -p "¿Crear directorio home? (s/n) [s]: " create_home
        create_home=${create_home:-s}
        
        if [[ $create_home == "s" || $create_home == "S" ]]; then
            useradd -m -s /bin/bash -G sambashare "$username"
        else
            useradd -M -s /bin/bash -G sambashare "$username"
        fi
        
        print_success "Usuario del sistema creado"
    else
        # Agregar al grupo sambashare si no está
        usermod -a -G sambashare "$username"
        print_message "Usuario agregado al grupo sambashare"
    fi
    
    # Crear directorio personal en Samba
    read -p "¿Crear directorio personal en Samba? (s/n) [s]: " create_samba_dir
    create_samba_dir=${create_samba_dir:-s}
    
    if [[ $create_samba_dir == "s" || $create_samba_dir == "S" ]]; then
        mkdir -p "/srv/samba/users/$username"
        chown "$username:sambashare" "/srv/samba/users/$username"
        chmod 755 "/srv/samba/users/$username"
        print_success "Directorio personal creado: /srv/samba/users/$username"
    fi
    
    # Agregar a Samba y establecer contraseña
    print_message "Configurando usuario en Samba..."
    if smbpasswd -a "$username"; then
        smbpasswd -e "$username"
        print_success "Usuario $username agregado exitosamente a Samba"
        
        # Agregar recurso compartido personal si se creó el directorio
        if [[ $create_samba_dir == "s" || $create_samba_dir == "S" ]]; then
            read -p "¿Agregar recurso compartido personal? (s/n) [s]: " add_share
            add_share=${add_share:-s}
            
            if [[ $add_share == "s" || $add_share == "S" ]]; then
                add_user_share "$username"
            fi
        fi
    else
        print_error "Error al agregar usuario a Samba"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

change_password() {
    print_header
    echo -e "${CYAN}🔑 CAMBIAR CONTRASEÑA DE USUARIO${NC}"
    echo
    
    # Mostrar usuarios disponibles
    echo -e "${GREEN}Usuarios disponibles:${NC}"
    pdbedit -L 2>/dev/null | cut -d: -f1 | while read user; do
        echo "  - $user"
    done
    echo
    
    read -p "Usuario para cambiar contraseña: " username
    if [ -z "$username" ]; then
        print_error "Debes especificar un usuario"
        return
    fi
    
    if pdbedit -L | grep -q "^$username:"; then
        print_message "Cambiando contraseña para $username..."
        if smbpasswd "$username"; then
            print_success "Contraseña cambiada exitosamente"
        else
            print_error "Error al cambiar la contraseña"
        fi
    else
        print_error "Usuario $username no encontrado en Samba"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

toggle_user() {
    print_header
    echo -e "${CYAN}🔄 HABILITAR/DESHABILITAR USUARIO${NC}"
    echo
    
    # Mostrar usuarios con su estado
    echo -e "${GREEN}Usuarios disponibles:${NC}"
    pdbedit -L 2>/dev/null | while IFS=: read username uid; do
        if pdbedit -L -v "$username" 2>/dev/null | grep -q "Account Flags.*\[U"; then
            echo -e "  - $username ${GREEN}(Activo)${NC}"
        else
            echo -e "  - $username ${RED}(Deshabilitado)${NC}"
        fi
    done
    echo
    
    read -p "Usuario a habilitar/deshabilitar: " username
    if [ -z "$username" ]; then
        print_error "Debes especificar un usuario"
        return
    fi
    
    if pdbedit -L | grep -q "^$username:"; then
        # Verificar estado actual
        if pdbedit -L -v "$username" 2>/dev/null | grep -q "Account Flags.*\[U"; then
            # Usuario está activo, deshabilitar
            if smbpasswd -d "$username"; then
                print_success "Usuario $username deshabilitado"
            else
                print_error "Error al deshabilitar usuario"
            fi
        else
            # Usuario está deshabilitado, habilitar
            if smbpasswd -e "$username"; then
                print_success "Usuario $username habilitado"
            else
                print_error "Error al habilitar usuario"
            fi
        fi
    else
        print_error "Usuario $username no encontrado"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

remove_user() {
    print_header
    echo -e "${CYAN}🗑️  ELIMINAR USUARIO${NC}"
    echo
    
    # Mostrar usuarios disponibles
    echo -e "${GREEN}Usuarios disponibles:${NC}"
    pdbedit -L 2>/dev/null | cut -d: -f1 | while read user; do
        echo "  - $user"
    done
    echo
    
    read -p "Usuario a eliminar: " username
    if [ -z "$username" ]; then
        print_error "Debes especificar un usuario"
        return
    fi
    
    if ! pdbedit -L | grep -q "^$username:"; then
        print_error "Usuario $username no encontrado en Samba"
        return
    fi
    
    echo -e "${RED}⚠️  ADVERTENCIA:${NC} Esta acción eliminará:"
    echo "  - Usuario de Samba"
    echo "  - Opcionalmente: usuario del sistema"
    echo "  - Opcionalmente: directorio personal"
    echo
    
    read -p "¿Estás seguro? (escribe 'ELIMINAR' para confirmar): " confirm
    if [[ "$confirm" != "ELIMINAR" ]]; then
        print_message "Operación cancelada"
        return
    fi
    
    # Eliminar de Samba
    if smbpasswd -x "$username" 2>/dev/null; then
        print_success "Usuario eliminado de Samba"
    else
        print_warning "Error al eliminar usuario de Samba (puede que no existiera)"
    fi
    
    # Preguntar si eliminar del sistema
    read -p "¿Eliminar usuario del sistema también? (s/n) [n]: " remove_system
    remove_system=${remove_system:-n}
    
    if [[ $remove_system == "s" || $remove_system == "S" ]]; then
        if userdel "$username" 2>/dev/null; then
            print_success "Usuario eliminado del sistema"
        else
            print_warning "Error al eliminar usuario del sistema"
        fi
    fi
    
    # Preguntar si eliminar directorio personal
    if [ -d "/srv/samba/users/$username" ]; then
        read -p "¿Eliminar directorio personal /srv/samba/users/$username? (s/n) [n]: " remove_dir
        remove_dir=${remove_dir:-n}
        
        if [[ $remove_dir == "s" || $remove_dir == "S" ]]; then
            rm -rf "/srv/samba/users/$username"
            print_success "Directorio personal eliminado"
        fi
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

# === FUNCIONES DE GESTIÓN DE RECURSOS COMPARTIDOS ===

show_shares() {
    print_header
    echo -e "${CYAN}📂 RECURSOS COMPARTIDOS${NC}"
    echo
    
    if ! command -v smbclient &> /dev/null; then
        print_error "Comando smbclient no disponible"
        return
    fi
    
    echo -e "${GREEN}Recursos compartidos activos:${NC}"
    echo "════════════════════════════════════════"
    
    # Obtener lista de compartidos
    shares=$(smbclient -L localhost -N 2>/dev/null | grep -E "^\s*[A-Za-z]" | grep -v "IPC\|ADMIN" | awk '{print $1}' || echo "")
    
    if [ -n "$shares" ]; then
        while IFS= read -r share; do
            if [ -n "$share" ]; then
                echo -e "📁 ${GREEN}$share${NC}"
                
                # Obtener información del smb.conf
                if [ -f /etc/samba/smb.conf ]; then
                    path=$(grep -A 10 "^\[$share\]" /etc/samba/smb.conf | grep "path" | head -1 | awk -F= '{print $2}' | sed 's/^ *//' || echo "")
                    comment=$(grep -A 10 "^\[$share\]" /etc/samba/smb.conf | grep "comment" | head -1 | awk -F= '{print $2}' | sed 's/^ *//' || echo "")
                    writable=$(grep -A 10 "^\[$share\]" /etc/samba/smb.conf | grep "writable\|read only" | head -1 | awk -F= '{print $2}' | sed 's/^ *//' || echo "")
                    guest_ok=$(grep -A 10 "^\[$share\]" /etc/samba/smb.conf | grep "guest ok" | head -1 | awk -F= '{print $2}' | sed 's/^ *//' || echo "")
                    
                    [ -n "$comment" ] && echo -e "   Descripción: $comment"
                    [ -n "$path" ] && echo -e "   Ruta: $path"
                    
                    if [ -n "$path" ] && [ -d "$path" ]; then
                        size=$(du -sh "$path" 2>/dev/null | awk '{print $1}' || echo "N/A")
                        echo -e "   Tamaño: $size"
                        
                        # Verificar permisos
                        perms=$(ls -ld "$path" 2>/dev/null | awk '{print $1}' || echo "N/A")
                        owner=$(ls -ld "$path" 2>/dev/null | awk '{print $3":"$4}' || echo "N/A")
                        echo -e "   Permisos: $perms ($owner)"
                    fi
                    
                    # Mostrar configuración de acceso
                    if [[ "$guest_ok" == "yes" ]]; then
                        echo -e "   Acceso: ${GREEN}Público (sin autenticación)${NC}"
                    else
                        echo -e "   Acceso: ${YELLOW}Autenticado${NC}"
                    fi
                    
                    if [[ "$writable" == "yes" ]] || [[ "$writable" == *"no"* ]]; then
                        if [[ "$writable" == "yes" ]]; then
                            echo -e "   Permisos: ${GREEN}Lectura/Escritura${NC}"
                        else
                            echo -e "   Permisos: ${YELLOW}Solo lectura${NC}"
                        fi
                    fi
                fi
                echo
            fi
        done <<< "$shares"
    else
        print_warning "No hay recursos compartidos configurados"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

add_share() {
    print_header
    echo -e "${CYAN}➕ AGREGAR NUEVO RECURSO COMPARTIDO${NC}"
    echo
    
    read -p "Nombre del recurso compartido: " share_name
    if [ -z "$share_name" ]; then
        print_error "El nombre no puede estar vacío"
        return
    fi
    
    # Verificar si ya existe
    if grep -q "^\[$share_name\]" /etc/samba/smb.conf 2>/dev/null; then
        print_error "El recurso compartido '$share_name' ya existe"
        return
    fi
    
    read -p "Ruta del directorio [/srv/samba/$share_name]: " share_path
    share_path=${share_path:-/srv/samba/$share_name}
    
    read -p "Descripción del recurso: " share_comment
    share_comment=${share_comment:-"Recurso compartido $share_name"}
    
    # Crear directorio si no existe
    if [ ! -d "$share_path" ]; then
        read -p "El directorio no existe. ¿Crearlo? (s/n) [s]: " create_dir
        create_dir=${create_dir:-s}
        
        if [[ $create_dir == "s" || $create_dir == "S" ]]; then
            mkdir -p "$share_path"
            print_success "Directorio creado: $share_path"
        else
            print_error "No se puede crear el recurso sin directorio"
            return
        fi
    fi
    
    # Configurar permisos
    echo
    echo "Configuración de acceso:"
    echo "1. Público (sin autenticación)"
    echo "2. Solo usuarios autenticados"
    echo "3. Usuarios específicos"
    read -p "Selecciona tipo de acceso (1-3) [2]: " access_type
    access_type=${access_type:-2}
    
    echo
    echo "Permisos de escritura:"
    echo "1. Solo lectura"
    echo "2. Lectura y escritura"
    read -p "Selecciona permisos (1-2) [2]: " write_perms
    write_perms=${write_perms:-2}
    
    # Configurar propietario y permisos del directorio
    case $access_type in
        1)
            chown nobody:nogroup "$share_path"
            chmod 777 "$share_path"
            ;;
        2|3)
            chown root:sambashare "$share_path"
            if [ "$write_perms" == "2" ]; then
                chmod 775 "$share_path"
            else
                chmod 755 "$share_path"
            fi
            ;;
    esac
    
    # Agregar configuración al smb.conf
    echo >> /etc/samba/smb.conf
    echo "[$share_name]" >> /etc/samba/smb.conf
    echo "    comment = $share_comment" >> /etc/samba/smb.conf
    echo "    path = $share_path" >> /etc/samba/smb.conf
    echo "    browsable = yes" >> /etc/samba/smb.conf
    
    case $access_type in
        1)
            echo "    guest ok = yes" >> /etc/samba/smb.conf
            echo "    public = yes" >> /etc/samba/smb.conf
            ;;
        2)
            echo "    guest ok = no" >> /etc/samba/smb.conf
            echo "    valid users = @sambashare" >> /etc/samba/smb.conf
            ;;
        3)
            echo "    guest ok = no" >> /etc/samba/smb.conf
            read -p "Usuarios permitidos (separados por coma): " valid_users
            echo "    valid users = $valid_users" >> /etc/samba/smb.conf
            ;;
    esac
    
    if [ "$write_perms" == "2" ]; then
        echo "    writable = yes" >> /etc/samba/smb.conf
        echo "    read only = no" >> /etc/samba/smb.conf
    else
        echo "    writable = no" >> /etc/samba/smb.conf
        echo "    read only = yes" >> /etc/samba/smb.conf
    fi
    
    # Agregar máscaras de archivos
    if [ "$access_type" == "1" ]; then
        echo "    create mask = 0666" >> /etc/samba/smb.conf
        echo "    directory mask = 0777" >> /etc/samba/smb.conf
    else
        echo "    create mask = 0664" >> /etc/samba/smb.conf
        echo "    directory mask = 0775" >> /etc/samba/smb.conf
        echo "    force group = sambashare" >> /etc/samba/smb.conf
    fi
    
    # Verificar configuración
    if testparm -s > /dev/null 2>&1; then
        print_success "Configuración válida"
        
        # Reiniciar Samba
        if systemctl reload smbd; then
            print_success "Recurso compartido '$share_name' creado exitosamente"
            echo -e "Acceso: ${GREEN}\\\\$(hostname -I | awk '{print $1}')\\$share_name${NC}"
        else
            print_error "Error al recargar Samba"
        fi
    else
        print_error "Error en la configuración de Samba"
        echo "Ejecuta 'testparm' para ver los errores"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

# === FUNCIONES DE ADMINISTRACIÓN ===

show_connections() {
    print_header
    echo -e "${CYAN}🔗 CONEXIONES ACTIVAS${NC}"
    echo
    
    if ! command -v smbstatus &> /dev/null; then
        print_error "Comando smbstatus no disponible"
        return
    fi
    
    echo -e "${GREEN}Conexiones por usuario:${NC}"
    smbstatus -b 2>/dev/null || echo "No hay conexiones activas"
    
    echo
    echo -e "${GREEN}Archivos abiertos:${NC}"
    smbstatus -L 2>/dev/null || echo "No hay archivos abiertos"
    
    echo
    echo -e "${GREEN}Bloqueos activos:${NC}"
    smbstatus -l 2>/dev/null || echo "No hay bloqueos activos"
    
    echo
    read -p "Presiona Enter para continuar..."
}

verify_config() {
    print_header
    echo -e "${CYAN}🔍 VERIFICACIÓN DE CONFIGURACIÓN${NC}"
    echo
    
    echo -e "${GREEN}Verificando sintaxis de smb.conf:${NC}"
    if testparm -s; then
        print_success "Configuración válida"
    else
        print_error "Errores encontrados en la configuración"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

restart_services() {
    print_header
    echo -e "${CYAN}🔄 REINICIAR SERVICIOS DE SAMBA${NC}"
    echo
    
    print_message "Reiniciando servicios de Samba..."
    
    if systemctl restart smbd nmbd; then
        print_success "Servicios reiniciados exitosamente"
        
        # Verificar estado
        echo
        echo -e "${GREEN}Estado de servicios:${NC}"
        systemctl status smbd --no-pager -l
        echo
        systemctl status nmbd --no-pager -l
    else
        print_error "Error al reiniciar los servicios"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

show_logs() {
    print_header
    echo -e "${CYAN}📝 LOGS DEL SISTEMA${NC}"
    echo
    
    echo "Selecciona qué logs ver:"
    echo "1. Logs de smbd (últimas 50 líneas)"
    echo "2. Logs de nmbd (últimas 50 líneas)"
    echo "3. Logs del sistema (journal)"
    echo "4. Logs en tiempo real (smbd)"
    echo "0. Volver"
    
    read -p "Opción: " log_choice
    
    case $log_choice in
        1)
            if [ -f /var/log/samba/log.smbd ]; then
                echo -e "${GREEN}Últimas 50 líneas de smbd:${NC}"
                tail -50 /var/log/samba/log.smbd
            else
                print_warning "Archivo de log no encontrado"
            fi
            ;;
        2)
            if [ -f /var/log/samba/log.nmbd ]; then
                echo -e "${GREEN}Últimas 50 líneas de nmbd:${NC}"
                tail -50 /var/log/samba/log.nmbd
            else
                print_warning "Archivo de log no encontrado"
            fi
            ;;
        3)
            echo -e "${GREEN}Logs del sistema (últimas 50 líneas):${NC}"
            journalctl -u smbd -u nmbd --no-pager -n 50
            ;;
        4)
            echo -e "${GREEN}Logs en tiempo real (Ctrl+C para salir):${NC}"
            echo "Presiona Ctrl+C para volver al menú"
            tail -f /var/log/samba/log.smbd 2>/dev/null || journalctl -u smbd -f
            ;;
        0)
            return
            ;;
        *)
            print_error "Opción inválida"
            ;;
    esac
    
    echo
    read -p "Presiona Enter para continuar..."
}

backup_config() {
    print_header
    echo -e "${CYAN}💾 BACKUP DE CONFIGURACIÓN${NC}"
    echo
    
    BACKUP_DIR="/opt/samba/backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="samba_backup_$DATE.tar.gz"
    
    # Crear directorio de backups si no existe
    mkdir -p "$BACKUP_DIR"
    
    print_message "Creando backup de configuración..."
    
    # Crear backup
    if tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
        /etc/samba/ \
        /srv/samba/ \
        /opt/samba/ \
        --exclude="$BACKUP_DIR" 2>/dev/null; then
        
        print_success "Backup creado exitosamente: $BACKUP_DIR/$BACKUP_FILE"
        
        # Mostrar tamaño del backup
        size=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" | awk '{print $1}')
        echo -e "Tamaño del backup: ${GREEN}$size${NC}"
        
        # Mantener solo los últimos 10 backups
        cd "$BACKUP_DIR"
        ls -t samba_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm
        
        echo
        echo -e "${GREEN}Backups disponibles:${NC}"
        ls -lh samba_backup_*.tar.gz 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        print_error "Error al crear el backup"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

# === FUNCIÓN PRINCIPAL ===

main() {
    check_root
    check_samba
    
    while true; do
        show_menu
        case $choice in
            1) list_users ;;
            2) add_user ;;
            3) change_password ;;
            4) toggle_user ;;
            5) remove_user ;;
            6) show_shares ;;
            7) add_share ;;
            8) echo "Función en desarrollo..." && sleep 2 ;;
            9) echo "Función en desarrollo..." && sleep 2 ;;
            10) show_connections ;;
            11) verify_config ;;
            12) restart_services ;;
            13) show_logs ;;
            14) backup_config ;;
            15) echo "Función en desarrollo..." && sleep 2 ;;
            16) /opt/samba/welcome.sh --status 2>/dev/null || echo "Script de bienvenida no disponible" && sleep 3 ;;
            17) echo "Función en desarrollo..." && sleep 2 ;;
            18) /opt/samba/welcome.sh --quick 2>/dev/null || echo "Script de bienvenida no disponible" && sleep 3 ;;
            19) echo "Función en desarrollo..." && sleep 2 ;;
            0) 
                print_success "¡Gracias por usar el Gestor de Samba!"
                exit 0 
                ;;
            *) 
                print_error "Opción inválida"
                sleep 1
                ;;
        esac
    done
}

# Función auxiliar para agregar recurso compartido de usuario
add_user_share() {
    local username="$1"
    
    cat >> /etc/samba/smb.conf << EOF

[$username]
    comment = Directorio personal de $username
    path = /srv/samba/users/$username
    browsable = yes
    writable = yes
    guest ok = no
    read only = no
    valid users = $username
    create mask = 0644
    directory mask = 0755

EOF
    
    if systemctl reload smbd; then
        print_success "Recurso compartido personal agregado para $username"
    else
        print_warning "Error al recargar Samba"
    fi
}

# Verificar argumentos de línea de comandos
case "${1:-}" in
    add-user)
        check_root
        check_samba
        add_user
        ;;
    list-users)
        check_root
        check_samba
        list_users
        ;;
    change-password)
        check_root
        check_samba
        change_password
        ;;
    remove-user)
        check_root
        check_samba
        remove_user
        ;;
    add-share)
        check_root
        check_samba
        add_share
        ;;
    show-shares)
        check_samba
        show_shares
        ;;
    backup)
        check_root
        backup_config
        ;;
    --help|-h)
        echo "🛠️ Gestor de Samba - Herramienta de administración"
        echo "Uso: $0 [comando]"
        echo
        echo "Comandos disponibles:"
        echo "  add-user         Agregar nuevo usuario"
        echo "  list-users       Listar usuarios"
        echo "  change-password  Cambiar contraseña"
        echo "  remove-user      Eliminar usuario"
        echo "  add-share        Agregar recurso compartido"
        echo "  show-shares      Mostrar recursos compartidos"
        echo "  backup           Crear backup de configuración"
        echo "  --help, -h       Mostrar esta ayuda"
        echo
        echo "Sin argumentos: Modo interactivo (menú completo)"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 