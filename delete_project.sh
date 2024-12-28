#!/bin/bash

# Имя проекта
PROJECT_NAME="Bodyexprta"
PROJECT_DIR="/var/www/$PROJECT_NAME"
GUNICORN_SOCKET="/run/$PROJECT_NAME.sock"
NGINX_CONFIG="/etc/nginx/sites-available/$PROJECT_NAME"
NGINX_SYMLINK="/etc/nginx/sites-enabled/$PROJECT_NAME"
SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"

# Остановка и отключение сервиса
echo "Остановка и отключение systemd-сервиса..."
sudo systemctl stop $PROJECT_NAME || echo "Сервис $PROJECT_NAME не запущен."
sudo systemctl disable $PROJECT_NAME || echo "Сервис $PROJECT_NAME не был включен."

# Удаление systemd-сервиса
if [ -f "$SERVICE_FILE" ]; then
    echo "Удаление systemd-сервиса..."
    sudo rm "$SERVICE_FILE"
else
    echo "Файл systemd-сервиса $SERVICE_FILE не найден."
fi

# Перезагрузка systemd
echo "Перезагрузка конфигурации systemd..."
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Удаление Gunicorn сокета
if [ -S "$GUNICORN_SOCKET" ]; then
    echo "Удаление Gunicorn сокета..."
    sudo rm "$GUNICORN_SOCKET"
else
    echo "Сокет $GUNICORN_SOCKET не найден."
fi

# Удаление конфигурации Nginx
if [ -f "$NGINX_CONFIG" ]; then
    echo "Удаление конфигурации Nginx..."
    sudo rm "$NGINX_CONFIG"
else
    echo "Файл конфигурации Nginx $NGINX_CONFIG не найден."
fi

if [ -f "$NGINX_SYMLINK" ]; then
    echo "Удаление символической ссылки конфигурации Nginx..."
    sudo rm "$NGINX_SYMLINK"
else
    echo "Символическая ссылка конфигурации Nginx $NGINX_SYMLINK не найдена."
fi

# Проверка конфигурации Nginx
echo "Перезагрузка Nginx..."
sudo nginx -t && sudo systemctl restart nginx || echo "Ошибка перезагрузки Nginx."

# Удаление директории проекта
if [ -d "$PROJECT_DIR" ]; then
    echo "Удаление директории проекта..."
    sudo rm -rf "$PROJECT_DIR"
else
    echo "Директория проекта $PROJECT_DIR не найдена."
fi

echo "Удаление завершено!"
