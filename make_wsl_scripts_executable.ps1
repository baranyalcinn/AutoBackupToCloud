# WSL betiklerine çalıştırma izni vermek için PowerShell betiği
$wslScriptsPath = "C:\Users\recte\Desktop\SystemManagement\wsl_scripts"
$wslScriptsPathUnix = "/mnt/c/Users/recte/Desktop/SystemManagement/wsl_scripts"

Write-Host "WSL kurulu mu kontrol ediliyor..." -ForegroundColor Yellow
$wslInstalled = $false

try {
    $wslCheck = wsl --list --verbose
    $wslInstalled = $true
    Write-Host "WSL kurulu görünüyor. Mevcut dağıtımlar:" -ForegroundColor Green
    Write-Host $wslCheck
} catch {
    Write-Host "WSL kurulu değil veya erişilemiyor. Lütfen önce WSL kurun." -ForegroundColor Red
    Write-Host "Kurulum adımları için: https://docs.microsoft.com/tr-tr/windows/wsl/install" -ForegroundColor Yellow
    exit 1
}

if ($wslInstalled) {
    Write-Host "Betik dosyalarına çalıştırma izni veriliyor..." -ForegroundColor Yellow
    
    try {
        # WSL komutunu çalıştırarak bash betiğini çalıştır
        wsl -e bash -c "chmod +x $wslScriptsPathUnix/*.sh"
        Write-Host "Betik dosyalarına çalıştırma izni verildi." -ForegroundColor Green
        
        # Dizin listesini göster
        $fileList = wsl -e bash -c "ls -la $wslScriptsPathUnix/"
        Write-Host "WSL Scripts klasörü içeriği:" -ForegroundColor Cyan
        Write-Host $fileList
        
        Write-Host "WSL'de betikleri çalıştırmak için:" -ForegroundColor Yellow
        Write-Host "1. WSL terminalini açın (wsl komutunu çalıştırın)" -ForegroundColor White
        Write-Host "2. Betiklerin bulunduğu dizine gidin:" -ForegroundColor White
        Write-Host "   cd $wslScriptsPathUnix" -ForegroundColor White
        Write-Host "3. İstediğiniz betiği çalıştırın, örneğin:" -ForegroundColor White 
        Write-Host "   ./backup.sh" -ForegroundColor White
    } catch {
        Write-Host "Hata oluştu: $_" -ForegroundColor Red
    }
} 