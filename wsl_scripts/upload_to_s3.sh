#!/bin/bash

# Değişkenler
BACKUP_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/backup_system"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
S3_BUCKET="my-backup-bucket"
S3_PREFIX="backups/"
DATE=$(date +"%Y-%m-%d-%H-%M")
LOG_FILE="${LOG_DIR}/s3_upload_log_${DATE}.txt"

# Log dizini yoksa oluştur
mkdir -p "$LOG_DIR"

# Log fonksiyonu
log_message() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} - $1" | tee -a "$LOG_FILE"
}

# Yedekleme dizini kontrol et
if [ ! -d "$BACKUP_DIR" ]; then
  log_message "HATA: Yedekleme dizini bulunamadı: $BACKUP_DIR"
  exit 1
fi

# AWS CLI kontrol et
if ! command -v aws &> /dev/null; then
  log_message "HATA: AWS CLI bulunamadı. Lütfen yükleyin: sudo apt install awscli"
  exit 1
fi

# En son yedek dosyasını bul
LATEST_BACKUP=$(find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)

if [ -z "$LATEST_BACKUP" ]; then
  log_message "HATA: Yedekleme dizininde yedek dosyası bulunamadı."
  exit 1
fi

BACKUP_FILENAME=$(basename "$LATEST_BACKUP")
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}${BACKUP_FILENAME}"

log_message "Yükleme başlatılıyor: $LATEST_BACKUP -> $S3_PATH"

# AWS S3'e yükle
aws s3 cp "$LATEST_BACKUP" "$S3_PATH"

if [ $? -eq 0 ]; then
  log_message "Yükleme başarıyla tamamlandı: $S3_PATH"
else
  log_message "HATA: Yükleme başarısız oldu."
  exit 1
fi

log_message "S3 yükleme işlemi tamamlandı." 