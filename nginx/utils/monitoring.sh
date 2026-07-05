#!/bin/bash

# 📊 Monitoring Utils - Herramientas de Monitoreo para Nginx
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

# Mostrar estadísticas en tiempo real
show_realtime_stats() {
    log_step "Mostrando estadísticas en tiempo real..."
    
    while true; do
        clear
        echo -e "${CYAN}"
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                📊 ESTADÍSTICAS EN TIEMPO REAL 📊             ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        # Información del sistema
        echo -e "${WHITE}🖥️  Sistema${NC}"
        echo -e "   ${CYAN}Uptime:${NC} $(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f4-)"
        echo -e "   ${CYAN}Load:${NC} $(uptime | awk -F'load average:' '{print $2}' | xargs)"
        
        # CPU y Memoria
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "N/A")
        local mem_info=$(free -h | grep Mem)
        local mem_used=$(echo $mem_info | awk '{print $3}')
        local mem_total=$(echo $mem_info | awk '{print $2}')
        local mem_percent=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        
        echo -e "   ${CYAN}CPU:${NC} ${cpu_usage}%"
        echo -e "   ${CYAN}Memoria:${NC} $mem_used / $mem_total (${mem_percent}%)"
        
        # Estado de Nginx
        echo -e "\n${WHITE}🌐 Nginx${NC}"
        if systemctl is-active --quiet nginx; then
            echo -e "   ${GREEN}✅ Estado: Activo${NC}"
            
            # Procesos nginx
            local nginx_processes=$(pgrep -c nginx 2>/dev/null || echo "0")
            echo -e "   ${CYAN}Procesos:${NC} $nginx_processes"
            
            # Conexiones activas
            if command -v ss &> /dev/null; then
                local connections=$(ss -tuln | grep -E ':80|:443' | wc -l)
                echo -e "   ${CYAN}Puertos activos:${NC} $connections"
            fi
            
        else
            echo -e "   ${RED}❌ Estado: Inactivo${NC}"
        fi
        
        # Estadísticas de acceso
        echo -e "\n${WHITE}📊 Estadísticas de Acceso${NC}"
        if [ -f "/var/log/nginx/access.log" ]; then
            local requests_last_minute=$(tail -100 /var/log/nginx/access.log 2>/dev/null | grep "$(date '+%d/%b/%Y:%H:%M')" | wc -l)
            local total_requests_today=$(grep "$(date '+%d/%b/%Y')" /var/log/nginx/access.log 2>/dev/null | wc -l)
            
            echo -e "   ${CYAN}Requests último minuto:${NC} $requests_last_minute"
            echo -e "   ${CYAN}Requests hoy:${NC} $total_requests_today"
            
            # Top IPs
            echo -e "   ${CYAN}Top 3 IPs:${NC}"
            tail -1000 /var/log/nginx/access.log 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | head -3 | while read count ip; do
                echo -e "     $ip: $count requests"
            done
        else
            echo -e "   ${YELLOW}No hay logs disponibles${NC}"
        fi
        
        # Errores
        echo -e "\n${WHITE}⚠️  Errores${NC}"
        if [ -f "/var/log/nginx/error.log" ]; then
            local errors_today=$(grep "$(date '+%Y/%m/%d')" /var/log/nginx/error.log 2>/dev/null | wc -l)
            echo -e "   ${CYAN}Errores hoy:${NC} $errors_today"
            
            if [ "$errors_today" -gt 0 ]; then
                echo -e "   ${CYAN}Último error:${NC}"
                tail -1 /var/log/nginx/error.log 2>/dev/null | cut -c1-80
            fi
        else
            echo -e "   ${YELLOW}No hay logs de errores${NC}"
        fi
        
        # Seguridad
        echo -e "\n${WHITE}🔐 Seguridad${NC}"
        if command -v fail2ban-client &> /dev/null && systemctl is-active --quiet fail2ban; then
            local banned_ips=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d':' -f2 | wc -w)
            echo -e "   ${CYAN}Fail2ban activo:${NC} $banned_ips jails"
        else
            echo -e "   ${YELLOW}Fail2ban no activo${NC}"
        fi
        
        if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
            echo -e "   ${GREEN}✅ UFW activo${NC}"
        else
            echo -e "   ${YELLOW}⚠️  UFW inactivo${NC}"
        fi
        
        echo -e "\n${PURPLE}Presiona Ctrl+C para salir${NC}"
        sleep 5
    done
}

