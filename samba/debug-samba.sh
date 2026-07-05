#!/bin/bash

# 🔍 Script de Diagnóstico para Samba
# Desarrollado por MondoBoricua

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                🔍 DIAGNÓSTICO DE SAMBA                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_section() {
    echo -e "${CYAN}$1${NC}"
    echo "----------------------------------------"
}

check_system() {
    print_section "🖥️ INFORMACIÓN DEL SISTEMA"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'No disponible')"
    echo "Kernel: $(uname -r)"
    echo "Arquitectura: $(uname -m)"
    echo "Memoria: $(free -h | grep Mem | awk '{print $2}')"
    echo "Espacio en disco: $(df -h / | tail -1 | awk '{print $4}' | sed 's/G/ GB/')"
    echo
}

check_packages() {
    print_section "📦 ESTADO DE PAQUETES"
    
    packages=("samba" "samba-common-bin" "samba-client")
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            echo -e "✅ $package: ${GREEN}Instalado${NC}"
        else
            echo -e "❌ $package: ${RED}No instalado${NC}"
        fi
    done
    echo
}

check_services() {
    print_section "🔄 ESTADO DE SERVICIOS"
    
    services=("smbd" "nmbd")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "✅ $service: ${GREEN}Activo${NC}"
        else
            echo -e "❌ $service: ${RED}Inactivo${NC}"
        fi
        
        if systemctl is-enabled --quiet "$service"; then
            echo -e "   Habilitado: ${GREEN}Sí${NC}"
        else
            echo -e "   Habilitado: ${RED}No${NC}"
        fi
    done
    echo
}

check_directories() {
    print_section "📁 DIRECTORIOS Y PERMISOS"
    
    directories=("/srv/samba" "/srv/samba/public" "/srv/samba/private" "/opt/samba")
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            perms=$(ls -ld "$dir" | awk '{print $1, $3, $4}')
            echo -e "✅ $dir: ${GREEN}Existe${NC} ($perms)"
        else
            echo -e "❌ $dir: ${RED}No existe${NC}"
        fi
    done
    echo
}

check_config() {
    print_section "⚙️ CONFIGURACIÓN DE SAMBA"
    
    if [ -f /etc/samba/smb.conf ]; then
        echo -e "✅ smb.conf: ${GREEN}Existe${NC}"
        
        # Verificar configuración básica
        if grep -q "workgroup" /etc/samba/smb.conf; then
            workgroup=$(grep "workgroup" /etc/samba/smb.conf | head -1 | cut -d'=' -f2 | xargs)
            echo "   Grupo de trabajo: $workgroup"
        fi
        
        if grep -q "server string" /etc/samba/smb.conf; then
            server_string=$(grep "server string" /etc/samba/smb.conf | head -1 | cut -d'=' -f2 | xargs)
            echo "   Descripción: $server_string"
        fi
        
        # Verificar recursos compartidos
        echo "   Recursos compartidos:"
        grep "^\[" /etc/samba/smb.conf | grep -v "global" | sed 's/\[//g' | sed 's/\]//g' | while read share; do
            echo "     - $share"
        done
        
        # Verificar sintaxis
        if testparm -s /etc/samba/smb.conf >/dev/null 2>&1; then
            echo -e "   Sintaxis: ${GREEN}Válida${NC}"
        else
            echo -e "   Sintaxis: ${RED}Inválida${NC}"
        fi
    else
        echo -e "❌ smb.conf: ${RED}No existe${NC}"
    fi
    echo
}

check_users() {
    print_section "👥 USUARIOS DE SAMBA"
    
    if command -v pdbedit >/dev/null 2>&1; then
        users=$(pdbedit -L 2>/dev/null | cut -d: -f1)
        if [ -n "$users" ]; then
            echo "Usuarios configurados:"
            echo "$users" | while read user; do
                echo "   - $user"
            done
        else
            echo -e "${YELLOW}No hay usuarios configurados${NC}"
        fi
    else
        echo -e "${RED}pdbedit no disponible${NC}"
    fi
    echo
}

check_ports() {
    print_section "🔌 PUERTOS Y CONEXIONES"
    
    ports=("139" "445")
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo -e "✅ Puerto $port: ${GREEN}Abierto${NC}"
        else
            echo -e "❌ Puerto $port: ${RED}Cerrado${NC}"
        fi
    done
    
    # Verificar conexiones activas
    connections=$(smbstatus -b 2>/dev/null | grep -v "^Samba\|^=\|^$\|PID\|Service\|^---" | wc -l)
    echo "Conexiones activas: $connections"
    echo
}

check_logs() {
    print_section "📝 LOGS RECIENTES"
    
    log_files=("/var/log/samba/log.smbd" "/var/log/samba/log.nmbd")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo "Últimas líneas de $log_file:"
            tail -5 "$log_file" 2>/dev/null | sed 's/^/   /'
        else
            echo -e "${YELLOW}$log_file no existe${NC}"
        fi
        echo
    done
}

check_firewall() {
    print_section "🔥 FIREWALL"
    
    if command -v ufw >/dev/null 2>&1; then
        ufw_status=$(ufw status 2>/dev/null)
        if echo "$ufw_status" | grep -q "Status: active"; then
            echo -e "UFW: ${GREEN}Activo${NC}"
            if echo "$ufw_status" | grep -q "Samba\|139\|445"; then
                echo -e "Reglas Samba: ${GREEN}Configuradas${NC}"
            else
                echo -e "Reglas Samba: ${RED}No configuradas${NC}"
            fi
        else
            echo -e "UFW: ${YELLOW}Inactivo${NC}"
        fi
    else
        echo -e "${YELLOW}UFW no instalado${NC}"
    fi
    echo
}

run_tests() {
    print_section "🧪 PRUEBAS DE CONECTIVIDAD"
    
    # Probar conexión local
    echo "Probando conexión local..."
    if smbclient -L localhost -N >/dev/null 2>&1; then
        echo -e "✅ Conexión local: ${GREEN}Exitosa${NC}"
    else
        echo -e "❌ Conexión local: ${RED}Fallida${NC}"
    fi
    
    # Probar testparm
    echo "Verificando configuración..."
    if testparm -s >/dev/null 2>&1; then
        echo -e "✅ Configuración: ${GREEN}Válida${NC}"
    else
        echo -e "❌ Configuración: ${RED}Inválida${NC}"
        echo "Errores encontrados:"
        testparm -s 2>&1 | grep -i error | sed 's/^/   /'
    fi
    echo
}

main() {
    clear
    print_header
    
    check_system
    check_packages
    check_services
    check_directories
    check_config
    check_users
    check_ports
    check_firewall
    check_logs
    run_tests
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                    FIN DEL DIAGNÓSTICO                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}💡 Consejos:${NC}"
    echo "• Si hay servicios inactivos, ejecuta: systemctl start smbd nmbd"
    echo "• Si hay errores de configuración, revisa: /etc/samba/smb.conf"
    echo "• Para ver logs en tiempo real: tail -f /var/log/samba/log.smbd"
    echo "• Para reiniciar servicios: systemctl restart smbd nmbd"
    echo
}

main "$@" 