# Üretim kaydı — 23 Ekim 2026

## Doğrulanmış sonuç

- Mac: arm64, Godot 4.7.2. Ağır model indirilmedi. Blender PATH veya /Applications altında bulunmadı.
- Depo kökündeki `project.godot`: gerçek 3D prototip. `godot/`: ayrı eski web prototipi; mevcut Pages iş akışı onu yayımlıyor. Bu iki projenin varlıkları ve testleri birbirine karıştırılmadı.
- Kökteki oyun Godot headless ile başlatıldı. `tests/gameplay.gd`: 14 kontrol geçti.
- Grafik başlatma macOS uygulama oturumu/sandbox nedeniyle SIGABRT ile durdu. Bu yüzden oynanabilirlik testleri otomatik; görsel QA, FPS ve elle oynama henüz doğrulanmadı.
- `gh` yerel kimlik doğrulaması geçersiz. GitHub connector depoya erişebiliyor.

## Gerçek Hugging Face çağrıları

1. FLUX Schnell Gradio API, kimliksiz çağrı: ZeroGPU runs limit hatası; çıktı oluşmadı.
2. Kullanıcı Pro hesabında en az 5 dakika dahil kota bulunduğunu teyit etti.
3. `evalstate/flux1_schnell`, Pro MCP, seed 73124, 1024×1024, 4 adım: **başarılı**. `assets/hf/cabinet-concept.webp` indirildi ve görsel olarak incelendi. Bu bir konsepttir; 3D mesh değildir. İki çekmece/çift kulp, paslı mint metal, temiz arka plan. Referans için kabul; nihai oyun varlığı değil.
4. `trellis-community/TRELLIS` preprocess: MCP POST endpoint Not Found. `hysts-mcp/TRELLIS`: HTTP 503.
5. `prithivMLmods/TRELLIS.2-Text-to-3D` preprocess: **başarılı**; arka planı temizlenmiş PNG döndü.
6. Aynı Space `generate_3d`: **çalıştırılmadı**. Otomatik onay denetimi, xlarge 120 saniye çağrısının ücretli kredi tüketmeyeceğini doğrulanmış bulmadığı için reddetti.
7. İkinci FLUX doku çağrısı da otomatik onay denetiminde reddedildi; GPU üretimi durduruldu. Ücretli kaynak onayı verilmedi, ücretli iş veya abonelik başlatılmadı. Başarılı ilk FLUX çağrısının faturalandırması bağımsız olarak okunamadı; sıfır harcama iddiası yapılmıyor.

Kalan kotayı okuyan resmi yöntem `HfApi.get_zero_gpu_quota()`; yerelde HF token yok, MCP kota aracı sunmuyor. Tarayıcıdaki oturum başlangıçta farklı ücretsiz hesaba aitti. Pro oturumunun kota ekranıyla doğrulama bekleniyor. Kullanıcıdan şifre/token istenmedi.

## Alternatiflerin canlı durumları

- Microsoft TRELLIS: CONFIG_ERROR (PyTorch/ZeroGPU sürüm uyumsuzluğu).
- Microsoft TRELLIS.2: RUNNING, ZeroGPU.
- Tencent Hunyuan3D-2 ve 2.1: RUNNING, ZeroGPU; özel lisans incelemesi gerekir.
- Stability TripoSR: RUNTIME_ERROR.
- hansyan/perflow-triposr: CONFIG_ERROR.
- Stability Stable Fast 3D: RUNNING, ZeroGPU.
- kirikir13/image-to-rigged-3d: PAUSED.
- Stable Audio Open Zero: RUNNING, ZeroGPU; lisans incelemesi bekliyor.
- Kokoro TTS: RUNNING, ZeroGPU; Türkçe için uygunluğu varsayılmadı.

Durumlar kalıcı garanti değildir; çağrıdan önce yeniden okunmalıdır.

## Kalite kapıları

3D çıktının nihai kullanımı için: sağlam GLB, geçerli geometri/UV/material, doğru ölçek/zemin hizası, ön/arka/yan görsel kontrol, makul üçgen sayısı, Godot import ve oyun içi çarpışma testi. İnsansı model ayrıca anatomi, rig ve animasyon geçişi kontrolünden geçer. Eksik veya bozuk çıktı yedek geometriyle örtülüp AI üretimi tamamlandı diye raporlanmaz.

Shader ile eklenen koridor yıpranması elle yazılmıştır; AI üretimi PBR texture değildir. Stalker hâlâ prosedürel bir prototiptir. Henüz yeni 3D mesh, rig, animasyon, ses veya sinematik üretimi tamamlanmadı.

## Sonraki başarılı alternatifler

75 Space için canlı runtime taraması: `space-runtime-scan.json`. CPU etiketi tek başına yeterli görülmedi; kaynak kodu da incelendi.

- `wite-tech/pocket-tts-turkish`: cpu-basic, doğrudan CPU model inference, dış ücretli sağlayıcı yok. Kimliksiz Gradio çağrısı başarılı. female_3, neutral, 7,02 saniye mono 24 kHz WAV. Peak 0,869; clipping sıfır. Anons ve Türkçe altyazı prototipe entegre edildi; reset/duraklatma testi geçti. İşitsel kalite incelemesi bekliyor. Model CC-BY-4.0; atıf `assets/hf/ATTRIBUTION.md`.
- `WeReCooking2/Dust3R-TripoSR`: cpu-basic, model bulutta çalıştı. 128 mesh resolution ile gerçek GLB üretildi. 49.804 üçgen; dört açılı görsel incelemede bozuk endüstriyel yüzeyler/yuvarlanmış detaylar nedeniyle nihai kullanım reddedildi. Ham çıktı `production/staging/` altında `.gdignore` ile karantinada; varsayılan oyun yüklemiyor.
- Kullanıcının seçtiği `tencent/Hunyuan3D-2.1`: kimliksiz, token=False çağrı; Pro veya kredi hesabı bağlanmadı. Shape generation başarılı: yaklaşık 14,5 saniye sunucu üretim zamanı, 521.236 üçgen, seed 73124, 20 adım. Bu servis kimliksiz çağrıyı kabul etti; önceki Space'in çalıştırma limiti bütün servislerin kapalı olduğu anlamına gelmedi.
- Hunyuan temizlik: ayrı 2 yüzlük parça çıkarıldı; CPU quadric decimation ile 20.000 üçgene düşürüldü. Ön/arka/yan/üç çeyrek görüntü incelendi. Çekmece ve kulplar korunuyor; yüzey/UV/PBR tamamlanmadı, watertight değil. Final kabul yok. `production/review/cabinet-hunyuan-candidate.glb` yalnızca `scenes/asset_review.tscn` geliştirme sahnesine bağlandı. Materyali elle yazılmış nötr mint metal; AI PBR iddiası yok.
- Hunyuan tam dokulu generation_all kimliksiz çağrısı reddedildi: servis 270 saniye GPU rezervasyonu istiyor, kimliksiz çağrı sınırından büyük. Ücretli hesaba geçilmedi. Sonraki adım, Pro ücretsiz kotası araç ekranıyla doğrulanınca PBR üretimini tekrar denemek veya ücretsiz daha kısa rezervasyonlu bir servis seçmek.

Bu bölüm önceki ara durumları günceller: artık gerçek 3D üretimi ve Türkçe ses üretimi var; nihai 3D varlık kalitesi ve dokulu üretim hâlâ tamamlanmadı.
