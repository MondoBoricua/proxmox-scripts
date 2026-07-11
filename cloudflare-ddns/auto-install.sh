#!/usr/bin/env bash

# Instalador rápido automático para Cloudflare DDNS en Proxmox
# Descarga y ejecuta el script completo de instalación automática

echo "☁️  Instalador Automático Cloudflare DDNS para Proxmox"
echo "======================================================"
echo ""

# Verificar que estamos en Proxmox
if ! command -v pct &> /dev/null; then
    echo "❌ Este script debe ejecutarse en un servidor Proxmox VE"
    echo "   Usa este comando desde el host Proxmox, no desde un contenedor"
    exit 1
fi

# Verificar que tenemos wget o curl
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "📦 Instalando wget..."
    apt update && apt install -y wget
fi

# URL del script principal
SCRIPT_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/cloudflare-ddns/proxmox-auto-install.sh"

echo "⬇️  Descargando instalador automático..."

# Descargar el script
if command -v wget &> /dev/null; then
    wget -O /tmp/cf-proxmox-auto-install.sh "$SCRIPT_URL"
else
    curl -fsSL -o /tmp/cf-proxmox-auto-install.sh "$SCRIPT_URL"
fi

# Verificar descarga
if [[ ! -s /tmp/cf-proxmox-auto-install.sh ]]; then
    echo "❌ Error al descargar el script"
    exit 1
fi

# Dar permisos
chmod +x /tmp/cf-proxmox-auto-install.sh

echo "✅ ¡Descarga completada!"
echo ""
echo "🛠️  **CONTINÚA CON LA INSTALACIÓN:**"
echo ""
echo "   bash /tmp/cf-proxmox-auto-install.sh"
echo ""
echo "💡 Copia y pega el comando de arriba para continuar"
echo ""

# El archivo queda en /tmp/cf-proxmox-auto-install.sh para uso posterior
