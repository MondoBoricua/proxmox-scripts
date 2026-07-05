# 🌐 Nginx + PHP Web Server para Proxmox LXC

<p>
  <img alt="Proxmox" src="https://img.shields.io/badge/Proxmox-VE_8.x_%2F_9.x-E57000?style=for-the-badge&logo=proxmox&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
  <a href="https://www.patreon.com/MT3K"><img alt="Patreon" src="https://img.shields.io/badge/Patreon-Support_MT3K-FF424D?style=for-the-badge&logo=patreon"></a>
</p>


Un script automatizado para crear y configurar servidores web **Nginx + PHP** en contenedores LXC de Proxmox, perfecto para hospedar sitios web, aplicaciones PHP, WordPress, Laravel y servicios web sin complicaciones.

## ✨ Novedades v3.0

- 🐘 **PHP-FPM opcional** con versiones 8.1, 8.2 y 8.3
- 📦 **Composer** instalado globalmente
- ⚡ **Configuración PHP optimizada** para producción
- 🛠️ **php-manager** - Nueva herramienta de gestión PHP
- 🎨 **Página de bienvenida dinámica** con info del sistema en tiempo real
- 🔒 **Security headers** configurados por defecto

## 📋 Requisitos

* **Proxmox VE 8.x o 9.x**
* **Template LXC** (Ubuntu 22.04/24.04 o Debian 12/13 - se detecta automáticamente)
* **Acceso de red** para el contenedor
* **Dominio o IP** para acceder al servidor web

## 🚀 Instalación Rápida

### Método 1: Instalación Automática (Recomendado)

```bash
# Ejecutar desde el HOST Proxmox (no desde un contenedor)
bash -c "$(wget -qO- https://raw.githubusercontent.com/MondoBoricua/nginx-server/master/auto-install.sh)"
```

### Método 2: Instalación Manual

```bash
# Clonar el repositorio
git clone https://github.com/MondoBoricua/nginx-server.git
cd nginx-server

# Hacer ejecutable el instalador
chmod +x auto-install.sh

# Ejecutar instalación
./auto-install.sh
```

## 🔄 Actualizar Contenedor Existente

¿Ya tienes un contenedor con Nginx? Puedes actualizarlo a la v3.0 con PHP:

```bash
# Ejecutar DENTRO del contenedor existente
bash -c "$(wget -qO- https://raw.githubusercontent.com/MondoBoricua/nginx-server/master/update.sh)"
```

El script de actualización te permite:
- Instalar PHP en contenedor existente
- Actualizar herramientas de gestión
- Actualizar página de bienvenida
- Configurar Nginx para PHP

## 🎯 Proceso de Instalación

El instalador te guía paso a paso:

```
STEP 1/5: Verificando Entorno
STEP 2/5: Configuración del Contenedor
STEP 3/5: Recursos y Red
STEP 4/5: Configuración de PHP    ← ¡NUEVO!
STEP 5/5: Confirmación
```

### Configuración de PHP (Paso 4)

```
PHP Configuration
Recommended for most web applications

> Install PHP? [y/N]: y

Available PHP versions:
   1) PHP 8.1 (LTS - stable)
   2) PHP 8.2 (recommended)
   3) PHP 8.3 (latest)

> PHP Version [2]: 2
[OK] PHP 8.2 selected
```

## ✨ Características

