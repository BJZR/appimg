#!/bin/bash

echo "Instalando appimg..."

# Determinar la arquitectura del sistema
ARCH=$(uname -m)

# Crear directorio de instalación
sudo mkdir -p /usr/local/bin
sudo mkdir -p ~/.local/bin

# Descargar el script
echo "Descargando appimg..."
curl -s https://raw.githubusercontent.com/bjzr/appimg/main/appimg.sh -o /tmp/appimg.sh

# Dar permisos de ejecución
chmod +x /tmp/appimg.sh

# Mover a la ubicación final
sudo mv /tmp/appimg.sh /usr/local/bin/appimg
sudo chmod +x /usr/local/bin/appimg

echo "appimg instalado en /usr/local/bin/appimg"
echo "Uso: appimg {install|update|remove|status|list} [nombre]"