# Fedora Personal Custom Config
- Este repositorio contiene las configuraciones que yo considero buenas y funcionales para mi sistema
- No necesariamente aplicará para todos los equipos, sin embargo, se busca que los cambios que se apliquen puedan ser lo más universales posibles
- Varios de las configuraciones son aplicables a versiones recientes de Fedora

## Requisitos
- Tener Fedora 41 Workstation (usar la versión con GNOME como entorno de escritorio)
- Usar un procesador Intel o AMD reciente (necesario para algunos cambios que se benificien de ello)

## Cambios generales en la interfaz (estéticos)
### Mejorar el renderizado de fuentes pequeñas
- Requerimos de agregar la siguiente variable de entorno, en mi caso lo añadiré al archivo `/etc/environment`
```bash
FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"
```
### Instalar mejores fuentes tipográficas
- Para la interfaz del sistema pueden ser las siguientes:
  - Inter Fonts (probablemente serán las fuentes que Fedora use por defecto en próximos lanzamientos)
  - Inter Variable Fonts
  - Fira Fonts
- En caso de que se quiera instalar cada una de ellas se instalan de la siguiente forma usando el gestor de paquetes DNF
```bash
sudo dnf install rsms-inter-fonts rsms-inter-vf-fonts mozilla-fira-fonts-common
```
- Para la terminal, para editores de texto o para IDEs se puede optar por la siguiente:
  - Fira Code Fonts (trae integradas ligaturas para programación)
    - Esta se instala con DNF de la siguiente forma:
    ```bash
    sudo dnf install fira-code-fonts
    ```
  - También puedes instalar las Nerd Fonts si gustas, incluyen soporte a múltiples símbolos

## Cambios funcionales
- Se activarán los snapshots de BTRFS
  - **En caso de que se haya hecho una instalación por defecto, o en caso de que la instalación haya sido personalizada, pero con BTRFS**
  - Para una mejor gestión se hará la instalación de BTRFS Assistant para mayor interactividad
- Se activará la hibernación
  - Por defecto viene desactivada, se supone que por cuestiones de seguridad, sin embargo, ofrece mucha comodidad, esta es opcional
- Se cambiará el Kernel distribuido por Fedora por el que proporciona CachyOS, que ofrece optimizaciones para procesadores Intel y AMD de recientes generaciones
- Se instalará Cloudflare Warp para acelerar o mejorar las conexiones a internet
- Cambios para Flatpak
  - Se cambia la configuración para Flatpak
    - Se activa en modo usuario
    - Se activan los repositorios de Flathub para instalar aplicaciones desde GNOME Software (la tienda de aplicaciones)
    - Se desactivan los repositorios de Fedora Flatpak, aunque se pueden mantener en caso de que el usuario así lo desee
- Optimizaciones para el gestor de paquetes DNF
  - Aunque actualmente el rendimiento de DNF se ha visto incrementado gracias a la sustitución de la versión hecha con Python por una de C++, aún se pueden hacer algunas cuantas cosas como:
    - Aumentar la cantidad de descargas paralelas
    - Seleccionar el mirror más veloz
- Optimizaciones en el rendimiento seleccionando perfiles de consumo de energía distintos con tuned
- Personalizar la configuración de swap con ZRAM usando el algoritmo de compresión LZ4
