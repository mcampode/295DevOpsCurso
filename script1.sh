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


##################################################################################################


# Notificacion a Discord
echo "\n${LBLUE} Notificacion a Discord ${NC}"

# Configura el token de acceso de tu bot de Discord
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"
MIREPO="295DevOpsCurso"
MIBRANCH="tarea1"

# Verifica si se proporcionó el argumento del directorio del repositorio
if [ -d $MIREPO ]; then
  echo "Uso del repo https://github.com/mcampode/$MIREPO.git"
else 
  git clone -b $MIBRANCH https://github.com/mcampode/$MIREPO.git
fi

# Cambia al directorio del repositorio
cd $MIREPO

# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="localhost"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio


# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"
