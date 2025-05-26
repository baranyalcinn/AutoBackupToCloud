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
                creds = flow.run_local_server(port=0, access_type='offline', prompt='consent')
            
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
