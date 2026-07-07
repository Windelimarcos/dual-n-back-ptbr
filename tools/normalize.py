#!/usr/bin/env python3
"""Peak-normalize a PCM16 WAV (mono or stereo->mono) and add 5ms edge fades."""
import array, struct, sys

SRC, DST = sys.argv[1], sys.argv[2]
with open(SRC, 'rb') as f:
    raw = f.read()
assert raw[:4] == b'RIFF' and raw[8:12] == b'WAVE'
pos = 12
fr = None
nch = 1
data = None
while pos + 8 <= len(raw):
    cid = raw[pos:pos+4]
    size = struct.unpack('<I', raw[pos+4:pos+8])[0]
    body = raw[pos+8:pos+8+size]
    if cid == b'fmt ':
        nch, fr, _, block, bits = struct.unpack('<HIIHH', body[2:16])
        assert bits == 16, bits
    elif cid == b'data':
        data = array.array('h')
        data.frombytes(body[:len(body)//2*2])
    pos += 8 + size + (size & 1)
assert fr and data is not None

if nch == 2:
    data = array.array('h', ((data[i] + data[i+1]) // 2 for i in range(0, len(data) - 1, 2)))

peak = max(max(data), -min(data)) or 1
gain = int(32767 * 0.89) / peak
out = array.array('h', (max(-32768, min(32767, int(v * gain))) for v in data))
fade = int(0.005 * fr)
for i in range(min(fade, len(out))):
    out[i] = int(out[i] * i / fade)
    out[-1 - i] = int(out[-1 - i] * i / fade)

with open(DST, 'wb') as f:
    n = len(out)
    f.write(b'RIFF' + struct.pack('<I', 36 + n * 2) + b'WAVE')
    f.write(b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 1, fr, fr * 2, 2, 16))
    f.write(b'data' + struct.pack('<I', n * 2))
    f.write(out.tobytes())
print(f"{SRC} -> {DST}: {n/fr:.2f}s gain x{gain:.1f}")
