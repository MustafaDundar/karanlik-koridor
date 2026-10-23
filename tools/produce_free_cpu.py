"""Reproduce the audited free CPU cloud routes; never downloads model weights.
Dependencies: gradio_client. Run: python tools/produce_free_cpu.py voice|mesh
Cloud output is staged for review, never promoted into gameplay automatically.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import urllib.request
from gradio_client import Client, handle_file

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('kind', choices=['voice', 'mesh'])
args = parser.parse_args()
space = 'wite-tech/pocket-tts-turkish' if args.kind == 'voice' else 'WeReCooking2/Dust3R-TripoSR'
# No account credentials: no Pro credits can be consumed by this client.
with urllib.request.urlopen('https://huggingface.co/api/spaces/' + space, timeout=20) as r:
    info = json.load(r)
runtime = info.get('runtime', {})
if runtime.get('stage') != 'RUNNING' or runtime.get('hardware', {}).get('current') != 'cpu-basic':
    raise SystemExit('Audited cpu-basic route unavailable. Stop; do not select GPU automatically.')
with urllib.request.urlopen('https://huggingface.co/spaces/' + space + '/raw/main/app.py', timeout=20) as r:
    source = r.read()
# Pin the inspected server source. Runtime changes require a fresh review.
EXPECTED_SOURCE = {
    'wite-tech/pocket-tts-turkish': '53a58e248c41a04016f143d72882b5911e96b3d2191eccc384d5f4f1d97ccca1',
    'WeReCooking2/Dust3R-TripoSR': '1c94ccf0503e76ddedb665a3d4f250aeb1d79f57a2219da162a1db8e7f7134e0',
}
if hashlib.sha256(source).hexdigest() != EXPECTED_SOURCE[space]:
    raise SystemExit('Space source changed. Review billing/model behavior before calling.')
staging = ROOT / 'production' / 'staging'
staging.mkdir(parents=True, exist_ok=True)
target = staging / ('emergency-tr-new.wav' if args.kind == 'voice' else 'cabinet-triposr-new.glb')
if target.exists():
    raise SystemExit('Staged output exists; review it before another run.')
client = Client(space, token=False, analytics_enabled=False)
if args.kind == 'voice':
    params = dict(text='Dikkat. Acil çıkışın elektriği kesildi. Yedek sigortayı bekleme alanında bulabilirsiniz.', voice='female_3', emotion='neutral')
    result = client.predict(**params, api_name='/synthesize')
    target = staging / 'emergency-tr-new.wav'
else:
    concept = ROOT / 'assets' / 'hf' / 'cabinet-concept.webp'
    image = client.predict(input_image=handle_file(str(concept)), do_remove_background=True, foreground_ratio=0.85, api_name='/preprocess')
    params = dict(mc_resolution=128)
    result = client.predict(image=handle_file(image), **params, api_name='/generate')
    target = staging / 'cabinet-triposr-new.glb'
if target.exists():
    raise SystemExit('Staged output already exists; review it before another run.')
shutil.copy(result, target)
manifest = {'space': space, 'space_commit': info.get('sha'), 'hardware': 'cpu-basic', 'authenticated': False, 'parameters': params, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'review': 'required'}
target.with_suffix(target.suffix + '.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('Staged for review:', target)
