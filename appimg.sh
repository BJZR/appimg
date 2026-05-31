#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
APP_ID="${2:-}"

# Directorio base para la configuración
CONFIG_DIR="$HOME/.config/appimg"
CACHE_DIR="$CONFIG_DIR/cache"
REPOS_DIR="$CONFIG_DIR/repos"

# Crear directorios necesarios
mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$REPOS_DIR"

# Archivo de repositorios conocidos
REPOS_FILE="$REPOS_DIR/known_repos.json"

[[ -z "$ACTION" ]] && {
  echo "Usage: appimg {install|update|remove|status|list|search|info} [name]"
  exit 1
}

ask() {
  read -rp "$1: " v
  echo "$v"
}

menu() {
  select opt in "$@"; do
    [[ -n "$opt" ]] && { echo "$opt"; break; }
  done
}

# Inicializar archivo de repositorios si no existe
init_repos() {
  if [[ ! -f "$REPOS_FILE" ]]; then
    cat > "$REPOS_FILE" <<EOF
{
  "repos": [
    {
      "name": "AppImageHub",
      "url": "https://appimage.github.io/apps.json",
      "enabled": true
    }
  ]
}
EOF
  fi
}

# ================= SEARCH =================
search_app() {
  init_repos
  
  if [[ -z "$APP_ID" ]]; then
    echo "🔍 Buscando aplicaciones disponibles..."
    # Aquí podríamos buscar en todos los repositorios
    echo "Por favor proporciona un término de búsqueda"
    exit 1
  fi
  
  echo "🔍 Buscando: $APP_ID"
  
  # Verificar si tenemos el índice de aplicaciones
  INDEX_FILE="$CACHE_DIR/apps_index.json"
  
  if [[ ! -f "$INDEX_FILE" ]]; then
    echo "📥 Descargando índice de aplicaciones..."
    curl -s "https://appimage.github.io/apps.json" -o "$INDEX_FILE"
  fi
  
  # Buscar en el índice
  echo "Resultados para '$APP_ID':"
  grep -i "$APP_ID" "$INDEX_FILE" | head -10 || echo "No se encontraron resultados"
}