# Generar reporte de estadísticas
generate_stats_report() {
    log_step "Generando reporte de estadísticas..."
    
    local report_file="/tmp/nginx-stats-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "REPORTE DE ESTADÍSTICAS DE NGINX SERVER"
        echo "========================================"
        echo "Generado: $(date)"
        echo "Hostname: $(hostname)"
        echo "IP: $(hostname -I | awk '{print $1}')"
        echo ""
        
        echo "INFORMACIÓN DEL SISTEMA"
        echo "----------------------"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f4-)"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
        echo "CPU Cores: $(nproc)"
        echo "Memoria Total: $(free -h | grep Mem | awk '{print $2}')"
        echo "Memoria Usada: $(free -h | grep Mem | awk '{print $3}')"
        echo "Disco Usado: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
        echo ""
        
        echo "ESTADO DE NGINX"
        echo "---------------"
        if systemctl is-active --quiet nginx; then
            echo "Estado: Activo"
            echo "Versión: $(nginx -v 2>&1 | cut -d'/' -f2)"
            echo "Procesos: $(pgrep -c nginx 2>/dev/null || echo "0")"
            echo "Configuración: $(nginx -t 2>&1 | grep -q "syntax is ok" && echo "Válida" || echo "Con errores")"
        else
            echo "Estado: Inactivo"
        fi
        echo ""
        
        echo "SITIOS WEB"
        echo "----------"
        echo "Sitios disponibles: $(find /etc/nginx/sites-available -maxdepth 1 -type f | wc -l)"
        echo "Sitios habilitados: $(find /etc/nginx/sites-enabled -maxdepth 1 -type l | wc -l)"
        if [ -d "/etc/nginx/sites-enabled" ]; then
            echo "Sitios activos:"
            for site in /etc/nginx/sites-enabled/*; do
                if [ -L "$site" ]; then
                    echo "  - $(basename "$site")"
                fi
            done
        fi
        echo ""
        
        echo "CERTIFICADOS SSL"
        echo "----------------"
        if [ -d "/etc/letsencrypt/live" ]; then
            local ssl_count=0
            local ssl_expiring=0
            for cert_dir in /etc/letsencrypt/live/*; do
                if [ -d "$cert_dir" ] && [ -f "$cert_dir/fullchain.pem" ]; then
                    ssl_count=$((ssl_count + 1))
                    local domain=$(basename "$cert_dir")
                    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_dir/fullchain.pem" 2>/dev/null | cut -d= -f2)
                    if [ -n "$expiry_date" ]; then
                        local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
                        local current_timestamp=$(date +%s)
                        local days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                        
                        echo "  $domain: expira en $days_left días"
                        if [ "$days_left" -lt 30 ]; then
                            ssl_expiring=$((ssl_expiring + 1))
                        fi
                    fi
                fi
            done
            echo "Total certificados: $ssl_count"
            echo "Expiran pronto (<30 días): $ssl_expiring"
        else
            echo "No hay certificados SSL instalados"
        fi
        echo ""
        
        echo "ESTADÍSTICAS DE ACCESO (ÚLTIMOS 7 DÍAS)"
        echo "======================================="
        if [ -f "/var/log/nginx/access.log" ]; then
            echo "Total requests: $(wc -l < /var/log/nginx/access.log)"
            echo "Requests hoy: $(grep "$(date '+%d/%b/%Y')" /var/log/nginx/access.log 2>/dev/null | wc -l)"
            echo ""
            echo "Top 10 IPs:"
            tail -10000 /var/log/nginx/access.log 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
            echo ""
            echo "Top 10 páginas:"
            tail -10000 /var/log/nginx/access.log 2>/dev/null | awk '{print $7}' | sort | uniq -c | sort -nr | head -10
            echo ""
            echo "Códigos de respuesta:"
            tail -10000 /var/log/nginx/access.log 2>/dev/null | awk '{print $9}' | sort | uniq -c | sort -nr
        else
            echo "No hay logs de acceso disponibles"
        fi
        echo ""
        
        echo "ERRORES (ÚLTIMOS 7 DÍAS)"
        echo "========================"
        if [ -f "/var/log/nginx/error.log" ]; then
            local total_errors=$(wc -l < /var/log/nginx/error.log)
            echo "Total errores: $total_errors"
            
            if [ "$total_errors" -gt 0 ]; then
                echo ""
                echo "Últimos 5 errores:"
                tail -5 /var/log/nginx/error.log
            fi
        else
            echo "No hay logs de errores disponibles"
        fi
        echo ""
        
        echo "SEGURIDAD"
        echo "========="
        if command -v ufw &> /dev/null; then
            echo "UFW Status: $(ufw status | grep "Status:" | cut -d' ' -f2)"
        fi
        
        if command -v fail2ban-client &> /dev/null; then
            if systemctl is-active --quiet fail2ban; then
                echo "Fail2ban: Activo"
                echo "Jails activos:"
                fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d':' -f2
            else
                echo "Fail2ban: Inactivo"
            fi
        fi
        
    } > "$report_file"
    
    log_success "Reporte generado: $report_file"
    
    # Mostrar resumen
    echo -e "\n${WHITE}📋 Resumen del Reporte:${NC}"
    grep -E "(Total requests|Sitios habilitados|Total certificados|Total errores)" "$report_file" | while read line; do
        echo -e "   ${CYAN}$line${NC}"
    done
    
    echo -e "\n${CYAN}Ver reporte completo: cat $report_file${NC}"
}

# Monitorear logs en tiempo real
monitor_logs() {
    log_step "Monitoreando logs en tiempo real..."
    
    echo -e "${WHITE}Selecciona el tipo de log a monitorear:${NC}"
    echo -e "   ${YELLOW}1.${NC} Logs de acceso"
    echo -e "   ${YELLOW}2.${NC} Logs de errores"
    echo -e "   ${YELLOW}3.${NC} Todos los logs"
    
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1)
            log_info "Monitoreando logs de acceso (Ctrl+C para salir)..."
            tail -f /var/log/nginx/access.log 2>/dev/null || log_error "No se pueden leer los logs de acceso"
            ;;
        2)
            log_info "Monitoreando logs de errores (Ctrl+C para salir)..."
            tail -f /var/log/nginx/error.log 2>/dev/null || log_error "No se pueden leer los logs de errores"
            ;;
        3)
            log_info "Monitoreando todos los logs (Ctrl+C para salir)..."
            tail -f /var/log/nginx/*.log 2>/dev/null || log_error "No se pueden leer los logs"
            ;;
        *)
            log_error "Opción inválida"
            ;;
    esac
}

# Analizar logs para detectar anomalías
analyze_logs() {
    log_step "Analizando logs para detectar anomalías..."
    
    if [ ! -f "/var/log/nginx/access.log" ]; then
        log_error "No se encontraron logs de acceso"
        return 1
    fi
    
    echo -e "${WHITE}🔍 Análisis de Anomalías${NC}"
    echo
    
    # IPs con más de 100 requests en la última hora
    echo -e "${CYAN}IPs con actividad alta (>100 requests/hora):${NC}"
    local current_hour=$(date '+%d/%b/%Y:%H')
    grep "$current_hour" /var/log/nginx/access.log 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | awk '$1 > 100 {print "  " $2 ": " $1 " requests"}' | head -10
    
    echo
    
    # Códigos de error 4xx y 5xx
    echo -e "${CYAN}Errores HTTP (4xx/5xx) en la última hora:${NC}"
    grep "$current_hour" /var/log/nginx/access.log 2>/dev/null | awk '$9 ~ /^[45]/ {print $9}' | sort | uniq -c | sort -nr | awk '{print "  " $2 ": " $1 " veces"}'
    
    echo
    
    # User agents sospechosos
    echo -e "${CYAN}User agents sospechosos:${NC}"
    tail -1000 /var/log/nginx/access.log 2>/dev/null | grep -E "(bot|crawler|scanner|wget|curl)" | awk -F'"' '{print $6}' | sort | uniq -c | sort -nr | head -5 | awk '{print "  " $0}'
    
    echo
    
    # URLs más solicitadas con errores
    echo -e "${CYAN}URLs con más errores 404:${NC}"
    grep " 404 " /var/log/nginx/access.log 2>/dev/null | awk '{print $7}' | sort | uniq -c | sort -nr | head -5 | awk '{print "  " $2 ": " $1 " veces"}'
    
    echo
    
    # Análisis de bandwidth
    echo -e "${CYAN}Análisis de ancho de banda:${NC}"
    local total_bytes=$(awk '{sum += $10} END {print sum}' /var/log/nginx/access.log 2>/dev/null || echo 0)
    local total_mb=$((total_bytes / 1024 / 1024))
    echo -e "  Total transferido: ${total_mb}MB"
    
    # Top IPs por bandwidth
    echo -e "  Top 5 IPs por bandwidth:"
    awk '{ip[$1] += $10} END {for (i in ip) print ip[i], i}' /var/log/nginx/access.log 2>/dev/null | sort -nr | head -5 | while read bytes ip; do
        local mb=$((bytes / 1024 / 1024))
        echo "    $ip: ${mb}MB"
    done
}

# Verificar salud del servidor
health_check() {
    log_step "Verificando salud del servidor..."
    
    local health_score=0
    local max_score=10
    
    echo -e "${WHITE}🏥 Chequeo de Salud del Servidor${NC}"
    echo
    
    # Verificar nginx
    if systemctl is-active --quiet nginx; then
        echo -e "   ${GREEN}✅ Nginx está activo${NC}"
        health_score=$((health_score + 2))
    else
        echo -e "   ${RED}❌ Nginx está inactivo${NC}"
    fi
    
    # Verificar configuración nginx
    if nginx -t &>/dev/null; then
        echo -e "   ${GREEN}✅ Configuración nginx válida${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${RED}❌ Configuración nginx con errores${NC}"
    fi
    
    # Verificar uso de CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "0")
    if (( $(echo "$cpu_usage < 80" | bc -l 2>/dev/null || echo "1") )); then
        echo -e "   ${GREEN}✅ Uso de CPU normal (${cpu_usage}%)${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${YELLOW}⚠️  Uso de CPU alto (${cpu_usage}%)${NC}"
    fi
    
    # Verificar uso de memoria
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage < 80" | bc -l 2>/dev/null || echo "1") )); then
        echo -e "   ${GREEN}✅ Uso de memoria normal (${mem_usage}%)${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${YELLOW}⚠️  Uso de memoria alto (${mem_usage}%)${NC}"
    fi
    
    # Verificar espacio en disco
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        echo -e "   ${GREEN}✅ Espacio en disco suficiente (${disk_usage}% usado)${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${YELLOW}⚠️  Poco espacio en disco (${disk_usage}% usado)${NC}"
    fi
    
    # Verificar logs de errores recientes
    local recent_errors=$(tail -100 /var/log/nginx/error.log 2>/dev/null | grep "$(date '+%Y/%m/%d')" | wc -l)
    if [ "$recent_errors" -lt 10 ]; then
        echo -e "   ${GREEN}✅ Pocos errores recientes ($recent_errors)${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${YELLOW}⚠️  Muchos errores recientes ($recent_errors)${NC}"
    fi
    
    # Verificar conectividad
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
        echo -e "   ${GREEN}✅ Servidor web responde${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${RED}❌ Servidor web no responde${NC}"
    fi
    
    # Verificar seguridad
    local security_score=0
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        security_score=$((security_score + 1))
    fi
    if command -v fail2ban-client &> /dev/null && systemctl is-active --quiet fail2ban; then
        security_score=$((security_score + 1))
    fi
    
    if [ "$security_score" -eq 2 ]; then
        echo -e "   ${GREEN}✅ Seguridad configurada correctamente${NC}"
        health_score=$((health_score + 2))
    elif [ "$security_score" -eq 1 ]; then
        echo -e "   ${YELLOW}⚠️  Seguridad parcialmente configurada${NC}"
        health_score=$((health_score + 1))
    else
        echo -e "   ${RED}❌ Seguridad no configurada${NC}"
    fi
    
    echo
    
    # Mostrar puntuación final
    local health_percent=$((health_score * 100 / max_score))
    
    if [ "$health_percent" -ge 80 ]; then
        echo -e "${GREEN}🎉 Salud del servidor: EXCELENTE (${health_score}/${max_score} - ${health_percent}%)${NC}"
    elif [ "$health_percent" -ge 60 ]; then
        echo -e "${YELLOW}⚠️  Salud del servidor: BUENA (${health_score}/${max_score} - ${health_percent}%)${NC}"
    else
        echo -e "${RED}🚨 Salud del servidor: NECESITA ATENCIÓN (${health_score}/${max_score} - ${health_percent}%)${NC}"
    fi
}

# Función principal
main() {
    case "${1:-menu}" in
        "realtime")
            show_realtime_stats
            ;;
        "report")
            generate_stats_report
            ;;
        "logs")
            monitor_logs
            ;;
        "analyze")
            analyze_logs
            ;;
        "health")
            health_check
            ;;
        "menu")
            echo -e "${WHITE}📊 Herramientas de Monitoreo Disponibles:${NC}"
            echo -e "   ${YELLOW}realtime${NC} - Estadísticas en tiempo real"
            echo -e "   ${YELLOW}report${NC}   - Generar reporte de estadísticas"
            echo -e "   ${YELLOW}logs${NC}     - Monitorear logs en tiempo real"
            echo -e "   ${YELLOW}analyze${NC}  - Analizar logs para detectar anomalías"
            echo -e "   ${YELLOW}health${NC}   - Verificar salud del servidor"
            echo
            echo "Uso: $0 [realtime|report|logs|analyze|health]"
            ;;
        *)
            log_error "Comando desconocido: $1"
            echo "Comandos disponibles: realtime, report, logs, analyze, health"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@" 