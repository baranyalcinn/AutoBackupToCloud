#!/bin/bash

# Değişkenler
BACKUP_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/backup_system"
RESTORE_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/restored_data"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
DATE=$(date +"%Y-%m-%d-%H-%M")
LOG_FILE="${LOG_DIR}/restore_log_${DATE}.txt"

# Parametreler
BACKUP_FILE=""
LIST_BACKUPS=false

# Parametreleri işle
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--file)
      BACKUP_FILE="$2"
      shift 2
      ;;
    -l|--list)
      LIST_BACKUPS=true
      shift
      ;;
    *)
      echo "Bilinmeyen parametre: $1"
      echo "Kullanım: $0 [-f|--file YEDEK_DOSYASI] [-l|--list]"
      exit 1
      ;;
  esac
done

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

# Mevcut yedekleri bul
BACKUPS=($(find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))

if [ ${#BACKUPS[@]} -eq 0 ]; then
  log_message "HATA: Yedekleme dizininde yedek dosyası bulunamadı."
  exit 1
fi

# Sadece yedekleri listeleme modu
if [ "$LIST_BACKUPS" = true ]; then
  log_message "Mevcut Yedekler:"
  index=1
  for backup in "${BACKUPS[@]}"; do
    backup_name=$(basename "$backup")
    backup_date=$(stat -c "%y" "$backup")
    log_message "$index. $backup_name - $backup_date"
    ((index++))
  done
  exit 0
fi

# Geri yüklenecek yedek dosyasını belirle
BACKUP_TO_RESTORE=""

if [ -z "$BACKUP_FILE" ]; then
  # En son yedeği kullan
  BACKUP_TO_RESTORE="${BACKUPS[0]}"
  BACKUP_FILE=$(basename "$BACKUP_TO_RESTORE")
  log_message "En son yedek kullanılıyor: $BACKUP_FILE"
else
  # Belirtilen dosyayı bul
  for backup in "${BACKUPS[@]}"; do
    if [ "$(basename "$backup")" = "$BACKUP_FILE" ]; then
      BACKUP_TO_RESTORE="$backup"
      break
    fi
  done
  
  if [ -z "$BACKUP_TO_RESTORE" ]; then
    log_message "HATA: Belirtilen yedek dosyası bulunamadı: $BACKUP_FILE"
    log_message "Mevcut yedekleri listelemek için -l veya --list parametresi ile betiği çalıştırın."
    exit 1
  fi
fi

# Geri yükleme dizinini hazırla
if [ -d "$RESTORE_DIR" ]; then
  log_message "Geri yükleme dizini temizleniyor..."
  rm -rf "${RESTORE_DIR:?}"/*
else
  log_message "Geri yükleme dizini oluşturuluyor..."
  mkdir -p "$RESTORE_DIR"
fi

log_message "Geri yükleme başlatılıyor: $BACKUP_TO_RESTORE -> $RESTORE_DIR"

# Tar dosyasını çıkart
tar -xzf "$BACKUP_TO_RESTORE" -C "$RESTORE_DIR"

if [ $? -eq 0 ]; then
  log_message "Geri yükleme başarıyla tamamlandı: $RESTORE_DIR"
else
  log_message "HATA: Geri yükleme başarısız oldu."
  exit 1
fi

log_message "Geri yükleme işlemi tamamlandı." 