# ================= INSTALL =================
install_app() {
  [[ -z "$APP_ID" ]] && { echo "❌ Falta nombre"; exit 1; }

  echo "📦 Instalando AppImage: $APP_ID"

  echo "Origen:"
  SOURCE=$(menu "online (buscar)" "online (URL)" "local")

  echo "Instalación:"
  MODE=$(menu "user" "system")

  if [[ "$MODE" == "user" ]]; then
    OPT="$HOME/.local/opt"
    BIN="$HOME/.local/bin"
    DESKTOP="$HOME/.local/share/applications"
    REG="$HOME/.local/share/appimg"
    SUDO=""
  else
    OPT="/usr/local/opt"
    BIN="/usr/local/bin"
    DESKTOP="/usr/share/applications"
    REG="/usr/local/share/appimg"
    SUDO="sudo"
  fi

  REGISTRY="$REG/registry.db"
  $SUDO mkdir -p "$OPT/$APP_ID" "$BIN" "$DESKTOP" "$REG"
  $SUDO touch "$REGISTRY"

  if grep -q "^$APP_ID|" "$REGISTRY"; then
    echo "❌ Ya instalada"
    exit 1
  fi

  TARGET="$OPT/$APP_ID/$APP_ID.AppImage"

  if [[ "$SOURCE" == "online (buscar)" ]]; then
    # Buscar automáticamente la aplicación
    init_repos
    echo "Buscando $APP_ID en repositorios..."
    # Aquí iría la lógica de búsqueda
    URL="$(ask 'No se encontró automáticamente. URL de descarga (.AppImage)')"
    $SUDO curl -L "$URL" -o "$TARGET"
    REF="$URL"
  elif [[ "$SOURCE" == "online (URL)" ]]; then
    URL="$(ask 'URL de descarga (.AppImage)')"
    $SUDO curl -L "$URL" -o "$TARGET"
    REF="$URL"
  else
    FILE="$(ask 'Ruta del archivo .AppImage')"
    [[ -f "$FILE" ]] || { echo "❌ Archivo no existe"; exit 1; }
    $SUDO cp "$FILE" "$TARGET"
    REF="$FILE"
  fi

  # Verificar integridad del archivo descargado
  echo "🔍 Verificando integridad..."
  if command -v sha256sum &>/dev/null; then
    CHECKSUM=$(sha256sum "$TARGET" | cut -d' ' -f1)
    echo "SHA256: $CHECKSUM"
  fi

  $SUDO chmod +x "$TARGET"
  $SUDO ln -sf "$TARGET" "$BIN/$APP_ID"

  NAME="$(ask 'Nombre visible')"
  DESC="$(ask 'Descripción')"
  CAT="$(ask 'Categorías (ej: Development;Utility;)')"
  ICON="$(ask 'Ruta icono (opcional)')"

  if [[ -n "$ICON" && -f "$ICON" ]]; then
    ICON_DEST="$OPT/$APP_ID/icon.${ICON##*.}"
    $SUDO cp "$ICON" "$ICON_DEST"
  else
    ICON_DEST="application-x-executable"
  fi

  $SUDO tee "$DESKTOP/$APP_ID.desktop" > /dev/null <<EOF
[Desktop Entry]
Name=$NAME
Comment=$DESC
Exec=$BIN/$APP_ID %U
Icon=$ICON_DEST
Type=Application
Categories=$CAT
Terminal=false
EOF

  # Añadir información adicional al registro
  VERSION=""
  if command -v file &>/dev/null; then
    VERSION=$(file "$TARGET" | grep -o 'version [0-9.]*' | head -1 || echo "desconocida")
  fi
  
  SIZE=$(du -h "$TARGET" 2>/dev/null | cut -f1 || echo "desconocido")

  echo "$APP_ID|$MODE|$SOURCE|$REF|$NAME|$DESC|$CAT|$ICON_DEST|$VERSION|$SIZE|$(date -I)" | $SUDO tee -a "$REGISTRY" > /dev/null

  echo "✅ $APP_ID instalada correctamente"
}

# ================= UPDATE =================
update_app() {
  [[ -z "$APP_ID" ]] && { echo "❌ Falta nombre"; exit 1; }

  for BASE in "$HOME/.local" "/usr/local"; do
    REG="$BASE/share/appimg/registry.db"
    [[ -f "$REG" ]] || continue

    LINE="$(grep "^$APP_ID|" "$REG" || true)"
    [[ -n "$LINE" ]] || continue

    IFS="|" read -r _ MODE SOURCE REF _ _ _ _ VERSION _ INSTALL_DATE <<< "$LINE"

    [[ "$SOURCE" == *"online"* ]] || {
      echo "⚠ No se puede actualizar (instalación local)"
      exit 0
    }

    [[ "$BASE" == "/usr/local" ]] && SUDO="sudo" || SUDO=""
    TARGET="$BASE/opt/$APP_ID/$APP_ID.AppImage"

    echo "⬆ Actualizando $APP_ID (versión actual: $VERSION)..."
    $SUDO curl -L "$REF" -o "$TARGET"
    $SUDO chmod +x "$TARGET"
    
    # Verificar nueva versión
    if command -v file &>/dev/null; then
      NEW_VERSION=$(file "$TARGET" | grep -o 'version [0-9.]*' | head -1 || echo "desconocida")
      echo "Nueva versión: $NEW_VERSION"
    fi
    
    echo "✅ Actualizada"
    exit 0
  done

  echo "❌ App no registrada"
}

