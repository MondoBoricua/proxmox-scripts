#!/usr/bin/env bash

# cf-ddns.sh — DDNS con Cloudflare / Cloudflare Dynamic DNS updater
# Mantiene tus records A apuntando a tu IP pública actual, ¡qué brutal!
#
# Config: /etc/cf-ddns.env (chmod 600) con:
#   CF_TOKEN="tu-api-token"          # API Token con permiso Zone.DNS (Edit)
#   CF_ZONE="ejemplo.com"            # Tu zona en Cloudflare
#   CF_RECORDS="@,home,*.home"       # Records a mantener (@ = apex, nombre relativo o FQDN)
#   CF_TTL="300"                     # Opcional (default 300)
#   CF_PROXIED="false"               # Opcional (default false — para DDNS casero casi siempre false)
#
# No hace falta buscar Zone IDs ni Record IDs en el dashboard:
# el script los resuelve solo por API, los cachea, y CREA los records que falten.
#
# Cron sugerido: */5 * * * * root /opt/cf-ddns/cf-ddns.sh >/dev/null 2>&1
# Uso manual: cf-ddns.sh [--force]   (--force ignora el cache de IP y actualiza sí o sí)

set -u

ENV_FILE="${CF_DDNS_ENV:-/etc/cf-ddns.env}"
CACHE_DIR="${CF_DDNS_CACHE:-/var/cache/cf-ddns}"
LOG="${CF_DDNS_LOG:-/var/log/cf-ddns.log}"
API="https://api.cloudflare.com/client/v4"
MAX_LOG_LINES=500

log() { echo "$(date -Is) $*" >> "$LOG"; }

die() {
    log "ERROR: $*"
    echo "[cf-ddns] ERROR: $*" >&2
    exit 1
}

# Cargar configuración - sin esto no podemos hacer na'
[ -f "$ENV_FILE" ] || die "no existe $ENV_FILE — corre install.sh primero"
# shellcheck source=/dev/null
source "$ENV_FILE"
[ -n "${CF_TOKEN:-}" ] || die "CF_TOKEN vacío en $ENV_FILE"
[ -n "${CF_ZONE:-}" ]  || die "CF_ZONE vacío en $ENV_FILE"
[ -n "${CF_RECORDS:-}" ] || die "CF_RECORDS vacío en $ENV_FILE"
CF_TTL="${CF_TTL:-300}"
CF_PROXIED="${CF_PROXIED:-false}"

command -v jq >/dev/null 2>&1 || die "falta jq (apt install -y jq)"
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# Llamada autenticada a la API de Cloudflare
cf_api() {
    curl -s -m 15 \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json" \
        "$@"
}

# ── 1) IP pública actual (varias fuentes, por si una falla) ──────────
IP=""
for src in "https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
    IP=$(curl -s -m 8 "$src" 2>/dev/null | tr -d '[:space:]')
    [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
    IP=""
done
[ -n "$IP" ] || die "no pude obtener la IP pública de ninguna fuente"

# ── 2) Si la IP no cambió, no gastamos API calls ─────────────────────
IP_CACHE="$CACHE_DIR/last-ip"
LAST=$(cat "$IP_CACHE" 2>/dev/null || true)
if [ "$IP" = "$LAST" ] && [ "$FORCE" = "0" ]; then
    exit 0
fi

# ── 3) Resolver Zone ID (cacheado) ───────────────────────────────────
ZONE_CACHE="$CACHE_DIR/zone-id"
ZONE_ID=$(cat "$ZONE_CACHE" 2>/dev/null || true)
if [ -z "$ZONE_ID" ]; then
    ZONE_ID=$(cf_api "$API/zones?name=$CF_ZONE&status=active" | jq -r '.result[0].id // empty')
    [ -n "$ZONE_ID" ] || die "no encontré la zona '$CF_ZONE' — verifica el token (necesita Zone:Read + DNS:Edit) y el nombre de la zona"
    echo "$ZONE_ID" > "$ZONE_CACHE"
    log "zona $CF_ZONE resuelta -> $ZONE_ID"
fi

# Convierte un nombre de record a FQDN: "@" = apex, relativo o FQDN completo
to_fqdn() {
    local name="$1"
    case "$name" in
        "@") echo "$CF_ZONE" ;;
        *".$CF_ZONE") echo "$name" ;;
        "$CF_ZONE") echo "$name" ;;
        *) echo "$name.$CF_ZONE" ;;
    esac
}

# Resuelve (o crea) el record y devuelve su ID
get_record_id() {
    local fqdn="$1"
    local cache_file="$CACHE_DIR/record-$(echo "$fqdn" | tr '*.' '__')"
    local rid
    rid=$(cat "$cache_file" 2>/dev/null || true)
    if [ -z "$rid" ]; then
        rid=$(cf_api "$API/zones/$ZONE_ID/dns_records?type=A&name=$fqdn" | jq -r '.result[0].id // empty')
        if [ -z "$rid" ]; then
            # El record no existe — lo creamos apuntando a la IP actual
            rid=$(cf_api -X POST "$API/zones/$ZONE_ID/dns_records" \
                -d "{\"type\":\"A\",\"name\":\"$fqdn\",\"content\":\"$IP\",\"ttl\":$CF_TTL,\"proxied\":$CF_PROXIED}" \
                | jq -r '.result.id // empty')
            [ -n "$rid" ] && log "record $fqdn no existía — creado -> $IP"
        fi
        [ -n "$rid" ] && echo "$rid" > "$cache_file"
    fi
    echo "$rid"
}

# Actualiza un record; si el ID cacheado quedó viejo, re-resuelve y reintenta una vez
update_record() {
    local fqdn="$1"
    local rid ok
    rid=$(get_record_id "$fqdn")
    [ -n "$rid" ] || { log "ERROR: no pude resolver/crear el record $fqdn"; return 1; }

    ok=$(cf_api -X PATCH "$API/zones/$ZONE_ID/dns_records/$rid" \
        -d "{\"content\":\"$IP\"}" | jq -r '.success')
    if [ "$ok" != "true" ]; then
        # ID viejo (record borrado/recreado) — limpiar cache y reintentar
        rm -f "$CACHE_DIR/record-$(echo "$fqdn" | tr '*.' '__')"
        rid=$(get_record_id "$fqdn")
        [ -n "$rid" ] || { log "ERROR: $fqdn desapareció y no pude recrearlo"; return 1; }
        ok=$(cf_api -X PATCH "$API/zones/$ZONE_ID/dns_records/$rid" \
            -d "{\"content\":\"$IP\"}" | jq -r '.success')
    fi

    if [ "$ok" = "true" ]; then
        log "$fqdn actualizado -> $IP"
        return 0
    else
        log "ERROR actualizando $fqdn -> $IP"
        return 1
    fi
}

# ── 4) Actualizar todos los records ──────────────────────────────────
FAIL=0
IFS=', ' read -r -a RECORDS <<< "$CF_RECORDS"
for name in "${RECORDS[@]}"; do
    [ -n "$name" ] || continue
    update_record "$(to_fqdn "$name")" || FAIL=1
done

# ── 5) Solo cachear la IP si TODO salió bien (si falló, reintenta al próximo cron) ──
if [ "$FAIL" = "0" ]; then
    echo "$IP" > "$IP_CACHE"
    log "IP: ${LAST:-ninguna} -> $IP (todos los records al día)"
fi

# Mantener el log en tamaño razonable
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt "$MAX_LOG_LINES" ]; then
    tail -n "$MAX_LOG_LINES" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

exit $FAIL