### 🌐 Servidor Web
* 🔧 **Instalación completamente automatizada**
* 🌐 **Nginx optimizado para producción**
* 🔒 **Security headers** (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
* 📁 **Gzip compression** habilitado
* 🚀 **Static file caching** (30 días)
* 🛡️ **Bloqueo de archivos sensibles** (.env, .log, .ini, .htaccess)

### 🐘 PHP (Opcional)
* **PHP-FPM** con versiones 8.1, 8.2, 8.3
* **Módulos incluidos**: mysql, pgsql, sqlite3, curl, gd, mbstring, xml, zip, bcmath, intl, opcache, soap, redis, imagick
* **Composer** instalado globalmente
* **Configuración optimizada**:
  - `upload_max_filesize`: 64M
  - `post_max_size`: 64M
  - `memory_limit`: 256M
  - `max_execution_time`: 300s
  - OPcache habilitado

### 🔐 Seguridad
* 🔒 **SSL/TLS** con Let's Encrypt (Certbot)
* 🛡️ **UFW Firewall** configurado
* 🚫 **Fail2ban** protección contra ataques
* 🔑 **expose_php = Off** por seguridad
* 🔒 **cgi.fix_pathinfo = 0** contra path traversal

### 🛠️ Herramientas de Gestión
* `nginx-info` - Panel de información del servidor
* `nginx-manager` - Gestión de sitios web
* `ssl-manager` - Gestión de certificados SSL
* `php-manager` - Gestión de PHP (nuevo!)

## 🎯 Lo que Instala

| Paquete | Descripción |
|---------|-------------|
| **Nginx** | Servidor web principal |
| **PHP-FPM** | Procesamiento PHP (opcional) |
| **Composer** | Gestor de dependencias PHP |
| **Certbot** | Certificados SSL gratuitos |
| **UFW** | Firewall configurado |
| **Fail2ban** | Protección contra ataques |
| **Git, Curl, Wget** | Herramientas esenciales |
| **htop, tree, nano** | Utilidades de sistema |

## 🖥️ Comandos Disponibles

### Nginx
```bash
nginx-info      # Mostrar información del servidor
nginx-manager   # Gestionar sitios web
nginx-status    # Ver estado del servicio
nginx-test      # Probar configuración
nginx-reload    # Recargar configuración
nginx-restart   # Reiniciar servicio
nginx-logs      # Ver logs de acceso
nginx-errors    # Ver logs de errores
```

### PHP (si está instalado)
```bash
php-manager     # Gestionar configuración PHP
php-status      # Ver estado de PHP-FPM
php-restart     # Reiniciar PHP-FPM
php-logs        # Ver logs de PHP-FPM
composer        # Gestor de dependencias
```

### SSL
```bash
ssl-manager     # Gestionar certificados SSL
```

## 🛠️ php-manager

Nueva herramienta interactiva para gestionar PHP:

```
================================================
           PHP Manager - v1.0
================================================

   1) Show PHP info
   2) Show installed modules
   3) Restart PHP-FPM
   4) View PHP-FPM status
   5) Edit php.ini
   6) View PHP-FPM logs
   7) Clear OPcache
   8) Update Composer
   0) Exit
```

## 📂 Estructura de Directorios

```
/var/www/html/           # Directorio web principal
/etc/nginx/              # Configuración Nginx
├── sites-available/     # Sitios disponibles
├── sites-enabled/       # Sitios habilitados
└── nginx.conf           # Configuración principal
/etc/php/8.x/            # Configuración PHP
├── fpm/php.ini          # PHP-FPM config
└── fpm/pool.d/www.conf  # Pool config
/var/log/nginx/          # Logs de Nginx
/opt/nginx-server/       # Scripts de gestión
```

## 🌐 Páginas de Prueba

### Con PHP instalado
- `http://IP/` - Página de bienvenida dinámica con info del sistema
- `http://IP/info.php` - phpinfo() completo

### Sin PHP
- `http://IP/` - Página de bienvenida HTML estática

## 📝 Configuraciones de Ejemplo

### Sitio PHP (Laravel, WordPress, etc.)

```nginx
server {
    listen 80;
    server_name ejemplo.com www.ejemplo.com;
    root /var/www/ejemplo.com/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

### Sitio Web Estático

```nginx
server {
    listen 80;
    server_name ejemplo.com www.ejemplo.com;
    root /var/www/ejemplo.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

## 🔒 Obtener Certificado SSL

```bash
# Ejecutar ssl-manager
ssl-manager

# O directamente con certbot
certbot --nginx -d ejemplo.com -d www.ejemplo.com
```

## 🖥️ Acceso al Contenedor

### Consola Proxmox (Recomendado)
```bash
pct enter [ID_CONTENEDOR]
```

### SSH
```bash
ssh root@IP_DEL_CONTENEDOR
# Contraseña por defecto: nginx123
```

## 🛠️ Solución de Problemas

### Nginx no inicia
```bash
nginx -t                    # Verificar configuración
journalctl -u nginx -n 50   # Ver logs
systemctl restart nginx     # Reiniciar
```

### PHP-FPM no responde
```bash
php-status                  # Ver estado
php-restart                 # Reiniciar
php-logs                    # Ver logs
```

### Problemas de permisos
```bash
chown -R www-data:www-data /var/www/
chmod -R 755 /var/www/
```

### Limpiar OPcache
```bash
php-manager   # Opción 7
# O crear archivo para limpiar via web
```

## 📊 Resumen de Instalación

Al finalizar, verás un resumen como este:

```
==================================================================
||              [OK] INSTALLATION COMPLETED!                    ||
==================================================================

   Container
   ├─ ID: 100
   ├─ Hostname: nginx-server
   ├─ IP: 192.168.1.100
   ├─ Password: nginx123
   └─ Template: local:vztmpl/ubuntu-24.04...

   Software
   ├─ [OK] Nginx
   ├─ [OK] PHP 8.2 (PHP-FPM)
   └─ [OK] Composer

   Features
   ├─ [OK] Autoboot enabled
   ├─ [OK] Autologin configured
   └─ [OK] Service running

Web Server Access
   ├─ http://192.168.1.100
   └─ http://192.168.1.100/info.php (PHP Info)
```

## 🤝 Contribuir

¿Encontraste un bug o tienes una mejora?

1. Haz fork del repositorio
2. Crea tu rama de feature (`git checkout -b feature/mejora-increible`)
3. Commit tus cambios (`git commit -am '🚀 Añade mejora increíble'`)
4. Push a la rama (`git push origin feature/mejora-increible`)
5. Crea un Pull Request

## 📜 Licencia

Este proyecto está bajo la Licencia MIT - ve el archivo LICENSE para más detalles.

## ⭐ ¿Te Sirvió?

Si este script te ayudó, ¡dale una estrella al repo! ⭐

---

**Desarrollado en 🇵🇷 Puerto Rico con mucho ☕ café para la comunidad de Proxmox**

## 🔗 Recursos Adicionales

* [Documentación oficial de Nginx](https://nginx.org/en/docs/)
* [Documentación de PHP](https://www.php.net/docs.php)
* [Guía de Proxmox LXC](https://pve.proxmox.com/wiki/Linux_Container)
* [Let's Encrypt](https://letsencrypt.org/)
* [Composer](https://getcomposer.org/)

---

*Basado en el exitoso proyecto [proxmox-samba](https://github.com/MondoBoricua/proxmox-samba)*

## ❤️ Support / Apoya

Free and open source (MIT). If this script saved you time, [**become a patron**](https://www.patreon.com/MT3K) — patrons ($5+) get early access to new MT3K tools and a voice on what ships next. / Gratis y open source (MIT). Si este script te ahorró tiempo, [**hazte patron**](https://www.patreon.com/MT3K).