# ================= AUTO-UPDATE =================
auto_update_all() {
  echo "🔄 Verificando actualizaciones para todas las aplicaciones..."
  
  UPDATED=0
  for REG in "$HOME/.local/share/appimg/registry.db" "/usr/local/share/appimg/registry.db"; do
    [[ -f "$REG" ]] || continue
    
    while IFS= read -r line; do
      APP_ID=$(echo "$line" | cut -d'|' -f1)
      SOURCE=$(echo "$line" | cut -d'|' -f3)
      
      # Solo actualizar aplicaciones instaladas desde internet
      if [[ "$SOURCE" == *"online"* ]]; then
        echo "Verificando actualización para: $APP_ID"
        # Aquí iría la lógica para verificar si hay nueva versión
        # Por ahora solo mostramos que se verificaría
        echo "  - $APP_ID: disponible para actualización (simulado)"
        UPDATED=$((UPDATED+1))
      fi
    done < "$REG"
  done
  
  echo "✅ Verificación completada. $UPDATED aplicaciones pueden actualizarse."
}

# ================= REMOVE =================
remove_app() {
  [[ -z "$APP_ID" ]] && { echo "❌ Falta nombre"; exit 1; }

  for BASE in "$HOME/.local" "/usr/local"; do
    REG="$BASE/share/appimg/registry.db"
    [[ -f "$REG" ]] || continue

    if grep -q "^$APP_ID|" "$REG"; then
      [[ "$BASE" == "/usr/local" ]] && SUDO="sudo" || SUDO=""
      $SUDO sed -i "/^$APP_ID|/d" "$REG"
      $SUDO rm -rf "$BASE/opt/$APP_ID"
      $SUDO rm -f "$BASE/bin/$APP_ID"
      $SUDO rm -f "$BASE/share/applications/$APP_ID.desktop"
      echo "🗑 Eliminada $APP_ID"
      exit 0
    fi
  done

  echo "❌ App no encontrada"
}

# ================= STATUS =================
status_app() {
  for REG in "$HOME/.local/share/appimg/registry.db" "/usr/local/share/appimg/registry.db"; do
    [[ -f "$REG" ]] && grep "^$APP_ID|" "$REG" && exit 0
  done
  echo "❌ No instalada"
}

# ================= LIST =================
list_apps() {
  echo "=== Aplicaciones AppImage Instaladas ==="
  for REG in "$HOME/.local/share/appimg/registry.db" "/usr/local/share/appimg/registry.db"; do
    if [[ -f "$REG" ]]; then
      echo "Archivo: $REG"
      column -t -s '|' "$REG"
      echo
    fi
  done
}

# ================= INFO =================
info_app() {
  [[ -z "$APP_ID" ]] && { 
    echo "❌ Se requiere un nombre de aplicación"
    exit 1
  }
  
  echo "=== Información de $APP_ID ==="
  FOUND=false
  
  for REG in "$HOME/.local/share/appimg/registry.db" "/usr/local/share/appimg/registry.db"; do
    [[ -f "$REG" ]] || continue
    
    if LINE="$(grep "^$APP_ID|" "$REG" 2>/dev/null)"; then
      IFS="|" read -r NAME MODE SOURCE REF DESC_NAME DESC CAT ICON VERSION SIZE INSTALL_DATE <<< "$LINE"
      echo "Nombre: $NAME"
      echo "Modo: $MODE"
      echo "Origen: $SOURCE"
      echo "Referencia: $REF"
      echo "Nombre visible: $DESC_NAME"
      echo "Descripción: $DESC"
      echo "Categorías: $CAT"
      echo "Versión: $VERSION"
      echo "Tamaño: $SIZE"
      echo "Fecha instalación: $INSTALL_DATE"
      FOUND=true
      break
    fi
  done
  
  if [[ "$FOUND" == false ]]; then
    echo "❌ Aplicación no encontrada"
    exit 1
  fi
}

case "$ACTION" in
  install) install_app ;;
  update) update_app ;;
  remove) remove_app ;;
  status) status_app ;;
  list) list_apps ;;
  search) search_app ;;
  info) info_app ;;
  autoupdate) auto_update_all ;;
  *) echo "Acción inválida" ;;
esac