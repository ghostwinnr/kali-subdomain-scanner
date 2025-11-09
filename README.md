# Kali Subdomain Scanner (Pentest odaklı)

Önemli: Bu araç yalnızca yetkili pentest, eğitim veya izole lab ortamları için kullanılmalıdır.

## Hızlı başlangıç
1. `sudo bash install-deps.sh`
2. `sudo bash scan.sh example.com`
3. Sonuçlar `results/example.com/` altında bulunur.

## İçerik
- `scan.sh` : Orkestratör script
- `install-deps.sh` : Gerekli araçların kurulumu (go ile bazı araçlar kurulur)
- `report_generator.py` : Markdown raporu oluşturur
