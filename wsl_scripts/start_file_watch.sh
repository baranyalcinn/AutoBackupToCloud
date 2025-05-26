#!/bin/bash

# Değişkenler
SCRIPT_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/wsl_scripts"
WATCH_SCRIPT="${SCRIPT_DIR}/watch_data.sh"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
LOG_FILE="${LOG_DIR}/watch_startup_log_$(date +"%Y-%m-%d-%H-%M").txt"
PID_FILE="/tmp/file_watch.pid"

# Log dizini yoksa oluştur
mkdir -p "$LOG_DIR"

# Log fonksiyonu
log_message() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} - $1" | tee -a "$LOG_FILE"
}

# Betik çalışma izni ver
chmod +x "$WATCH_SCRIPT" "$(basename "$0")"

# Zaten çalışıyor mu kontrol et
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p "$PID" > /dev/null; then
    log_message "İzleme betiği zaten çalışıyor (PID: $PID). Önce durdurun."
    echo "İzleme betiği zaten çalışıyor (PID: $PID). Durdurmak için: kill $PID"
    exit 1
  else
    log_message "Önceki PID dosyası bulundu ama süreç çalışmıyor. Temizleniyor."
    rm -f "$PID_FILE"
  fi
fi

log_message "Dosya izleme betiği başlatılıyor..."

# İzleme betiğini arkaplanda başlat
nohup bash "$WATCH_SCRIPT" > "${LOG_DIR}/watch_output.log" 2>&1 &
WATCH_PID=$!

# PID'i kaydet
echo $WATCH_PID > "$PID_FILE"

log_message "Dosya izleme betiği başlatıldı (PID: $WATCH_PID)"
echo "Dosya izleme betiği başlatıldı (PID: $WATCH_PID)"
echo "Log dosyası: ${LOG_DIR}/watch_output.log"
echo "Durdurmak için: kill $WATCH_PID" 