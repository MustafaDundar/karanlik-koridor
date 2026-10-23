# Karanlık Koridor

Godot 4 ile birinci şahıs psikolojik korku prototipi. Sigortayı bul, takipçiden kaç, acil çıkışı aç.

## Başlatma

Depo kökündeki `project.godot` dosyasını Godot 4.3+ ile aç ve F5 kullan. `godot/` ayrı eski web prototipidir; mevcut Pages yayını onu kullanır. Bu geliştirme kökteki gerçek 3D sürüme aittir.

WASD hareket · Fare bakış · Shift koş · F fener · E etkileşim · Esc duraklat · Tıkla devam · R bölüm sonunda yeniden başlat.

## Bu geliştirmede

- Kapalı çıkışın yanından geçme açığı kapatıldı; giriş sınırı eklendi.
- Acil çıkış sigortası ve yakından etkileşim hedefi eklendi.
- Takipçi oyuncunun arkasında belirir; düşey hız zeminde sıfırlanır.
- Yakalanınca sigorta, çıkış, pil, kamera ve hızlar tamamen sıfırlanır.
- Kazanınca hareket ve takip durur; yeniden oynanabilir.
- Türkçe hedef/HUD, servis kapıları, korkuluklar, yönlendirme ve elle yazılmış yüzey yıpranma shader'ı eklendi.
- Hugging Face Pocket TTS Türkçe anonsu bulutta üretildi ve altyazısıyla oyuna eklendi; 24 kHz, 7,02 saniye. Dinleme QA bekliyor.
- Hunyuan3D-2.1 ile gerçek dolap GLB’si üretildi, 521.236 → 20.000 üçgene indirildi. `scenes/asset_review.tscn` inceleme sahnesini F6 ile aç; PBR/UV hazır olmadığı için nihai oyuna alınmadı.
- Hugging Face FLUX Schnell ile gerçek dolap konsepti üretildi; `assets/hf/cabinet-concept.webp`. Bu görüntü 3D model değildir.

## Test

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/gameplay.gd
```

Mac Godot 4.7.2 üzerinde 14 otomatik oynanış kontrolü geçti. GitHub Actions kök projeyi Godot 4.3 ile ayrıca test eder. Grafik pencere başlatma ortam erişimine takıldı; görsel QA/FPS/elle oynama henüz doğrulanmadı.

## Üretim durumu

Hugging Face ana AI üretim merkezidir. Bulut servisi, lisans ve kota kontrolü, çıktı indirme ve kalite kapıları [üretim hattında](docs/hugging-face-pipeline.md); gerçek çağrı sonuçları ve sınırlar [üretim kaydında](docs/production-log.md).

Prototip tamamlanmış AAA oyun değildir. Stalker prosedürel yedek geometri kullanır. Yeni 3D model/rig/animasyon/ses/sinematik için başarı yalnızca kayıtta doğrulandığında ilan edilir. Ücretli kaynak kullanıcı onayı olmadan başlatılmaz.
