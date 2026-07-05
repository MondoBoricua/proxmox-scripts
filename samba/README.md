# 🗂️ Samba Server for Proxmox LXC

<p>
  <img alt="Proxmox" src="https://img.shields.io/badge/Proxmox-VE_8.x_%2F_9.x-E57000?style=for-the-badge&logo=proxmox&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
  <a href="https://www.patreon.com/MT3K"><img alt="Patreon" src="https://img.shields.io/badge/Patreon-Support_MT3K-FF424D?style=for-the-badge&logo=patreon"></a>
</p>


**[English](#english) | [Español](#español)**

---

<a name="english"></a>
## 🇺🇸 English

An automated script to create and configure Samba servers in Proxmox LXC containers, perfect for sharing files on your local network without complications.

### 📋 Requirements

* **Proxmox VE 8.x / 9.x** (tested and working)
* **LXC Template** (Ubuntu 22.04, Debian 12 or Debian 13 - automatically detected)
* **Network access** for the container
* **Folders to share** (optional - can be created during installation)

### 🚀 Quick Installation

#### Method 1: Complete Automatic Installation (RECOMMENDED!) 🎯

**Option A: Super Fast (Two steps)** ⚡

```bash
# Step 1: Download the installer
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/auto-install.sh | bash

# Step 2: Run the installer (copy and paste the command that appears)
bash /tmp/proxmox-auto-install.sh
```

> **Note**: The first command downloads the installer, the second runs it. This avoids issues with pipes.

**Option B: Download and Run** 📥

```bash
# From Proxmox host (SSH or console)
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

**What does this script do?**

* ✅ Creates the LXC container automatically
* ✅ Detects and uses the best available template (Ubuntu 22.04, Debian 12/13)
* ✅ Configures network and storage
* ✅ Installs and configures Samba
* ✅ Creates default shared resources
* ✅ Configures users and permissions
* ✅ Enables autoboot (starts automatically with Proxmox)
* ✅ Configures console autologin (no password)
* ✅ Default password: `samba123` (customizable)
* ✅ Creates welcome screen with server information
* ✅ Configures secure and public shares
* ✅ Everything ready in 5 minutes!

#### Method 2: Manual Installation in Existing Container

##### 1. Create the LXC Container

In Proxmox, create a new LXC container:

* **Template**: Ubuntu 22.04 or Debian 11/12
* **RAM**: 1GB (recommended for multiple users)
* **Disk**: 4GB (minimum)
* **Network**: Configured with static IP or DHCP
* **Features**: Nesting enabled (optional)

##### 2. Access the Container

```bash
# From Proxmox, access the container
pct enter [CONTAINER_ID]
```

##### 3. Installation (Quick Method)

```bash
# One-line installation
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/install.sh | sudo bash
```

##### 3. Installation (Manual Method)

```bash
# Download the script
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/samba.sh

# Make it executable
chmod +x samba.sh

# Run as root
sudo ./samba.sh
```

### ⚙️ Configuration During Installation

The script will ask for:

* **Server name**: Name that will appear on the network
* **Workgroup**: Default `WORKGROUP`
* **Users**: Create users for authenticated access
* **Shared resources**: Folders to share and their permissions
* **Folder mapping**: If you want to map Proxmox host folders

### 🔧 What the Script Does

The installer automatically:

1. **Installs Samba** and necessary dependencies
2. **Configures the file** `/etc/samba/smb.conf` with optimized settings
3. **Creates users** for the system and Samba
4. **Sets up shared resources** with appropriate permissions
5. **Configures the firewall** (if enabled)
6. **Starts Samba services** automatically
7. **Creates management tools** and monitoring

### 📁 Created Structure

After installation you will find:

```
/opt/samba/
|-- samba-manager.sh      # Management tool
|-- welcome.sh            # Welcome screen
`-- backup-config.sh      # Backup script

/etc/samba/
|-- smb.conf              # Main configuration
`-- smb.conf.backup       # Configuration backup

/srv/samba/               # Base directory for shares
|-- public/               # Public share
|-- private/              # Private share
`-- users/                # User directories

/var/log/samba/           # Server logs
```

### 🔓 Container Access

#### 🖥️ Proxmox Console (Recommended)

```bash
# Direct access without password (autologin enabled)
pct enter [CONTAINER_ID]
```

#### SSH (Optional)

```bash
# SSH access (requires password)
ssh root@CONTAINER_IP
# Default password: samba123
```

#### Autoboot

The container starts automatically when Proxmox boots.

### 🖥️ Welcome Screen

When you enter the container (`pct enter [ID]`), you will automatically see:

* 🌐 Server IP and active ports
* 👥 Configured users
* 📂 Available shared resources
* 🔄 Service status
* 📊 Active connection statistics
* 🛠️ Available management commands

**Quick command**: Type `samba-info` at any time to see the information.

### 🔍 Verify it Works

#### ✅ Check the Service

```bash
# See if Samba is active
systemctl status smbd nmbd

# Verify configuration
testparm

# See shared resources
smbclient -L localhost
```

#### Test Connections

```bash
# From Windows (Run)
\\CONTAINER_IP

# From Linux
smbclient //CONTAINER_IP/public -U user

# Mount from Linux
sudo mount -t cifs //CONTAINER_IP/public /mnt/samba -o username=user
```

### 👥 User Management

```bash
# Create new user
/opt/samba/samba-manager.sh add-user username

# List users
/opt/samba/samba-manager.sh list-users

# Change password
/opt/samba/samba-manager.sh change-password user

# Remove user
/opt/samba/samba-manager.sh remove-user user
```

### 🛠️ Advanced Management

#### Add New Shared Resources

```bash
# Use the integrated manager
/opt/samba/samba-manager.sh add-share

# Or edit manually
nano /etc/samba/smb.conf
systemctl reload smbd
```

#### Map Proxmox Host Folders

```bash
# From Proxmox host, map folder to container
pct set [CONTAINER_ID] -mp0 /path/on/host,mp=/srv/samba/host-data

# Then add to smb.conf
[host-data]
    path = /srv/samba/host-data
    browsable = yes
    writable = yes
    valid users = @sambashare
```

### 🛠️ Troubleshooting

#### Installer Issues

**Error: "This script must run on Proxmox VE"**

```bash
# Make sure you are on the Proxmox HOST, not in a container
# Use SSH to connect directly to the Proxmox server
ssh root@YOUR_PROXMOX_IP
```

#### Connectivity Problems

**Can't see the server on the network**

```bash
# Verify services are running
systemctl status smbd nmbd

# Check open ports
netstat -tulpn | grep -E '139|445'

# Restart services
systemctl restart smbd nmbd
```

**Authentication error**

```bash
# Verify Samba users
pdbedit -L

# Recreate user
smbpasswd -x user
smbpasswd -a user
```

### 🔄 Backup and Restore

#### Create Backup

```bash
# Automatic configuration backup
/opt/samba/backup-config.sh

# Manual backup
tar -czf samba-backup-$(date +%Y%m%d).tar.gz /etc/samba/ /srv/samba/
```

#### Restore Configuration

```bash
# Restore from backup
tar -xzf samba-backup-YYYYMMDD.tar.gz -C /
systemctl restart smbd nmbd
```

### 🗑️ Uninstall

If you need to remove Samba:

```bash
# Stop services
systemctl stop smbd nmbd
systemctl disable smbd nmbd

# Remove packages
apt remove --purge samba samba-common-bin

# Remove configurations
rm -rf /etc/samba/
rm -rf /srv/samba/
rm -rf /opt/samba/
```

### 📝 Important Notes

* **Compatibility**: Works with Proxmox VE 8.x and 9.x, Ubuntu 22.04, Debian 12 and Debian 13
* **Templates**: The script automatically finds the best available template
* **Autologin**: Proxmox console does not require password (configured automatically)
* **SSH Password**: Default is `samba123` (can be changed during installation)
* **Autoboot**: Container starts automatically with Proxmox
* **Security**: Configured with user authentication by default
* **Firewall**: Compatible with UFW and iptables
* **Backup**: Automatic backup configuration
* **Performance**: Optimized for modern networks (SMB3)

---

<a name="español"></a>
## 🇪🇸 Español

Un script automatizado para crear y configurar servidores Samba en contenedores LXC de Proxmox, perfecto para compartir archivos en tu red local sin complicaciones.

### 📋 Requisitos

* **Proxmox VE 8.x / 9.x** (probado y funcionando)
* **Template LXC** (Ubuntu 22.04, Debian 12 o Debian 13 - se detecta automaticamente)
* **Acceso de red** para el contenedor
* **Carpetas a compartir** (opcional - se pueden crear durante la instalacion)

### 🚀 Instalacion Rapida

#### Metodo 1: Instalacion Automatica Completa (RECOMENDADO!) 🎯

**Opcion A: Super Rapida (Dos pasos)** ⚡

```bash
# Paso 1: Descargar el instalador
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/auto-install.sh | bash

# Paso 2: Ejecutar el instalador (copia y pega el comando que aparece)
bash /tmp/proxmox-auto-install.sh
```

> **Nota**: El primer comando descarga el instalador, el segundo lo ejecuta. Asi evitamos problemas con pipes.

**Opcion B: Descarga y Ejecuta** 📥

```bash
# Desde el host Proxmox (SSH o consola)
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

**Que hace este script?**

* ✅ Crea el contenedor LXC automaticamente
* ✅ Detecta y usa el mejor template disponible (Ubuntu 22.04, Debian 12/13)
* ✅ Configura la red y almacenamiento
* ✅ Instala y configura Samba
* ✅ Crea recursos compartidos predeterminados
* ✅ Configura usuarios y permisos
* ✅ Habilita autoboot (se inicia automaticamente con Proxmox)
* ✅ Configura autologin en consola (sin contrasena)
* ✅ Contrasena por defecto: `samba123` (personalizable)
* ✅ Crea pantalla de bienvenida con informacion del servidor
* ✅ Configura compartidos seguros y publicos
* ✅ Todo listo en 5 minutos!

#### Metodo 2: Instalacion Manual en Contenedor Existente

##### 1. Crear el Contenedor LXC

En Proxmox, crea un nuevo contenedor LXC:

* **Template**: Ubuntu 22.04 o Debian 11/12
* **RAM**: 1GB (recomendado para multiples usuarios)
* **Disco**: 4GB (minimo)
* **Red**: Configurada con IP estatica o DHCP
* **Features**: Nesting habilitado (opcional)

##### 2. Acceder al Contenedor

```bash
# Desde Proxmox, accede al contenedor
pct enter [ID_DEL_CONTENEDOR]
```

##### 3. Instalacion (Metodo Rapido)

```bash
# Instalacion en una sola linea
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/install.sh | sudo bash
```

##### 3. Instalacion (Metodo Manual)

```bash
# Descargar el script
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-samba/main/samba.sh

# Darle permisos de ejecucion
chmod +x samba.sh

# Ejecutar como root
sudo ./samba.sh
```

### ⚙️ Configuracion Durante la Instalacion

El script te pedira:

* **Nombre del servidor**: Nombre que aparecera en la red
* **Grupo de trabajo**: Por defecto `WORKGROUP`
* **Usuarios**: Crear usuarios para acceso autenticado
* **Recursos compartidos**: Carpetas a compartir y sus permisos
* **Mapeo de carpetas**: Si quieres mapear carpetas del host Proxmox

### 🔧 Lo que Hace el Script

El instalador automaticamente:

1. **Instala Samba** y dependencias necesarias
2. **Configura el archivo** `/etc/samba/smb.conf` con configuracion optimizada
3. **Crea usuarios** del sistema y de Samba
4. **Establece recursos compartidos** con permisos apropiados
5. **Configura el firewall** (si esta habilitado)
6. **Inicia los servicios** Samba automaticamente
7. **Crea herramientas** de gestion y monitoreo

### 📁 Estructura Creada

Despues de la instalacion encontraras:

```
/opt/samba/
|-- samba-manager.sh      # Herramienta de gestion
|-- welcome.sh            # Pantalla de bienvenida
`-- backup-config.sh      # Script de respaldo

/etc/samba/
|-- smb.conf              # Configuracion principal
`-- smb.conf.backup       # Respaldo de configuracion

/srv/samba/               # Directorio base para compartidos
|-- public/               # Compartido publico
|-- private/              # Compartido privado
`-- users/                # Directorios de usuarios

/var/log/samba/           # Logs del servidor
```

### 🔓 Acceso al Contenedor

#### 🖥️ Consola Proxmox (Recomendado)

```bash
# Acceso directo sin contrasena (autologin habilitado)
pct enter [ID_CONTENEDOR]
```

#### SSH (Opcional)

```bash
# Acceso por SSH (requiere contrasena)
ssh root@IP_DEL_CONTENEDOR
# Contrasena por defecto: samba123
```

#### Autoboot

El contenedor se inicia automaticamente cuando Proxmox arranca.

### 🖥️ Pantalla de Bienvenida

Cuando entres al contenedor (`pct enter [ID]`), veras automaticamente:

* 🌐 IP del servidor y puertos activos
* 👥 Usuarios configurados
* 📂 Recursos compartidos disponibles
* 🔄 Estado de los servicios
* 📊 Estadisticas de conexiones activas
* 🛠️ Comandos de gestion disponibles

**Comando rapido**: Escribe `samba-info` en cualquier momento para ver la informacion.

### 🔍 Verificar que Funciona

#### ✅ Comprobar el Servicio

```bash
# Ver si Samba esta activo
systemctl status smbd nmbd

# Verificar la configuracion
testparm

# Ver recursos compartidos
smbclient -L localhost
```

#### Probar Conexiones

```bash
# Desde Windows (Ejecutar)
\\IP_DEL_CONTENEDOR

# Desde Linux
smbclient //IP_DEL_CONTENEDOR/public -U usuario

# Montar desde Linux
sudo mount -t cifs //IP_DEL_CONTENEDOR/public /mnt/samba -o username=usuario
```

### 👥 Gestion de Usuarios

```bash
# Crear nuevo usuario
/opt/samba/samba-manager.sh add-user nombre_usuario

# Listar usuarios
/opt/samba/samba-manager.sh list-users

# Cambiar contrasena
/opt/samba/samba-manager.sh change-password usuario

# Eliminar usuario
/opt/samba/samba-manager.sh remove-user usuario
```

### 🛠️ Gestion Avanzada

#### Agregar Nuevos Recursos Compartidos

```bash
# Usar el gestor integrado
/opt/samba/samba-manager.sh add-share

# O editar manualmente
nano /etc/samba/smb.conf
systemctl reload smbd
```

#### Mapear Carpetas del Host Proxmox

```bash
# Desde el host Proxmox, mapear carpeta al contenedor
pct set [ID_CONTENEDOR] -mp0 /ruta/en/host,mp=/srv/samba/host-data

# Luego agregar al smb.conf
[host-data]
    path = /srv/samba/host-data
    browsable = yes
    writable = yes
    valid users = @sambashare
```

### 🛠️ Solucion de Problemas

#### Problemas con el Instalador

**Error: "Este script debe ejecutarse en un servidor Proxmox VE"**

```bash
# Asegurate de estar en el HOST Proxmox, no en un contenedor
# Usa SSH para conectarte al servidor Proxmox directamente
ssh root@IP_DE_TU_PROXMOX
```

#### Problemas de Conectividad

**No puedo ver el servidor en la red**

```bash
# Verificar que los servicios esten corriendo
systemctl status smbd nmbd

# Verificar puertos abiertos
netstat -tulpn | grep -E '139|445'

# Reiniciar servicios
systemctl restart smbd nmbd
```

**Error de autenticacion**

```bash
# Verificar usuarios de Samba
pdbedit -L

# Recrear usuario
smbpasswd -x usuario
smbpasswd -a usuario
```

### 🔄 Backup y Restauracion

#### Crear Backup

```bash
# Backup automatico de configuracion
/opt/samba/backup-config.sh

# Backup manual
tar -czf samba-backup-$(date +%Y%m%d).tar.gz /etc/samba/ /srv/samba/
```

#### Restaurar Configuracion

```bash
# Restaurar desde backup
tar -xzf samba-backup-YYYYMMDD.tar.gz -C /
systemctl restart smbd nmbd
```

### 🗑️ Desinstalar

Si necesitas remover Samba:

```bash
# Detener servicios
systemctl stop smbd nmbd
systemctl disable smbd nmbd

# Eliminar paquetes
apt remove --purge samba samba-common-bin

# Eliminar configuraciones
rm -rf /etc/samba/
rm -rf /srv/samba/
rm -rf /opt/samba/
```

### 📝 Notas Importantes

* **Compatibilidad**: Funciona con Proxmox VE 8.x y 9.x, Ubuntu 22.04, Debian 12 y Debian 13
* **Templates**: El script busca automaticamente el mejor template disponible
* **Autologin**: La consola de Proxmox no requiere contrasena (configurado automaticamente)
* **Contrasena SSH**: Por defecto es `samba123` (puedes cambiarla durante la instalacion)
* **Autoboot**: El contenedor se inicia automaticamente con Proxmox
* **Seguridad**: Por defecto se configura con autenticacion de usuarios
* **Firewall**: Compatible con UFW y iptables
* **Backup**: Configuracion automatica de respaldos
* **Performance**: Optimizado para redes modernas (SMB3)

---

## 🤝 Contributing / Contribuir

Found a bug or have an improvement? / Encontraste un bug o tienes una mejora?

1. Fork the repository / Haz fork del repositorio
2. Create your feature branch / Crea tu rama de feature (`git checkout -b feature/amazing-feature`)
3. Commit your changes / Commit tus cambios (`git commit -am 'Add amazing feature'`)
4. Push to the branch / Push a la rama (`git push origin feature/amazing-feature`)
5. Create a Pull Request / Crea un Pull Request

## 📜 License / Licencia

This project is under the MIT License - see the LICENSE file for details.

Este proyecto esta bajo la Licencia MIT - ve el archivo LICENSE para mas detalles.

---

**Developed with ❤️ for the Proxmox community**

**Desarrollado con ❤️ para la comunidad de Proxmox**

**Made in 🇵🇷 Puerto Rico**

---

## 🔗 Additional Resources / Recursos Adicionales

* [Official Samba Documentation / Documentacion oficial de Samba](https://www.samba.org/samba/docs/)
* [Proxmox LXC Guide / Guia de Proxmox LXC](https://pve.proxmox.com/wiki/Linux_Container)
* [Advanced SMB Configuration / Configuracion avanzada de SMB](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server)

## ❤️ Support / Apoya

Free and open source (MIT). If this script saved you time, [**become a patron**](https://www.patreon.com/MT3K) — patrons ($5+) get early access to new MT3K tools and a voice on what ships next. / Gratis y open source (MIT). Si este script te ahorró tiempo, [**hazte patron**](https://www.patreon.com/MT3K).
