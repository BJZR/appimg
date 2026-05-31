# appimg - Gestor de AppImage

Herramienta para gestionar aplicaciones AppImage en Linux.

## Características

- Instalación de AppImages desde repositorios en línea o archivos locales
- Soporte para instalación en modo usuario o sistema
- Registro de aplicaciones instaladas
- Búsqueda de aplicaciones
- Verificación de integridad
- Actualizaciones automáticas

## Instalación

```bash
curl -s https://raw.githubusercontent.com/bjzr/appimg/main/install.sh | bash
```

## Uso

```bash
# Listar aplicaciones instaladas
appimg list

# Instalar una nueva aplicación
appimg install nombre_app

# Buscar aplicaciones disponibles
appimg search término_de_búsqueda

# Ver información detallada de una aplicación
appimg info nombre_app
```

## Licencia

MIT