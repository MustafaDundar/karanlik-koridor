# Hugging Face üretim hattı

Hedef: bulutta üret, küçük çıktıyı indir, incele/optimize et, Godot'a al, test et. Model ağırlıklarını Mac'e indirme.

Bu liste aday değerlendirmesidir; sadece üretim kaydında başarılı yazan çağrılar çalıştırılmıştır. Araştırma tarihi: 23 Ekim 2026.

| Alan | Aday / alternatif | Değerlendirme ve geçiş koşulu |
|---|---|---|
| Konsept / referans | [FLUX Schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell), [Qwen Image Fast](https://huggingface.co/spaces/mcp-tools/Qwen-Image-Fast) | Schnell ile dolap konsepti üretildi. Schnell Apache-2.0 olarak listeleniyor; Qwen model ve hızlandırma lisansı ayrıca incelenmeli. |
| Karakter / yaratık | [TRELLIS.2](https://huggingface.co/microsoft/TRELLIS.2-4B), [Hunyuan3D-2.1](https://huggingface.co/tencent/Hunyuan3D-2.1) | Önce tek sabit prop ile zinciri kanıtla; sonra çok açılı anatomi. TRELLIS.2 MIT; Hunyuan özel koşullar. Rigli/animasyonlu çıkış varsayma. |
| Bina / iç mekân | Aynı 3D modeller; modüler parça üretimi | Bütün hastaneyi tek mesh üretme. Ölçek, kapı açıklığı ve collision Godot'ta ölçülmeli. |
| Kapı / mobilya / dekor | [TRELLIS community](https://huggingface.co/spaces/trellis-community/TRELLIS), [Stable Fast 3D](https://huggingface.co/spaces/stabilityai/stable-fast-3d) | Konsept → alpha → GLB. SF3D lisansı incelenmeden ticari nihai varlık kabul edilmez. |
| Rigging | [image-to-rigged-3d](https://huggingface.co/spaces/kirikir13/image-to-rigged-3d), [RigNet](https://huggingface.co/spaces/ckc99u/Rignet) | İlk servis PAUSED. Otomatik rig yeterli sayılmaz; omuz, kalça, parmak deformasyonu test edilmeli. |
| Yürüme / koşma / saldırı / ölüm | [Tencent HY-Motion-1.0](https://huggingface.co/tencent/HY-Motion-1.0) | Yalnızca aday. Lisans, çalışan cloud endpoint ve skeleton retarget incelenmeden üretime alınmaz. Her klipte ayak kayması, root motion, loop ve Godot geçişleri test edilmeli. |
| PBR albedo | Schnell / Qwen konseptten yüzey üretimi | Yönsüz ışık ve tekrar sınırları kontrol edilmeli. Konsept görüntüsü PBR set değildir. |
| Normal / roughness / metallic | [PBRFusion adayları](https://huggingface.co/spaces/NightRaven109/PBRFusion4DepthDemo-InstNorm), TRELLIS.2 materyal çıktısı | Kanal anlamları ve lisans doğrulanmalı. Albedodan çıkarılan yükseklik fiziksel doğruluk iddiası taşımaz; metal/paint ayrımı kontrol edilmeli. |
| Ambiyans / efekt | [Stable Audio Open Zero](https://huggingface.co/spaces/artificialguybr/Stable-Audio-Open-Zero) | Lisans, cloud limit, clipping ve loop birleşimi kontrolü; ses yüksekliği normalize edilip Godot spatial attenuation test edilmeli. |
| Müzik | Stable Audio ailesi; müzik adayı ayrıca seçilecek | Melodi kalitesi, loop, lisans ve ticari kullanım şartları doğrulanmadan final skor yok. |
| Türkçe seslendirme | [Piper Turkish](https://huggingface.co/99eren99/piper-turkish-tts); Türkçe destekli diğer TTS ayrıca kıyaslanacak | Ses modeli lisansı, çalışan ücretsiz bulut endpoint ve telaffuz QA gerekli. SpeechT5 Turkish cc-by-nc adayı ticari final için uygun kabul edilmedi. |
| Diğer diller | [Chatterbox](https://huggingface.co/spaces/ResembleAI/Chatterbox), [Kokoro](https://huggingface.co/spaces/hexgrad/Kokoro-TTS) | Dil desteği ve ses lisansı doğrulanmalı. Gerçek kişinin sesi izinsiz klonlanmaz. |
| Sinematik | [Wan2.2 Space](https://huggingface.co/spaces/zerogpu-aoti/wan2-2-fp8da-aoti-faster) | Önce oyun içi kamera ve tutarlı karakter referansı. Video animasyonu iskelet animasyonu yerine geçmez; lisans/kota/karakter tutarlılığı kontrolü gerekli. |

## Bütçe ve erişim

- [ZeroGPU koşulları](https://huggingface.co/docs/hub/spaces-zerogpu): Pro dahil kotası aşılırsa ön ödemeli krediler otomatik tüketilebilir. Pro üyeliği sınırsız ücretsiz GPU demek değildir.
- [Kota sorgusu](https://huggingface.co/docs/huggingface_hub/guides/manage-spaces): `HfApi.get_zero_gpu_quota()`. Uygun kimlik doğrulama/izin gerekir.
- Her çağrı öncesi kalan kota, sunucudaki GPU duration ve xlarge için iki kat kota rezervi kontrol edilmeli. Kota okunamıyorsa veya yeterli değilse dur; ücretli Jobs/Inference Endpoint açma.
- Model lisansı, Space kod lisansı ve kullanılan ek modeller ayrı ayrı kaydedilmeli.

## Gerçekleşen zincir ve sonraki adım

FLUX konsepti → TripoSR cpu-basic GLB (görsel kalite reddedildi) → Hunyuan3D-2.1 kimliksiz shape generation (başarılı) → CPU mesh temizliği / 20k decimation → Godot inceleme sahnesi. Türkçe anons Pocket TTS Türkçe cpu-basic Space'te üretildi ve prototipe entegre edildi. Ayrıntılar üretim kaydında.

Sonraki kapı: Hunyuan dokulu endpoint'in 270 saniyelik rezervasyonu için dahil Pro kotasını araç üzerinden doğrulamak, UV/PBR üretmek ve gerçek renderer altında varlığı incelemek. Oyun içi nihai kullanım ve 60 FPS iddiası henüz yok.

CPU rotalarını yeniden üretmek için `tools/produce_free_cpu.py` var. Kaynak kod hash'i ve cpu-basic runtime kontrolü geçmeden çağrı yapmaz. Yeni çıktıları final oyuna otomatik taşımaz.
