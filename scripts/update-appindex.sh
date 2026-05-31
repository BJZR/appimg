#!/bin/bash

# Script para actualizar el índice de aplicaciones desde AppImage
# Descarga y procesa el índice de aplicaciones disponibles

echo "Actualizando índice de aplicaciones..."

# Crear directorio de caché
CACHE_DIR="/home/$(whoami)/.config/appimg/cache"

# Crear directorio si no existe
if [ ! -d "$CACHE_DIR" ]; then
  mkdir -p "$CACHE_DIR"
fi

# Descargar el índice de aplicaciones
echo "Descargando índice de aplicaciones desde AppImageHub..."
curl -s https://appimage.github.io/apps.json -o $CACHE_DIR/apps.json

echo "Índice de aplicaciones actualizado"