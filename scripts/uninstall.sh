#!/bin/bash

# Script para desinstalar appimg
# Este script elimina todos los archivos de appimg del sistema

echo "Desinstalando appimg..."

# Eliminar el script de appimg del sistema
sudo rm -f /usr/local/bin/appimg 2>/dev/null

# Eliminar archivos de configuración
sudo rm -rf /home/$(whoami)/.local/share/appimg 2>/dev/null
sudo rm -rf /home/$(whoami)/.local/share/applications/appimg 2>/dev404

echo "Desinstalación completada"