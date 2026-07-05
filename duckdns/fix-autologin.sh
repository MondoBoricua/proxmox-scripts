#!/bin/bash

# Script para arreglar autologin en contenedores DuckDNS existentes
# Uso: ./fix-autologin.sh [ID_CONTENEDOR]

# Colores para mejor presentación
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con colores
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Función para ejecutar comandos en el contenedor
run_in_container() {
    pct exec $CONTAINER_ID -- bash -c "$1"
}

echo "🔧 ===== ARREGLAR AUTOLOGIN EN CONTENEDOR DUCKDNS ====="
echo ""

# Verificar si se proporcionó ID del contenedor
if [ -z "$1" ]; then
    echo -n "ID del contenedor a arreglar: "
    read CONTAINER_ID
else
    CONTAINER_ID=$1
fi

# Verificar que el contenedor existe
if ! pct status $CONTAINER_ID >/dev/null 2>&1; then
    show_error "El contenedor $CONTAINER_ID no existe"
    exit 1
fi

# Verificar que el contenedor está ejecutándose
if [ "$(pct status $CONTAINER_ID | awk '{print $2}')" != "running" ]; then
    show_info "Iniciando contenedor $CONTAINER_ID..."
    pct start $CONTAINER_ID
    sleep 3
fi

show_info "Configurando autologin en contenedor $CONTAINER_ID..."

# Configurar autologin en la consola del contenedor
run_in_container "mkdir -p /etc/systemd/system/console-getty.service.d"
run_in_container "cat > /etc/systemd/system/console-getty.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# También configurar autologin para tty1 (consola principal)
run_in_container "mkdir -p /etc/systemd/system/getty@tty1.service.d"
run_in_container "cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# Configurar autologin para container-getty (específico para contenedores LXC)
run_in_container "mkdir -p /etc/systemd/system/container-getty@1.service.d"
run_in_container "cat > /etc/systemd/system/container-getty@1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud pts/%I 115200,38400,9600 vt220
EOF"

# Habilitar los servicios de autologin
run_in_container "systemctl daemon-reload"
run_in_container "systemctl enable console-getty.service"
run_in_container "systemctl enable container-getty@1.service"

show_info "Reiniciando contenedor para aplicar cambios..."
pct stop $CONTAINER_ID
sleep 2
pct start $CONTAINER_ID

show_success "¡Autologin configurado exitosamente!"
echo ""
echo "🎉 ===== RESUMEN ====="
echo "📦 Contenedor: $CONTAINER_ID"
echo "🔓 Autologin: Habilitado"
echo ""
echo "📋 COMANDOS PARA PROBAR:"
echo "• Acceder sin contraseña: pct enter $CONTAINER_ID"
echo "• Si no funciona: pct reboot $CONTAINER_ID"
echo ""
echo "💡 NOTA: El autologin solo funciona desde la consola de Proxmox,"
echo "no desde SSH. Para SSH necesitas la contraseña del contenedor." 