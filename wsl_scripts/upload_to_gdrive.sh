#!/bin/bash

# Değişkenler
BACKUP_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/backup_system"
LOG_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/logs"
CLIENT_SECRET_PATH="/mnt/c/Users/recte/Desktop/SystemManagement/client_secret.json"
GDRIVE_FOLDER_ID="root" # Varsayılan olarak root klasör
DATE=$(date +"%Y-%m-%d-%H-%M")
LOG_FILE="${LOG_DIR}/gdrive_upload_log_${DATE}.txt"
SCRIPT_DIR="/mnt/c/Users/recte/Desktop/SystemManagement/wsl_scripts"
VENV_PATH="/mnt/c/Users/recte/Desktop/SystemManagement/aws-cli-venv/bin/activate" # Sanal ortam activate betiği

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

# Client secret kontrol et
if [ ! -f "$CLIENT_SECRET_PATH" ]; then
  log_message "HATA: Google API client secret dosyası bulunamadı: $CLIENT_SECRET_PATH"
  log_message "Lütfen Google Cloud Console'dan credentials dosyasını indirin."
  exit 1
fi

# Sanal ortamı aktif et
if [ -f "$VENV_PATH" ]; then
  log_message "Sanal ortam aktif ediliyor: $VENV_PATH"
  source "$VENV_PATH"
else
  log_message "HATA: Sanal ortam activate betiği bulunamadı: $VENV_PATH"
  log_message "Lütfen sanal ortamın doğru kurulduğundan emin olun."
  exit 1
fi

# Python kontrol et
if ! command -v python3 &> /dev/null; then
  log_message "HATA: Python3 bulunamadı. Lütfen yükleyin veya sanal ortamı kontrol edin."
  deactivate # Hata durumunda sanal ortamı devre dışı bırak
  exit 1
fi

# Gerekli Python paketlerini yükle (sanal ortam aktif olduğu için burası normalde gerekmeyebilir ama kontrol amaçlı kalabilir)
# log_message "Gerekli Python paketleri kontrol ediliyor..."
# python3 -m pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
# if [ $? -ne 0 ]; then
#    log_message "HATA: Gerekli Python paketleri yüklenemedi."
#    deactivate
#    exit 1
# fi

# En son yedek dosyasını bul
LATEST_BACKUP=$(find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)

if [ -z "$LATEST_BACKUP" ]; then
  log_message "HATA: Yedekleme dizininde yedek dosyası bulunamadı."
  deactivate # Hata durumunda sanal ortamı devre dışı bırak
  exit 1
fi

# Python betik oluştur
PYTHON_SCRIPT="${SCRIPT_DIR}/gdrive_upload.py"

cat > "$PYTHON_SCRIPT" << 'EOF'
import os
import sys
import json
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

# Google Drive API için gerekli izinler
SCOPES = ['https://www.googleapis.com/auth/drive.file']

def upload_to_drive(file_path, folder_id, client_secret_path):
    try:
        # Kimlik doğrulama
        creds = None
        token_path = os.path.expanduser('~/.gdrive_token.json')
        
        # Token dosyası varsa kullan
        if os.path.exists(token_path):
            with open(token_path, 'r') as token:
                creds = Credentials.from_authorized_user_info(json.load(token), SCOPES)
        
        # Token yoksa veya geçersizse yeni al
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(client_secret_path, SCOPES)
                creds = flow.run_local_server(port=0)
            
            # Token'ı kaydet
            with open(token_path, 'w') as token:
                token.write(creds.to_json())
        
        # Drive API servisini oluştur
        service = build('drive', 'v3', credentials=creds)
        
        # Dosya adını al
        file_name = os.path.basename(file_path)
        
        # Dosya metadatası oluştur
        file_metadata = {
            'name': file_name,
            'parents': [folder_id]
        }
        
        # Dosya içeriğini yükle
        media = MediaFileUpload(file_path, resumable=True)
        
        # Dosyayı yükle
        file = service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id'
        ).execute()
        
        print(f"Dosya başarıyla yüklendi: {file.get('id')}")
        return True
    
    except HttpError as error:
        print(f"Hata oluştu: {error}")
        return False

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Kullanım: python3 gdrive_upload.py <dosya_yolu> <klasör_id> <client_secret_yolu>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    folder_id = sys.argv[2]
    client_secret_path = sys.argv[3]
    
    success = upload_to_drive(file_path, folder_id, client_secret_path)
    sys.exit(0 if success else 1)
EOF

log_message "Yükleme başlatılıyor: $LATEST_BACKUP -> Google Drive ($GDRIVE_FOLDER_ID)"

# Python betiği çalıştır
python3 "$PYTHON_SCRIPT" "$LATEST_BACKUP" "$GDRIVE_FOLDER_ID" "$CLIENT_SECRET_PATH"

if [ $? -eq 0 ]; then
  log_message "Yükleme başarıyla tamamlandı"
else
  log_message "HATA: Yükleme başarısız oldu."
  deactivate # Hata durumunda sanal ortamı devre dışı bırak
  exit 1
fi

# Sanal ortamı devre dışı bırak
deactivate
log_message "Sanal ortam devre dışı bırakıldı."

log_message "Google Drive yükleme işlemi tamamlandı." 
