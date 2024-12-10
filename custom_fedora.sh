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
    echo "4) Optimizar imagen de arranque con Dracut"
    echo "5) Configurar BTRFS y herramientas"
    echo "6) Configurar entorno gráfico"
    echo "7) Instalar fuentes y utilidades"
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
                echo "
max_parallel_downloads=15
fastestmirror=True" >> /etc/dnf/dnf.conf
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
battery_detection=false

[profiles]
power-saver=powersave
balanced=balanced
performance=throughput-performance

[battery]
balanced=balanced-battery
EOF
                print_message "TuneD ha sido configurado"
            fi
            ;;
        4)
            print_message "Optimizando la imagen de arranque con cambios a Dracut..."
            if confirm_action; then
	    print_message "Se va a instalar lz4"
	    dnf install lz4 -y
                cat << EOF > /etc/dracut.conf.d/custom.conf
add_dracutmodules+=" systemd "
compress="lz4"
EOF
                dracut -f
                print_message "Se han hecho cambios a la configuración de dracut"
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
                print_message "Se van a activar los repositorios de terra (Ultramarine) para mayor cantidad de software disponible"
                dnf install --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' --setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' terra-release
                dnf --refresh makecache

                print_message "¿Desea instalar fish o quedarse con Bash como shell del sistema?"
                echo "1) Instalar fish"
                echo "2) Dejar bash"

                read -p "Seleccione una opción: " shell_inst
                case $shell_inst in
                    1)  dnf install fish -y
                        chsh -s /usr/bin/fish
                        ;;
                    2) ;;
                    *) print_message "Opción inválida" ;;
                esac

                dnf install -y rsms-inter-fonts rsms-inter-vf-fonts mozilla-fira-fonts-common fastfetch curl
                print_message "Se va a instalar Cloudflare Warp y se registrará. ¿Está de acuerdo?"

                if confirm_action; then
                    curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo
                    dnf install -y cloudflare-warp
                    systemctl enable --now warp-svc
                    warp-cli registration new
                    warp-cli mode warp+doh
                    warp-cli connect
                fi

                # Repo para sbctl y hacer firmas para SecureBoot
                #dnf copr enable chenxiaolong/sbctl

                print_message "¿Desea instalar el kernel de CachyOS para mejor rendimiento"
                if confirm_action; then
                    # Repo para el kernel y complementos de CachyOS
                    dnf copr enable bieszczaders/kernel-cachyos
                    dnf copr enable bieszczaders/kernel-cachyos-addons
                    #print_message "Instalando sbctl"
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
                fi

                print_message "¿Desea instalar utilidades para configurar GNOME?"
                if confirm_action; then
                    dnf install -y gnome-tweaks dconf-editor
                fi

                print_message "¿Desea instalar las mejoras al renderizado de fuentes?"
                if confirm_action; then
                    echo "FREETYPE_PROPERTIES=\"cff:no-stem-darkening=0 autofitter:no-stem-darkening=0\"" > /etc/environment
                fi

                print_message "Fuentes y utilidades instaladas"
            fi
            ;;
        8)
            print_message "Instalando Distrobox..."
            if confirm_action; then
                print_message "¿Prefiere Docker o Podman para contenedores?"
                echo "1) Docker"
                echo "2) Podman"

                read -p "Ingrese su elección: " cont
                case $cont in
                    1) dnf remove podman
                        dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo --overwrite;
                        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                        systemctl enable --now docker containerd
                        #groupadd docker
                        usermod -aG docker $SUDO_USER
                        #newgrp docker #Para activar los cambios sin reiniciar
                        print_message "Se recomienda reiniciar después de instalar Docker"
                        ;;
                    2) ;;   #No se hace nada, porque Fedora tiene podman preinstalado
                    *) print_message "Opción inválida";;
                esac
                dnf5 install -y distrobox
                print_message "Distrobox ha sido instalado"
            fi;;
        9)
            print_message "Configurando ZRAM..."
            if confirm_action; then
                cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size=ram
compression-algorithm=lz4
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
		        cp systemd/hibernate-* /etc/systemd/system/
		        mkdir -p /etc/systemd/system/systemd-hibernate.service.d/ /etc/systemd/system/systemd-logind.service.d/
                cp systemd/systemd-hibernate.service.d/override.conf /etc/systemd/system/systemd-hibernate.service.d/
                cp systemd/systemd-logind.service.d/override.conf /etc/systemd/system/systemd-logind.service.d/
                systemctl enable hibernate-preparation.service hibernate-resume.service
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
	       print_message "¿Eliminar los repositorios de Fedora Flatpak?"
	       if confirm_action; then
	           flatpak remote-delete fedora
		   print_message "Se han eliminado los repositorios de Fedora Flatpak"
	       fi
	       print_message "¿Desea agregar los repositorios de Flathub en modo usuario o dejarlos como están (en caso de haber activado los repositorios de terceros tras la primer ejecución)?"
	       if confirm_action; then
	           flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
		   print_message "Si tenía activado Flathub en modo system instalado, ¿desea eliminarlo?"
		   if confirm_action; then
	               flatpak remote-delete flathub --system
		   fi
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

