#!/usr/bin/bash
echo "Ejecutando con permisos de superadministrador"

#Añadir parámetros para acelerar dnf
cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=15
fastestmirror=True
EOF

#Verificar si dnf5 está instalado en Fedora
rpm -q dnf5

#Si no lo está entonces se instala con
dnf install dnf5

#Modificar los valores de TuneD para una gestión energética y de rendimiento óptima
cat << EOF > /etc/tuned/ppd.conf
[main]
# The default PPD profile
default=balanced
battery_detection=true

[profiles]
# PPD = TuneD
power-saver=powersave
balanced=balanced-battery
performance=accelerator-performance

[battery]
# PPD = TuneD
balanced=balanced-battery
EOF

#Instalar el escritorio GNOME en caso de que no estuviese instalado
dnf5 install @gnome-desktop

#Instalar las herramientas para usar btrfs y sus copias de seguridad
dnf5 install btrfs-assistant

#Crear subvolúmenes de BTRFS para un mejor manejo de snapshots

systemctl set-default multi-user.target	#Enable the multi-user target for the GDM
systemctl set-default graphical.target	#Enable the graphical target to make GDM start in Fedora Server or Fedora Custom

#Instalar las tipografías Inter para una mejor vista
dnf5 install rsms-inter-fonts

#Instalar fastfetch
dnf5 install fastfetch

#Instalar distrobox (podman viene incluido para los contenedores)
dnf5 install distrobox

#Cambiar los parámetros sysctl para el manejo de memoria en ZRAM
cat << EOF > /etc/sysctl.d/99-vm-zram.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

# Habilitar hibernación para systemd
cat << EOF > /etc/systemcd/sleep.conf
[Sleep]
AllowHibernation=yes
HibernateMode=shutdown
EOF

# Se necesita crear un archivo 'swapfile' si es que no se tiene una partición
# Se tiene que obtener el UUID del mismo
blkid | grep swap | cut -d: -f1
# Se tiene que obtener el offset en caso de que sea con un swapfile

# Una vez obtenidos los valores se necesita colocar esos valores como comandos (argumentos) para el kernel (ya sea que se use systemd-boot o GRUB)


# También se necesita añadir el módulo 'resume' para el initramfs en Fedora se hace con añadiendo ese argumento en un archivo ya sea dentro de /etc/dracut.conf o en /etc/dracut.conf.d/archivo.conf
cat << EOF > /etc/dracut.conf.d/resume.conf
add_dracutmodules+=" resume "
EOF

#Forzar la regeneración de initramfs
dracut -f

#Cambiar los valores de ZRAM en zram-generator.conf
cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size=ram/2
compression-algorithm=zstd
swap-priority=200
EOF

#Reiniciar el servicio de ZRAM
systemctl restart systemd-zram-setup@zram0.service


#Añadir el repositorio flathub para flatpak, pero en modo usuario
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo

#Instalar las aplicaciones de Flatpak que se deseen
flatpak install ...
