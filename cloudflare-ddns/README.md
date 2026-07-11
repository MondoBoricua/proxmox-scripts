# ☁️ Cloudflare DDNS para Proxmox LXC

Mantén tu dominio de Cloudflare apuntando a tu IP dinámica de casa — como DuckDNS, pero con **tu propio dominio**. Crea un contenedor LXC liviano (512MB / 2GB) que actualiza tus records A cada 5 minutos.

Keep your Cloudflare domain pointing at your dynamic home IP — like DuckDNS, but with **your own domain**. Creates a lightweight LXC container that updates your A records every 5 minutes.

## ✨ Lo que lo hace diferente / What makes it different

- **Cero IDs manuales** — no tienes que buscar Zone IDs ni Record IDs en el dashboard. El script los resuelve solo por API y los cachea.
- **Crea los records que falten** — si `home.ejemplo.com` no existe, lo crea apuntando a tu IP actual.
- **Auto-recuperación** — si borras y recreas un record en el dashboard, el script detecta el ID viejo y lo re-resuelve solo.
- **Ahorra API calls** — solo llama a Cloudflare cuando tu IP realmente cambió.
- Wizard bilingüe (English/Español), autologin en consola, pantalla de bienvenida con estado del DNS.

## 📋 Requisitos / Requirements

1. Un dominio en Cloudflare (el plan gratis sirve / free plan works)
2. Un **API Token** con estos permisos sobre tu zona:
   - **Zone → Zone → Read**
   - **Zone → DNS → Edit**

   Créalo en [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens) → *Create Token* → template *Edit zone DNS*.

> 💡 Usa un token scoped a tu zona, **nunca** tu Global API Key.

## 🚀 Instalación Automática (Recomendada)

Desde el **host Proxmox** (crea el contenedor LXC completo):

```bash
curl -fsSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/cloudflare-ddns/auto-install.sh | bash
```

El wizard te pregunta: token, zona (ej. `ejemplo.com`), records a mantener, y la config del contenedor. En 2 minutos tienes DDNS corriendo.

### Records — formato

Separados por coma. `@` es la zona misma, un nombre corto es relativo a la zona, y también acepta FQDNs y wildcards:

| Escribes | Se mantiene actualizado |
|---|---|
| `@` | `ejemplo.com` |
| `home` | `home.ejemplo.com` |
| `*.home` | `*.home.ejemplo.com` (wildcard) |
| `@,home,*.home` | los tres |

## 🔧 Instalación Manual (dentro de un LXC/VM existente)

Si ya tienes un contenedor Debian/Ubuntu donde quieres correrlo:

```bash
curl -fsSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/cloudflare-ddns/install.sh | bash
```

O no-interactivo (para automatizar):

```bash
CF_TOKEN="tu-token" CF_ZONE="ejemplo.com" CF_RECORDS="@,home" \
  bash <(curl -fsSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/cloudflare-ddns/install.sh)
```

## ⚙️ Configuración

Todo vive en `/etc/cf-ddns.env` (chmod 600 — solo root lee el token):

```bash
CF_TOKEN="tu-api-token"
CF_ZONE="ejemplo.com"
CF_RECORDS="@,home,*.home"
CF_TTL="300"          # opcional
CF_PROXIED="false"    # opcional — para DDNS casero casi siempre false
```

Si cambias los records, no hay que reinstalar nada: edita el archivo y corre `/opt/cf-ddns/cf-ddns.sh --force`.

## 📖 Comandos útiles / Useful commands

```bash
# Estado del DDNS (dentro del contenedor)
cfddns

# Update manual (ignora el cache de IP)
/opt/cf-ddns/cf-ddns.sh --force

# Logs en vivo
tail -f /var/log/cf-ddns.log

# Desde el host Proxmox
pct exec <ID> -- /opt/cf-ddns/cf-ddns.sh --force
```

## 🩺 Troubleshooting

| Síntoma | Causa probable | Fix |
|---|---|---|
| `no encontré la zona` | Token sin Zone:Read, o zona mal escrita | Verifica permisos del token y el nombre |
| `ERROR actualizando <record>` | Token sin DNS:Edit | Regenera el token con ambos permisos |
| DNS no coincide con tu IP | Record con proxy (nube naranja) activado | Normal — Cloudflare responde con sus IPs. El record por detrás sí está al día |
| No actualiza nunca | cron caído | `systemctl status cron` dentro del contenedor |

## 🗑️ Desinstalar

```bash
# Si usaste el instalador automático, borra el contenedor:
pct stop <ID> && pct destroy <ID>

# Si lo instalaste manual dentro de un LXC existente:
rm -rf /opt/cf-ddns /etc/cf-ddns.env /etc/cron.d/cf-ddns /var/cache/cf-ddns /var/log/cf-ddns.log
```

---

🚀 Desarrollado en Puerto Rico con café para la comunidad Proxmox / Developed in Puerto Rico with coffee for the Proxmox community
