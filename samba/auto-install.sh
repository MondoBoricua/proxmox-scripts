#!/bin/bash

# 🗂️ Descargador Automático del Instalador de Samba para Proxmox
# Desarrollado por MondoBoricua para la comunidad de Proxmox
# Versión: 1.0

# Colores para output - pa' que se vea bonito
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# URL del instalador principal
INSTALLER_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/samba/proxmox-auto-install.sh"
INSTALLER_PATH="/tmp/proxmox-auto-install.sh"

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Función principal
main() {
    print_header "🗂️ Descargador de Samba para Proxmox"
    echo -e "${BLUE}Desarrollado por MondoBoricua${NC}"
    echo
    
    print_message "Descargando instalador automático de Samba..."
    
    # Intentar descargar con curl primero
    if command -v curl &> /dev/null; then
        if curl -fsSL "$INSTALLER_URL" -o "$INSTALLER_PATH"; then
            print_success "Instalador descargado exitosamente con curl"
        else
            download_with_wget
        fi
    elif command -v wget &> /dev/null; then
        download_with_wget
    else
        print_error "No se encontró curl ni wget para descargar el instalador"
        print_error "Instala curl o wget y vuelve a intentar"
        exit 1
    fi
    
    # Verificar que el archivo se descargó correctamente
    if [ -f "$INSTALLER_PATH" ] && [ -s "$INSTALLER_PATH" ]; then
        chmod +x "$INSTALLER_PATH"
        print_success "Instalador preparado exitosamente"
        echo
        echo -e "${YELLOW}📋 PRÓXIMO PASO:${NC}"
        echo -e "   Ejecuta el siguiente comando para iniciar la instalación:"
        echo
        echo -e "   ${GREEN}bash $INSTALLER_PATH${NC}"
        echo
        echo -e "${BLUE}💡 NOTA:${NC} El instalador te guiará paso a paso para crear"
        echo -e "   un contenedor LXC completo con Samba configurado."
    else
        print_error "Error al descargar el instalador"
        exit 1
    fi
}

# Función auxiliar para descargar con wget
download_with_wget() {
    if wget -O "$INSTALLER_PATH" "$INSTALLER_URL"; then
        print_success "Instalador descargado exitosamente con wget"
    else
        print_error "Error al descargar el instalador con wget"
        exit 1
    fi
}

# Ejecutar función principal
main "$@" 