#!/bin/bash

# Директория, где находится скрипт
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Загрузка переменных из файла .env
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "Файл .env не найден. Убедитесь, что он находится в директории скрипта."
    exit 1
fi
source "$SCRIPT_DIR/.env"

# Проверка обязательных переменных
REQUIRED_VARS=("SECRET_KEY" "DEBUG" "ALLOWED_HOSTS" "DB_HOST" "DB_PORT" "DB_NAME" "DB_USER" "DB_PASSWORD" "STATIC_ROOT" "MEDIA_ROOT")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Ошибка: Переменная $var не задана в .env."
        exit 1
    fi
done

# Название проекта и сокет Gunicorn
PROJECT_NAME="Bodyexperta"
PROJECT_DIR="/var/www/$PROJECT_NAME"
GUNICORN_SOCKET="/run/$PROJECT_NAME.sock"

# Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
sudo apt install -y python3 python3-pip python3-venv nginx postgresql postgresql-contrib libpq-dev python3-certbot-nginx git

# Настройка PostgreSQL
echo "Настройка базы данных PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "База данных $DB_NAME уже существует."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "Пользователь $DB_USER уже существует."
sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Создание папки проекта
echo "Создание директории проекта..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Переход в папку проекта
cd $PROJECT_DIR

# Клонирование репозитория
echo "Клонирование репозитория..."
git clone https://github.com/fantoaimtrue/$PROJECT_NAME.git . || echo "Репозиторий уже склонирован."

# Создание виртуального окружения
echo "Создание виртуального окружения..."
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей
echo "Установка зависимостей..."
pip install --upgrade pip
pip install -r requirements.txt

# Копирование .env
echo "Копирование .env в директорию проекта..."
cp $SCRIPT_DIR/.env $PROJECT_DIR/

# Применение миграций и сбор статики
echo "Применение миграций и сбор статики..."
python manage.py migrate
python manage.py collectstatic --noinput

# Настройка Gunicorn
echo "Создание systemd-сервиса для Gunicorn..."
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
echo "Создание конфигурации Nginx..."
sudo tee /etc/nginx/sites-available/$PROJECT_NAME > /dev/null <<EOF
server {
    listen 80;
    server_name $ALLOWED_HOSTS;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $STATIC_ROOT;
    }

    location /media/ {
        root $MEDIA_ROOT;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$GUNICORN_SOCKET;
    }
}
EOF

# Активация конфигурации Nginx
sudo ln -s /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Установка HTTPS через Let's Encrypt
echo "Установка сертификатов Let's Encrypt..."
sudo certbot --nginx -d $ALLOWED_HOSTS --non-interactive --agree-tos -m admin@$PROJECT_NAME.ru

# Перезапуск Nginx
echo "Перезапуск Nginx с HTTPS..."
sudo systemctl restart nginx

echo "Развертывание проекта завершено!"
