#!/usr/bin/env bash

# DuckDNS Installer Standalone
# Script para instalar y configurar DuckDNS en contenedores LXC de Proxmox
# Mantiene tu IP dinámica actualizada automáticamente, ¡qué brutal!

echo "===== DuckDNS Installer ====="

# Pedimos los datos necesarios al usuario - sin esto no podemos hacer na'
read -r -p "Ingresa tu token de DuckDNS: " DUCKDNS_TOKEN
read -r -p "Ingresa tu subdominio (ej. midominio): " DUCKDNS_DOMAIN

echo "[INFO] Instalando curl y cron..."
# Actualizamos los paquetes primero - siempre hay que estar al día
apt update
# Instalamos curl para hacer las peticiones HTTP y cron para automatizar
apt install -y curl cron
echo "[OK] curl y cron instalados."

echo "[INFO] Configurando DuckDNS..."
# Creamos el directorio donde va a vivir nuestro script
mkdir -p /opt/duckdns
# Generamos el script que va a actualizar la IP automáticamente
cat <<EOF >/opt/duckdns/duck.sh
#!/bin/bash
# Este script se ejecuta cada 5 minutos para mantener la IP actualizada
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o ~/duckdns.log -K -
EOF

# Le damos permisos de ejecución solo al owner (seguridad ante todo)
chmod 700 /opt/duckdns/duck.sh

# Configuramos cron para que ejecute el script cada 5 minutos
cat <<EOF >/etc/cron.d/duckdns
*/5 * * * * root /opt/duckdns/duck.sh >/dev/null 2>&1
EOF

# Permisos correctos para el archivo de cron
chmod 644 /etc/cron.d/duckdns
# Reiniciamos cron para que tome la nueva configuración
systemctl restart cron

echo "[OK] DuckDNS configurado y activo."

echo "[INFO] Limpiando..."
# Removemos paquetes que ya no se necesitan - mantenemos el sistema limpio
apt autoremove -y
# Limpiamos el cache de apt para liberar espacio
apt autoclean -y
echo "[OK] Limpieza completada."

echo "===== DuckDNS Instalado Correctamente ====="
