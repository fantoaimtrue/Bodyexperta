#!/bin/bash

# Директория, где находится скрипт
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
sudo apt install -y python3 python3-pip python3-venv nginx postgresql postgresql-contrib libpq-dev python3-certbot-nginx git

# Переменные
PROJECT_NAME="Bodyexprta"       # Название проекта
PROJECT_DIR="/var/www/$PROJECT_NAME"   # Путь к проекту
GUNICORN_SOCKET="/run/$PROJECT_NAME.sock"
DOMAIN="bodycosm.ru"                   # Твой домен
EMAIL="a.a.andre9nov@gmail.com"         # Email для Let's Encrypt
ENV_FILE="$SCRIPT_DIR/.env"            # Путь к .env файлу
DB_NAME="bodyexperta"                  # Имя базы данных
DB_USER="fantoaimtrue"                # Имя пользователя базы данных
DB_PASSWORD=$(openssl rand -base64 12) # Случайный пароль для базы данных
DB_HOST="localhost"
DB_PORT="5432"

# Генерация значений для .env
echo "Создание .env файла..."
SECRET_KEY=$(openssl rand -base64 32)
DEBUG="False"
ALLOWED_HOSTS="$DOMAIN www.$DOMAIN"

cat <<EOF > $ENV_FILE
SECRET_KEY=$SECRET_KEY
DEBUG=$DEBUG
ALLOWED_HOSTS=$ALLOWED_HOSTS
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME
EOF

# Создание папки проекта
echo "Создание папки проекта..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Переход в папку проекта
cd $PROJECT_DIR

# Клонирование репозитория (замени на свой URL)
echo "Клонирование репозитория..."
git clone https://github.com/fantoaimtrue/Bodyexperta.git .

# Настройка PostgreSQL
echo "Настройка PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Создание виртуального окружения
echo "Создание виртуального окружения..."
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей
echo "Установка зависимостей..."
pip install --upgrade pip
pip install -r requirements.txt

# Копирование .env в директорию проекта
echo "Копирование .env в директорию проекта..."
cp $ENV_FILE $PROJECT_DIR/

# Применение миграций и сбор статики
echo "Применение миграций и сбор статики..."
python manage.py migrate
python manage.py collectstatic --noinput

# Создание systemd-сервиса для Gunicorn
echo "Настройка Gunicorn..."
sudo tee /etc/systemd/system/$PROJECT_NAME.service > /dev/null <<EOF
[Unit]
Description=Gunicorn instance to serve $PROJECT_NAME
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind unix:$GUNICORN_SOCKET $PROJECT_NAME.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Запуск и включение Gunicorn
echo "Запуск и включение Gunicorn..."
sudo systemctl start $PROJECT_NAME
sudo systemctl enable $PROJECT_NAME

# Настройка Nginx
echo "Настройка Nginx..."
sudo tee /etc/nginx/sites-available/$PROJECT_NAME > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $PROJECT_DIR;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$GUNICORN_SOCKET;
    }
}

server {
    listen 443 ssl; # Слушать на порту 443 с использованием SSL
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem; # Путь к сертификату SSL
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem; # Путь к закрытому ключу SSL

    location = /favicon.ico {
access_log off; log_not_found off; }
    location /static/ {
        root $PROJECT_DIR;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$GUNICORN_SOCKET;
    }
}
EOF

# Активация конфигурации Nginx
sudo ln -s /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Установка HTTPS через Let's Encrypt
echo "Настройка HTTPS через Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL

# Перенаправление HTTP на HTTPS
echo "Перенаправление HTTP на HTTPS..."
sudo tee /etc/nginx/sites-available/$PROJECT_NAME > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl; # Слушать на порту 443 с использованием SSL
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem; # Путь к сертификату SSL
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem; # Путь к закрытому ключу SSL

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $PROJECT_DIR;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$GUNICORN_SOCKET;
    }
}
EOF

# Активация конфигурации Nginx
sudo ln -s /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
