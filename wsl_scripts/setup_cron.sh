#!/bin/bash

# Değişkenler
SCRIPT_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/wsl_scripts"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"
S3_UPLOAD_SCRIPT="${SCRIPT_DIR}/upload_to_s3.sh"
GDRIVE_UPLOAD_SCRIPT="${SCRIPT_DIR}/upload_to_gdrive.sh"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
CRON_LOG="${LOG_DIR}/cron_setup_$(date +"%Y-%m-%d-%H-%M").log"

# Log dizini yoksa oluştur
mkdir -p "$LOG_DIR"

# Log fonksiyonu
log_message() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} - $1" | tee -a "$CRON_LOG"
}

# Betik çalışma izni ver
chmod +x "$BACKUP_SCRIPT" "$S3_UPLOAD_SCRIPT" "$GDRIVE_UPLOAD_SCRIPT" "$(basename "$0")"

log_message "Cron ayarları yapılandırılıyor..."

# Cron kullanılabilir mi kontrol et
if ! command -v crontab &> /dev/null; then
  log_message "HATA: crontab komutu bulunamadı. Lütfen cron yükleyin: sudo apt install cron"
  exit 1
fi

# Günlük yedekleme görevi (her gün gece 01:00'de)
DAILY_BACKUP_CRON="0 1 * * * $BACKUP_SCRIPT >> ${LOG_DIR}/daily_backup_cron.log 2>&1"
# Günlük S3 yükleme görevi (gece 01:30'da)
DAILY_S3_CRON="30 1 * * * $S3_UPLOAD_SCRIPT >> ${LOG_DIR}/daily_s3_cron.log 2>&1"
# Günlük Google Drive yükleme görevi (gece 02:00'de)
DAILY_GDRIVE_CRON="0 2 * * * $GDRIVE_UPLOAD_SCRIPT >> ${LOG_DIR}/daily_gdrive_cron.log 2>&1"

# Mevcut cron görevlerini al
CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")

# Yedekleme ve yükleme görevleri eklenmiş mi kontrol et
if echo "$CURRENT_CRONTAB" | grep -q "$BACKUP_SCRIPT"; then
  log_message "Yedekleme görevi zaten mevcut."
else
  NEW_CRONTAB="${CURRENT_CRONTAB}${CURRENT_CRONTAB:+$'\n'}# Günlük otomatik yedekleme - her gün 01:00'de çalışır$'\n'${DAILY_BACKUP_CRON}"
  echo "$NEW_CRONTAB" | crontab -
  log_message "Günlük yedekleme görevi eklendi: Her gün 01:00"
fi

# S3 yükleme görevi
if echo "$CURRENT_CRONTAB" | grep -q "$S3_UPLOAD_SCRIPT"; then
  log_message "S3 yükleme görevi zaten mevcut."
else
  CURRENT_CRONTAB=$(crontab -l)
  NEW_CRONTAB="${CURRENT_CRONTAB}${CURRENT_CRONTAB:+$'\n'}# Günlük AWS S3 yükleme - her gün 01:30'da çalışır$'\n'${DAILY_S3_CRON}"
  echo "$NEW_CRONTAB" | crontab -
  log_message "S3 yükleme görevi eklendi: Her gün 01:30"
fi

# Google Drive yükleme görevi
if echo "$CURRENT_CRONTAB" | grep -q "$GDRIVE_UPLOAD_SCRIPT"; then
  log_message "Google Drive yükleme görevi zaten mevcut."
else
  CURRENT_CRONTAB=$(crontab -l)
  NEW_CRONTAB="${CURRENT_CRONTAB}${CURRENT_CRONTAB:+$'\n'}# Günlük Google Drive yükleme - her gün 02:00'de çalışır$'\n'${DAILY_GDRIVE_CRON}"
  echo "$NEW_CRONTAB" | crontab -
  log_message "Google Drive yükleme görevi eklendi: Her gün 02:00"
fi

# Cron servisini yeniden başlat
if command -v service &> /dev/null; then
  sudo service cron restart
  log_message "Cron servisi yeniden başlatıldı."
else
  log_message "Cron servisi yeniden başlatılamadı. Lütfen elle yeniden başlatın: sudo service cron restart"
fi

log_message "Cron ayarları tamamlandı. Mevcut cron görevleri:"
crontab -l | tee -a "$CRON_LOG"

# Yardımcı bilgiler
cat << EOL

Yedekleme Sistemi Kurulumu Tamamlandı!

Mevcut görevler:
- Günlük Yedekleme: Her gün 01:00'de
- AWS S3'e Yükleme: Her gün 01:30'da
- Google Drive'a Yükleme: Her gün 02:00'de

Manuel Çalıştırma:
- Yedekleme: ${BACKUP_SCRIPT}
- AWS S3'e Yükleme: ${S3_UPLOAD_SCRIPT}
- Google Drive'a Yükleme: ${GDRIVE_UPLOAD_SCRIPT}
- Geri Yükleme: ${SCRIPT_DIR}/restore.sh

Yedekleriniz: ${BACKUP_DIR}
Log dosyaları: ${LOG_DIR}

EOL 