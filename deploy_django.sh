#!/bin/bash

# Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
sudo apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git

# Переменные
PROJECT_NAME="Bodyexperta"       # Название проекта
PROJECT_DIR="/var/www/$PROJECT_NAME"   # Путь к проекту
GUNICORN_SOCKET="/run/$PROJECT_NAME.sock"
DOMAIN="bodycosm.ru"                   # Твой домен
EMAIL="a.a.andre9nov@gmail.com"         # Твой email для Let's Encrypt

# Создание папки проекта
echo "Создание папки проекта..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Переход в папку проекта
cd $PROJECT_DIR

# Клонирование репозитория (замени на свой URL)
echo "Клонирование репозитория..."
git clone https://github.com/your-repo-url.git .

# Создание виртуального окружения
echo "Создание виртуального окружения..."
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей
echo "Установка зависимостей..."
pip install --upgrade pip
pip install -r requirements.txt

# Выполнение миграций и сбор статики
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
EOF

# Активация конфигурации Nginx
sudo ln -s /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Установка HTTPS через Let's Encrypt
echo "Настройка HTTPS через Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL

# Проверка автоматического обновления сертификатов
echo "Проверка автоматического обновления сертификатов..."
sudo certbot renew --dry-run

# Финализация
echo "Развертывание завершено!"
echo "Проект доступен по адресу: https://$DOMAIN"
