#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
APP_ID="${2:-}"

[[ -z "$ACTION" ]] && {
  echo "Usage: appimg {install|update|remove|status|list} [name]"
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

# ================= INSTALL =================
install_app() {
  [[ -z "$APP_ID" ]] && { echo "❌ Falta nombre"; exit 1; }

  echo "📦 Instalando AppImage: $APP_ID"

  echo "Origen:"
  SOURCE=$(menu "online" "local")

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

  if [[ "$SOURCE" == "online" ]]; then
    URL="$(ask 'URL de descarga (.AppImage)')"
    $SUDO curl -L "$URL" -o "$TARGET"
    REF="$URL"
  else
    FILE="$(ask 'Ruta del archivo .AppImage')"
    [[ -f "$FILE" ]] || { echo "❌ Archivo no existe"; exit 1; }
    $SUDO cp "$FILE" "$TARGET"
    REF="$FILE"
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

  echo "$APP_ID|$MODE|$SOURCE|$REF|$NAME|$DESC|$CAT|$ICON_DEST" | $SUDO tee -a "$REGISTRY" > /dev/null

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

    IFS="|" read -r _ MODE SOURCE REF _ <<< "$LINE"

    [[ "$SOURCE" == "online" ]] || {
      echo "⚠ No se puede actualizar (instalación local)"
      exit 0
    }

    [[ "$BASE" == "/usr/local" ]] && SUDO="sudo" || SUDO=""
    TARGET="$BASE/opt/$APP_ID/$APP_ID.AppImage"

    echo "⬆ Actualizando $APP_ID…"
    $SUDO curl -L "$REF" -o "$TARGET"
    $SUDO chmod +x "$TARGET"
    echo "✅ Actualizada"
    exit 0
  done

  echo "❌ App no registrada"
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
  for REG in "$HOME/.local/share/appimg/registry.db" "/usr/local/share/appimg/registry.db"; do
    [[ -f "$REG" ]] && column -t -s '|' "$REG"
  done
}

case "$ACTION" in
  install) install_app ;;
  update) update_app ;;
  remove) remove_app ;;
  status) status_app ;;
  list) list_apps ;;
  *) echo "Acción inválida" ;;
esac

