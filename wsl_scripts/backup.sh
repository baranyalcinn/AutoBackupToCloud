# Değişkenler
SOURCE_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/data"
BACKUP_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/backup_system"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
DATE=$(date +"%Y-%m-%d-%H-%M")
BACKUP_FILE="backup_${DATE}.tar.gz"
LOG_FILE="${LOG_DIR}/backup_log_${DATE}.txt"

# Log dizini yoksa oluştur
mkdir -p "$LOG_DIR"

# Log fonksiyonu
log_message() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} - $1" | tee -a "$LOG_FILE"
}

# Kaynak dizini kontrol et
if [ ! -d "$SOURCE_DIR" ]; then
  log_message "HATA: Kaynak dizin bulunamadı: $SOURCE_DIR"
  exit 1
fi

# Yedekleme dizini yoksa oluştur
if [ ! -d "$BACKUP_DIR" ]; then
  log_message "Yedekleme dizini oluşturuluyor: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

log_message "Yedekleme başlatıldı: $SOURCE_DIR -> $BACKUP_DIR/$BACKUP_FILE"

# Tar ile yedek oluştur
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

if [ $? -eq 0 ]; then
  log_message "Yedekleme başarıyla tamamlandı: $BACKUP_DIR/$BACKUP_FILE"
  
  # 30 günden eski yedekleri temizle
  log_message "Eski yedekler temizleniyor (30 günden eski)..."
  find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -mtime +30 -exec rm {} \; -exec echo "Silindi: {}" \; 2>&1 | tee -a "$LOG_FILE"
else
  log_message "HATA: Yedekleme başarısız oldu."
  exit 1
fi

log_message "Yedekleme işlemi tamamlandı." 