"""Geometry audit only; visual, license and anatomy review remain mandatory.
Run in a tools environment with numpy/trimesh installed. Does not load AI models.
"""
import argparse, hashlib, json, struct
from pathlib import Path
import numpy as np
import trimesh

parser = argparse.ArgumentParser()
parser.add_argument('path', type=Path)
parser.add_argument('--max-triangles', type=int, default=50000)
args = parser.parse_args()
data = args.path.read_bytes()
magic, version, length = struct.unpack_from('<4sII', data)
if magic != b'glTF' or version != 2 or length != len(data):
    raise SystemExit('Invalid GLB 2.0 header or length')
scene = trimesh.load(args.path, force='scene')
meshes = list(scene.geometry.values())
if not meshes or not all(len(m.vertices) and len(m.faces) and np.isfinite(m.vertices).all() for m in meshes):
    raise SystemExit('Missing or non-finite geometry')
triangles = sum(len(m.faces) for m in meshes)
report = {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data), 'meshes': len(meshes), 'triangles': triangles, 'bounds': scene.bounds.tolist(), 'has_uv': all(getattr(m.visual,'uv',None) is not None for m in meshes), 'status': 'geometry_pass' if triangles <= args.max_triangles else 'optimization_required', 'visual_review': 'required'}
print(json.dumps(report, indent=2))
raise SystemExit(0 if triangles <= args.max_triangles else 1)
