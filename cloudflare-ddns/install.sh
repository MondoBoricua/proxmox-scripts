#!/usr/bin/env bash

# Cloudflare DDNS Installer Standalone
# Instala y configura cf-ddns dentro de un LXC/VM Debian/Ubuntu.
# Interactivo, o no-interactivo si pasas CF_TOKEN, CF_ZONE y CF_RECORDS por entorno:
#   CF_TOKEN=xxx CF_ZONE=ejemplo.com CF_RECORDS="@,home" bash install.sh

set -u

BASE_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/cloudflare-ddns"
ENV_FILE="/etc/cf-ddns.env"
INSTALL_DIR="/opt/cf-ddns"
API="https://api.cloudflare.com/client/v4"

echo "===== Cloudflare DDNS Installer ====="

# Verificamos que estamos ejecutando como root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse como root"
    exit 1
fi

echo "[INFO] Instalando dependencias (curl, cron, jq)..."
apt update
apt install -y curl cron jq
echo "[OK] Dependencias instaladas."

# ── Configuración: entorno o preguntas ───────────────────────────────
if [ -z "${CF_TOKEN:-}" ]; then
    echo ""
    echo "Necesitas un API Token de Cloudflare con permisos sobre tu zona:"
    echo "  • Zone → Zone → Read"
    echo "  • Zone → DNS → Edit"
    echo "Créalo en: https://dash.cloudflare.com/profile/api-tokens"
    echo ""
    read -r -p "API Token de Cloudflare: " CF_TOKEN
fi
if [ -z "${CF_ZONE:-}" ]; then
    read -r -p "Tu zona (ej. ejemplo.com): " CF_ZONE
fi
if [ -z "${CF_RECORDS:-}" ]; then
    echo ""
    echo "Records A a mantener actualizados, separados por coma."
    echo "  @ = la zona misma, 'home' = home.$CF_ZONE, '*.home' = wildcard"
    read -r -p "Records [@]: " CF_RECORDS
    CF_RECORDS=${CF_RECORDS:-@}
fi
CF_TTL="${CF_TTL:-300}"
CF_PROXIED="${CF_PROXIED:-false}"

# ── Verificar el token contra la API antes de instalar nada ──────────
echo "[INFO] Verificando token y zona contra la API de Cloudflare..."
ZONE_ID=$(curl -s -m 15 -H "Authorization: Bearer $CF_TOKEN" \
    "$API/zones?name=$CF_ZONE&status=active" | jq -r '.result[0].id // empty')

if [ -z "$ZONE_ID" ]; then
    echo "❌ No pude encontrar la zona '$CF_ZONE' con ese token."
    echo "   Verifica que el token tenga Zone:Read + DNS:Edit sobre esa zona"
    echo "   y que el nombre de la zona esté bien escrito."
    exit 1
fi
echo "[OK] Zona '$CF_ZONE' verificada (ID: ${ZONE_ID:0:8}...)."

# ── Guardar configuración (solo root puede leer el token) ────────────
echo "[INFO] Guardando configuración en $ENV_FILE..."
cat > "$ENV_FILE" << EOF
# Configuración de cf-ddns — generada por install.sh
CF_TOKEN="$CF_TOKEN"
CF_ZONE="$CF_ZONE"
CF_RECORDS="$CF_RECORDS"
CF_TTL="$CF_TTL"
CF_PROXIED="$CF_PROXIED"
EOF
chmod 600 "$ENV_FILE"
echo "[OK] Configuración guardada."

# ── Instalar el updater ──────────────────────────────────────────────
echo "[INFO] Instalando el script de actualización..."
mkdir -p "$INSTALL_DIR"

# Si corremos desde un checkout del repo, usamos la copia local; si no, descargamos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/cf-ddns.sh" ]; then
    cp "$SCRIPT_DIR/cf-ddns.sh" "$INSTALL_DIR/cf-ddns.sh"
else
    curl -fsSL "$BASE_URL/cf-ddns.sh" -o "$INSTALL_DIR/cf-ddns.sh" || {
        echo "❌ Error descargando cf-ddns.sh"
        exit 1
    }
fi
chmod 700 "$INSTALL_DIR/cf-ddns.sh"
echo "[OK] Updater instalado en $INSTALL_DIR/cf-ddns.sh"

# ── Cron cada 5 minutos ──────────────────────────────────────────────
echo "[INFO] Configurando cron..."
cat > /etc/cron.d/cf-ddns << EOF
*/5 * * * * root $INSTALL_DIR/cf-ddns.sh >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/cf-ddns
systemctl restart cron
echo "[OK] Cron configurado (cada 5 minutos)."

# ── Primera actualización (crea los records que falten) ──────────────
echo "[INFO] Ejecutando primera actualización..."
if "$INSTALL_DIR/cf-ddns.sh" --force; then
    echo "[OK] Primera actualización exitosa:"
    tail -n 5 /var/log/cf-ddns.log
else
    echo "⚠️  La primera actualización reportó errores:"
    tail -n 5 /var/log/cf-ddns.log
    echo "   Revisa /var/log/cf-ddns.log y tu configuración en $ENV_FILE"
fi

echo ""
echo "===== Cloudflare DDNS Instalado ====="
echo ""
echo "  Config:            $ENV_FILE"
echo "  Update manual:     $INSTALL_DIR/cf-ddns.sh --force"
echo "  Logs:              tail -f /var/log/cf-ddns.log"
echo ""
