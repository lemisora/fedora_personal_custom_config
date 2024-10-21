#!/usr/bin/bash

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_message() {
    echo -e "${BLUE}==> ${1}${NC}"
}

# Función para solicitar confirmación
confirm_action() {
    while true; do
        read -p "¿Desea continuar con esta acción? (s/n): " yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor, responda con 's' o 'n'.";;
        esac
    done
}

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script debe ejecutarse como root${NC}"
    exit 1
fi

print_message "Bienvenido al script de configuración personalizada de Fedora"

# Menú principal
while true; do
    echo -e "\n${GREEN}Seleccione una opción:${NC}"
    echo "1) Optimizar DNF"
    echo "2) Instalar y configurar DNF5"
    echo "3) Configurar TuneD"
    echo "4) Instalar GNOME Desktop"
    echo "5) Configurar BTRFS y herramientas"
    echo "6) Configurar entorno gráfico"
    echo "7) Instalar fuentes y utilidades (Inter, fastfetch)"
    echo "8) Instalar y configurar Distrobox"
    echo "9) Configurar ZRAM y memoria"
    echo "10) Configurar hibernación"
    echo "11) Configurar Flatpak"
    echo "0) Salir"

    read -p "Ingrese su opción: " opcion

    case $opcion in
        1)
            print_message "Optimizando DNF..."
            if confirm_action; then
                cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=15
fastestmirror=True
EOF
                print_message "DNF ha sido optimizado"
            fi
            ;;
        2)
            print_message "Verificando DNF5..."
            if ! rpm -q dnf5 &>/dev/null; then
                if confirm_action; then
                    dnf install -y dnf5
                    print_message "DNF5 ha sido instalado"
                fi
            else
                print_message "DNF5 ya está instalado"
            fi
            ;;
        3)
            print_message "Configurando TuneD..."
            if confirm_action; then
                cat << EOF > /etc/tuned/ppd.conf
[main]
default=balanced
battery_detection=true

[profiles]
power-saver=powersave
balanced=balanced-battery
performance=accelerator-performance

[battery]
balanced=balanced-battery
EOF
                print_message "TuneD ha sido configurado"
            fi
            ;;
        4)
            print_message "Instalando GNOME Desktop..."
            if confirm_action; then
                dnf5 install -y @gnome-desktop
                print_message "GNOME Desktop ha sido instalado"
            fi
            ;;
        5)
            print_message "Configurando BTRFS..."
            if confirm_action; then
                dnf5 install -y btrfs-assistant
                print_message "Herramientas BTRFS instaladas"
                # Se asumirá que se tienen ya creados los volumenes @home, @ y @snapshots
                # Aquí podrías añadir más opciones para configurar subvolúmenes
            fi
            ;;
        6)
            print_message "Configurando entorno gráfico..."
            echo "1) Activar modo multi-usuario"
            echo "2) Activar modo gráfico"
            read -p "Seleccione el modo: " modo
            case $modo in
                1) systemctl set-default multi-user.target ;;
                2) systemctl set-default graphical.target ;;
                *) print_message "Opción no válida" ;;
            esac
            ;;
        7)
            print_message "Instalando fuentes y utilidades..."
            if confirm_action; then
                #Añadir repositorio de terra
                dnf install --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' --setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' terra-release
                dnf install -y rsms-inter-fonts fastfetch curl
                curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo
                dnf install -y cloudflare-warp
                systemctl enable --now warp-svc
                warp-cli registration new
                warp-cli mode warp+doh
                warp-cli connect
                # Repo para sbctl y hacer firmas para SecureBoot
                dnf copr enable chenxiaolong/sbctl
                # Repo para el kernel y complementos de CachyOS
                dnf copr enable bieszczaders/kernel-cachyos
                dnf copr enable bieszczaders/kernel-cachyos-addons
                print_message "Instalando sbctl"
                dnf install -y sbctl
                setsebool -P domain_kernel_load_modules on # Para poder cargar módulos del kernel de CachyOS si está SELinux activo
                dnf install -y kernel-cachyos kernel-cachyos-devel-matched
                dnf install -y libcap-ng libcap-ng-devel procps-ng procps-ng-devel # Componentes necesarios para complementos
                dnf install -y uksmd
                systemctl enable --now uksmd.service
                print_message "¿Quiere instalar la versión git de scx-scheds?"
                echo "1) Sí"
                echo "2) No, quiero instalar la versión estable"
                read -p "Ingrese su elección: " elect
                case $elect in
                    1) dnf install -y scx-scheds-git;;
                    2) dnf install -y scx-scheds;;
                    *) print_message "Opción inválida";;
                esac
                systemctl enable --now scx.service
                print_message "Fuentes y utilidades instaladas"
            fi
            ;;
        8)
            print_message "Instalando Distrobox..."
            if confirm_action; then
                dnf5 install -y distrobox
                print_message "Distrobox ha sido instalado"
            fi
            ;;
        9)
            print_message "Configurando ZRAM y memoria..."
            if confirm_action; then
                cat << EOF > /etc/sysctl.d/99-vm-zram.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF
                cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size=ram
compression-algorithm=zstd
swap-priority=200
EOF
                systemctl restart systemd-zram-setup@zram0.service
                print_message "ZRAM configurado"
            fi
            ;;
        10)
            print_message "Configurando hibernación..."
            if confirm_action; then
                cat << EOF > /etc/systemd/sleep.conf
[Sleep]
AllowHibernation=yes
HibernateMode=shutdown
EOF

                cp systemd/systemd-hibernate.service.d/override.conf /etc/system/
                cp systemd/systemd-logind.service.d/override.conf /etc/system/
                cat << EOF > /etc/dracut.conf.d/resume.conf
add_dracutmodules+=" resume "
EOF
                dracut -f
                print_message "Hibernación configurada"
            fi
            ;;
        11)
            print_message "Configurando Flatpak..."
            if confirm_action; then
                flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
                print_message "¿Desea instalar algunas aplicaciones comunes de Flatpak?"
                if confirm_action; then
                    # Aquí podrías añadir un menú de aplicaciones populares
                    while read -r app; do
                        if [[ ! -z "$app" ]]; then
                            echo "Instalando $app..."
                            flatpak install flathub --assumeyes "$app"
                            if [[ $? -eq 0 ]]; then
                                echo "$app se ha instalado correctamente"
                            else
                                echo "$app no se pudo instalar correctamente"
                            fi
                        fi
                    done < apps.txt
                    print_message "Se han instalado todas las aplicaciones"
                fi
            fi
            ;;
        0)
            print_message "Saliendo del script..."
            exit 0
            ;;
        *)
            print_message "Opción no válida"
            ;;
    esac
done
