#!/bin/bash

# Değişkenler
SOURCE_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/data"
BACKUP_SCRIPT="/mnt/c/Users/recte/Desktop/SystemManagement/wsl_scripts/backup.sh"
GDRIVE_SCRIPT="/mnt/c/Users/recte/Desktop/SystemManagement/wsl_scripts/upload_to_gdrive.sh"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
LOG_FILE="${LOG_DIR}/file_watch_log.txt"

# Log dizini yoksa oluştur
mkdir -p "$LOG_DIR"

# Log fonksiyonu
log_message() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} - $1" | tee -a "$LOG_FILE"
}

# İzleme işlevini başlat
log_message "Dosya izleme başlatılıyor: $SOURCE_DIR"

# inotify-tools kurulu mu kontrol et
if ! command -v inotifywait &> /dev/null; then
  log_message "HATA: inotifywait komutu bulunamadı. Lütfen yükleyin: sudo apt install inotify-tools"
  exit 1
fi

# Son yedekleme zamanını izle (çok sık yedekleme yapmamak için)
LAST_BACKUP_TIME=0
COOLDOWN_PERIOD=300 # 5 dakika (saniye cinsinden)

# Dosya değişikliklerini izle
inotifywait -m -r -e modify,create,delete,move "$SOURCE_DIR" --format "%w%f %e" | while read FILE EVENT; do
  CURRENT_TIME=$(date +%s)
  
  # Son yedeklemeden beri yeteri kadar zaman geçti mi?
  if [ $((CURRENT_TIME - LAST_BACKUP_TIME)) -gt $COOLDOWN_PERIOD ]; then
    log_message "Değişiklik algılandı: $FILE ($EVENT)"
    log_message "Yedekleme başlatılıyor..."
    
    # Yedekleme betiğini çalıştır
    bash "$BACKUP_SCRIPT"
    
    if [ $? -eq 0 ]; then
      log_message "Yedekleme tamamlandı."
      
      # Google Drive'a yükleme
      log_message "Google Drive'a yükleme başlatılıyor..."
      bash "$GDRIVE_SCRIPT"
      
      if [ $? -eq 0 ]; then
        log_message "Google Drive'a yükleme tamamlandı."
      else
        log_message "HATA: Google Drive'a yükleme başarısız oldu."
      fi
    else
      log_message "HATA: Yedekleme başarısız oldu."
    fi
    
    # Son yedekleme zamanını güncelle
    LAST_BACKUP_TIME=$CURRENT_TIME
  else
    log_message "Değişiklik algılandı: $FILE ($EVENT) - Yedekleme için soğuma süresi bekleniyor (son yedeklemeden $((CURRENT_TIME - LAST_BACKUP_TIME)) saniye geçti, $COOLDOWN_PERIOD saniye bekleniyor)"
  fi
done 