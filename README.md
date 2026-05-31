# appimg - Gestor de AppImage

**appimg** es una herramienta de línea de comandos para gestionar aplicaciones AppImage en sistemas Linux. Facilita la instalación, actualización y eliminación de aplicaciones empaquetadas como AppImages.

## Características

- Instalación de AppImages desde repositorios en línea o archivos locales
- Soporte para instalación en modo usuario o sistema
- Registro de aplicaciones instaladas
- Búsqueda automática de aplicaciones en línea
- Verificación de integridad de las AppImages descargadas
- Actualizaciones automáticas

## Instalación

La instalación se puede realizar de dos maneras:

### Método 1: Instalación automática

```bash
curl -s https://raw.githubusercontent.com/bjzr/appimg/main/install.sh | bash
```

### Método 2: Descarga e instalación manual

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/bjzr/appimg.git
   cd appimg
   ```

2. Dar permisos de ejecución:
   ```bash
   chmod +x appimg.sh
   ```

3. (Opcional) Crear enlace simbólico:
   ```bash
   sudo ln -s $(pwd)/appimg.sh /usr/local/bin/appimg
   ```

## Uso

### Instalar una nueva aplicación
```bash
appimg install nombre_app
```
Se le solicitará información sobre:
- Origen (en línea o local)
- Modo de instalación (usuario o sistema)
- URL del archivo AppImage (si es de origen en línea)
- Nombre visible de la aplicación
- Descripción
- Categorías del escritorio

### Comandos disponibles

```bash
# Instalar una aplicación
appimg install nombre_aplicacion

# Actualizar una aplicación
appimg update nombre_aplicacion

# Eliminar una aplicación
appimg remove nombre_aplicacion

# Ver estado de una aplicación
appimg status nombre_aplicacion

# Listar aplicaciones instaladas
appimg list

# Buscar aplicaciones
appimg search término_de_búsqueda

# Ver información de una aplicación
appimg info nombre_aplicacion

# Verificar actualizaciones para todas las aplicaciones
appimg autoupdate
```

## Registro de aplicaciones

Cada AppImage instalada se registra en:
- Instalación de usuario: `~/.local/share/appimg/registry.db`
- Instalación de sistema: `/usr/local/share/appimg/registry.db`

El formato del registro es: `nombre|modo|origen|referencia|nombre_visible|descripcion|categorias|icono|version|tamaño|fecha_instalacion`

## Licencia

MIT