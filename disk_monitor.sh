#Дополнительная задача EXTRA скрипт (BASE). Мониторинг свободного места на сервере и отправка уведомлений

# РЕШЕНИЕ

# Настройки  и внесения необходимых сведений
REMOTE_SERVER="user@remote_server_ip"  # Укажите удалённый сервер
DISK_PATH="/"                          # Укажите путь к диску для проверки
THRESHOLD=20                           # Порог свободного места в процентах
EMAIL="your_email@example.com"         # Адрес для уведомлений
LOG_FILE="/var/log/disk_monitor.log"   # Путь к файлу логов

# Логирование
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a $LOG_FILE
}

# Проверка соединения с сервером
log_message "Проверка соединения с сервером $REMOTE_SERVER..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 $REMOTE_SERVER "echo 2>&1" >/dev/null; then
    log_message "Ошибка: невозможно подключиться к серверу $REMOTE_SERVER."
    exit 1
fi

# Получение свободного места на диске
log_message "Получение информации о свободном месте на диске $DISK_PATH..."
FREE_SPACE=$(ssh $REMOTE_SERVER "df -h $DISK_PATH | awk 'NR==2 {print \$5}' | sed 's/%//'")
if [[ -z "$FREE_SPACE" ]]; then
    log_message "Ошибка: не удалось получить данные о свободном месте."
    exit 1
fi
log_message "Свободное место на диске: $FREE_SPACE%"

# Сравнение с пороговым значением
if (( FREE_SPACE > 100 - THRESHOLD )); then
    log_message "ВНИМАНИЕ: свободное место ниже порогового значения ($THRESHOLD%)."
    # Отправка уведомления по email
    log_message "Отправка уведомления на $EMAIL..."
    mail -s "Оповещение: низкое свободное место на диске $REMOTE_SERVER" $EMAIL <<EOF
На сервере $REMOTE_SERVER свободное место на диске $DISK_PATH составляет $((100 - FREE_SPACE))%.
Это ниже установленного порога $THRESHOLD%.
Примите необходимые меры!
EOF

else
    log_message "Свободное место в норме."
fi

# Финальный отчёт
log_message "Мониторинг завершён."

