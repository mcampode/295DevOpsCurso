#!/bin/bash

# Variables
REPO="bootcamp-devops-2023"
BRANCH="clase2-linux-bash"
USERID=$(id -u)
LBLUE='\033[1;34m'
LYELLOW='\033[1;33m'
LRED='\033[1;31m'
NC='\033[0m'       # Text Reset. Para que las líneas siguientes no se queden con el mismo color

echo -e "\n${LBLUE}### Desafio 1 - Automatizacion de despliegue de aplicación e-commerce ###${NC}"

# Comprobando root
if [ "${USERID}" -ne 0 ];
then
    echo -e "\n${LYELLOW}Corriento como root${NC}"
else  
    echo -e "\n${LYELLOW}Ejecutar script como root${NC}"
fi

# Actualizar servidor
echo -e "\n${LYELLOW}Actualizando servidor${NC}"
apt-get update

# MariaDB
if dpkg -l | grep -q mariadb ;
then
    echo -e "\n${LYELLOW}MariaDB instalado${NC}"
else
    echo "\n${LYELLOW}Instalando MariaDB${NC}"
    apt install -y mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
    systemctl status mariadb
fi

# Configuración de DB
echo -e "\n${LYELLOW}Configuración de Base de Datos${NC}"
mysql -e "
CREATE DATABASE ecomdb; 
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;"

# Agregando datos al Data Base mediante un script creado
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

# Ejecutar el script creado
mysql < db-load-script.sql

# Despliegue y configuracion de pagina Web

# Apache
if dpkg -l | grep -q apache2 ;
then
    echo -e "\n${LYELLOW}Apache2 instalado${NC}"
else
    echo "\n${LYELLOW}Instalando Apache2${NC}"
    apt install apache2 -y
    apt install -y php libapache2-mod-php php-mysql
    systemctl start apache2 
    systemctl enable apache2
fi

# Backup index.html
mv /var/www/html/index.html /var/www/html/index.html.bkp

# Instalando web
if [ -d "$REPO" ];
then
    echo -e "\n${LYELLOW}El directorio $REPO existe${NC}"
    rm -rf $REPO    
fi

if dpkg -l | grep -q git ;
then
    echo -e "\n${LYELLOW}Git instalado${NC}"
else
    echo -e "\n${LYELLOW}Instalando Git${NC}"
    apt install git -y
fi

echo -e "\n${LYELLOW}Instalando web${NC}"
sleep 1
git clone -b $BRANCH https://github.com/roxsross/$REPO.git
cp -r $REPO/app-ecommerce/* /var/www/html/

# Actualizacion de index.php
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
echo -e "\n${LBLUE}===========================================================${NC}"

# Reincio del servicio
systemctl reload apache2