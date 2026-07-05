# 🦆 DuckDNS for Proxmox LXC / DuckDNS para Proxmox LXC

<p>
  <img alt="Proxmox" src="https://img.shields.io/badge/Proxmox-VE_8.x_%2F_9.x-E57000?style=for-the-badge&logo=proxmox&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
  <a href="https://www.patreon.com/MT3K"><img alt="Patreon" src="https://img.shields.io/badge/Patreon-Support_MT3K-FF424D?style=for-the-badge&logo=patreon"></a>
</p>


[English](#english) | [Español](#español)

---

## English

An automated script to configure DuckDNS in Proxmox LXC containers, perfect for keeping your dynamic IP updated without hassle.

### ✨ Features

- 🌐 **Bilingual**: English and Spanish interface
- 🎯 **Interactive menu**: Step-by-step guided installation
- 🔄 **Auto-detection**: Finds next available container ID
- 📋 **Shows resources**: Lists available storage and network bridges
- ✅ **Confirmation**: Review configuration before installation
- 🚀 **Full automation**: Creates container, configures DuckDNS, sets up cron

### 📋 Requirements

- **Proxmox VE** (any recent version)
- **LXC Template** (Ubuntu 22.04 or Debian 12/13 - auto-detected)
- **DuckDNS Token** (get it from [duckdns.org](https://www.duckdns.org))
- **Registered subdomain** on DuckDNS

### 🚀 Quick Installation

#### Method 1: Fully Automatic (RECOMMENDED) 🎯

**Option A: Super Quick (Two steps)** ⚡

```bash
# Step 1: Download installer
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/duckdns/auto-install.sh | bash

# Step 2: Run installer (copy and paste the command shown)
bash /tmp/proxmox-auto-install.sh
```

**Option B: Download and Run** 📥

```bash
# From Proxmox host (SSH or console)
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/duckdns/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

### 🖥️ Installation Wizard

The installer features a 4-step interactive wizard:

```
╔═══════════════════════════════════════════════════════════════╗
║   🦆  DUCKDNS INSTALLER FOR PROXMOX  🦆                       ║
╚═══════════════════════════════════════════════════════════════╝

Select language / Selecciona idioma:
   1) English
   2) Español

━━━ STEP 1/4: DuckDNS Configuration ━━━
▶ DuckDNS Token:
▶ Subdomain (without .duckdns.org):

━━━ STEP 2/4: Container Configuration ━━━
Next available ID is: 105
▶ Container ID [105]:
▶ Container name [duckdns]:
▶ Root password [duckdns]:

━━━ STEP 3/4: Storage and Network ━━━
Available storage:
   • local-lvm
   • local
▶ Storage for container [local-lvm]:

━━━ STEP 4/4: Confirm Installation ━━━
Container will be created with this configuration:
   DuckDNS
   ├─ Domain: mydomain.duckdns.org
   └─ Token: a1b2c3d4...

Continue with installation? [Y/n]:
```

### 🔧 What the Script Does

1. ✅ Creates LXC container automatically
2. ✅ Detects and uses best available template (Ubuntu 22.04 or Debian 12/13)
3. ✅ Configures network and storage
4. ✅ Installs and configures DuckDNS
5. ✅ Sets up cron for automatic updates every 5 minutes
6. ✅ Enables autoboot (starts automatically with Proxmox)
7. ✅ Configures console autologin (no password needed)
8. ✅ Creates welcome screen with real-time information
9. ✅ Tests first update

### 📁 Files Created

```
/opt/duckdns/duck.sh          # Update script
/opt/duckdns/welcome.sh       # Welcome screen
/etc/cron.d/duckdns           # Cron configuration
~/duckdns.log                 # Update log
/var/log/duckdns/detailed.log # Detailed history
```

### 🔍 Verify It's Working

```bash
# Access container (no password - autologin enabled)
pct enter [CONTAINER_ID]

# Check DNS resolution
nslookup yourdomain.duckdns.org

# View current public IP
curl -s ifconfig.me

# Manual update
/opt/duckdns/duck.sh
```

---

## Español

Un script automatizado para configurar DuckDNS en contenedores LXC de Proxmox, perfecto para mantener tu IP dinámica actualizada sin complicaciones.

### ✨ Características

- 🌐 **Bilingüe**: Interfaz en inglés y español
- 🎯 **Menú interactivo**: Instalación guiada paso a paso
- 🔄 **Auto-detección**: Encuentra el siguiente ID de contenedor disponible
- 📋 **Muestra recursos**: Lista almacenamientos y bridges de red disponibles
- ✅ **Confirmación**: Revisa la configuración antes de instalar
- 🚀 **Automatización completa**: Crea contenedor, configura DuckDNS, configura cron

### 📋 Requisitos

- **Proxmox VE** (cualquier versión reciente)
- **Template LXC** (Ubuntu 22.04 o Debian 12/13 - se detecta automáticamente)
- **Token de DuckDNS** (obtenido desde [duckdns.org](https://www.duckdns.org))
- **Subdominio registrado** en DuckDNS

### 🚀 Instalación Rápida

#### Método 1: Instalación Automática Completa (¡RECOMENDADO!) 🎯

**Opción A: Súper Rápida (Dos pasos)** ⚡

```bash
# Paso 1: Descargar el instalador
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/duckdns/auto-install.sh | bash

# Paso 2: Ejecutar el instalador (copia y pega el comando que aparece)
bash /tmp/proxmox-auto-install.sh
```

**Opción B: Descarga y Ejecuta** 📥

```bash
# Desde el host Proxmox (SSH o consola)
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/duckdns/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

### 🖥️ Asistente de Instalación

El instalador incluye un asistente interactivo de 4 pasos:

```
╔═══════════════════════════════════════════════════════════════╗
║   🦆  DUCKDNS INSTALLER FOR PROXMOX  🦆                       ║
╚═══════════════════════════════════════════════════════════════╝

Select language / Selecciona idioma:
   1) English
   2) Español

━━━ PASO 1/4: Configuración de DuckDNS ━━━
▶ Token de DuckDNS:
▶ Subdominio (sin .duckdns.org):

━━━ PASO 2/4: Configuración del Contenedor ━━━
El siguiente ID disponible es: 105
▶ ID del contenedor [105]:
▶ Nombre del contenedor [duckdns]:
▶ Contraseña root [duckdns]:

━━━ PASO 3/4: Almacenamiento y Red ━━━
Almacenamientos disponibles:
   • local-lvm
   • local
▶ Almacenamiento para el contenedor [local-lvm]:

━━━ PASO 4/4: Confirmar Instalación ━━━
Se creará el contenedor con esta configuración:
   DuckDNS
   ├─ Dominio: midominio.duckdns.org
   └─ Token: a1b2c3d4...

¿Continuar con la instalación? [S/n]:
```

### 🔧 Lo que Hace el Script

1. ✅ Crea el contenedor LXC automáticamente
2. ✅ Detecta y usa el mejor template disponible (Ubuntu 22.04 o Debian 12/13)
3. ✅ Configura la red y almacenamiento
4. ✅ Instala y configura DuckDNS
5. ✅ Configura cron para actualización automática cada 5 minutos
6. ✅ Habilita autoboot (se inicia automáticamente con Proxmox)
7. ✅ Configura autologin en consola (sin contraseña)
8. ✅ Crea pantalla de bienvenida con información en tiempo real
9. ✅ Prueba la primera actualización

### 📁 Archivos Creados

```
/opt/duckdns/duck.sh          # Script de actualización
/opt/duckdns/welcome.sh       # Pantalla de bienvenida
/etc/cron.d/duckdns           # Configuración de cron
~/duckdns.log                 # Log de actualizaciones
/var/log/duckdns/detailed.log # Historial detallado
```

### 🔍 Verificar que Funciona

```bash
# Acceder al contenedor (sin contraseña - autologin habilitado)
pct enter [ID_CONTENEDOR]

# Verificar resolución DNS
nslookup tudominio.duckdns.org

# Ver IP pública actual
curl -s ifconfig.me

# Actualización manual
/opt/duckdns/duck.sh
```

---

## 🛠️ Troubleshooting / Solución de Problemas

### Script doesn't run / El script no ejecuta
```bash
# Make sure you're on Proxmox HOST, not inside a container
# Asegúrate de estar en el HOST Proxmox, no dentro de un contenedor
ssh root@IP_DE_TU_PROXMOX
```

### Autologin doesn't work / El autologin no funciona
```bash
pct reboot [CONTAINER_ID]
```

### Cron not running / El cron no ejecuta
```bash
pct exec [CONTAINER_ID] -- systemctl restart cron
```

---

## 📝 Default Values / Valores por Defecto

| Parameter / Parámetro | Value / Valor |
|----------------------|---------------|
| Hostname | duckdns |
| Password / Contraseña | duckdns |
| Storage / Almacenamiento | local-lvm |
| Bridge | vmbr0 |
| Memory / Memoria | 512MB |
| Disk / Disco | 2GB |
| Cron | every 5 min / cada 5 min |

---

## 🔄 Uninstall / Desinstalar

```bash
# Remove cron and files / Remover cron y archivos
pct exec [CONTAINER_ID] -- rm /etc/cron.d/duckdns
pct exec [CONTAINER_ID] -- rm -rf /opt/duckdns/

# Or delete the entire container / O eliminar todo el contenedor
pct stop [CONTAINER_ID]
pct destroy [CONTAINER_ID]
```

---

## 🤝 Contributing / Contribuir

Found a bug or have an improvement? / ¿Encontraste un bug o tienes una mejora?

1. Fork the repository / Haz fork del repositorio
2. Create your feature branch / Crea tu rama (`git checkout -b feature/amazing-feature`)
3. Commit your changes / Commit tus cambios (`git commit -am 'Add amazing feature'`)
4. Push to the branch / Push a la rama (`git push origin feature/amazing-feature`)
5. Open a Pull Request / Crea un Pull Request

---

## 📜 License / Licencia

MIT License - see [LICENSE](LICENSE) file / ver archivo [LICENSE](LICENSE)

---

## ⭐ Did it help? / ¿Te sirvió?

If this script helped you, give the repo a star! ⭐

Si este script te ayudó, ¡dale una estrella al repo! ⭐

---

**Developed in 🇵🇷 Puerto Rico with ☕ for the Proxmox community**

**Desarrollado en 🇵🇷 Puerto Rico con ☕ para la comunidad de Proxmox**

## ❤️ Support / Apoya

Free and open source (MIT). If this script saved you time, [**become a patron**](https://www.patreon.com/MT3K) — patrons ($5+) get early access to new MT3K tools and a voice on what ships next. / Gratis y open source (MIT). Si este script te ahorró tiempo, [**hazte patron**](https://www.patreon.com/MT3K).
