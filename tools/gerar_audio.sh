#!/bin/bash
# Regenera os áudios das letras a partir dos brutos e re-embute no index.html.
#
# Uso: bash tools/gerar_audio.sh   (rodar na raiz do repositório, em macOS)
#
# Fluxo: assets/audio/raw/<letra>_letra_NN.m4a
#          -> normaliza volume + fade (tools/normalize.py)
#          -> re-encoda AAC 48kbps mono (afconvert, nativo do macOS)
#          -> assets/audio/letras/<letra>.m4a
#          -> substitui o bloco AUDIO_B64 dentro do index.html
set -euo pipefail

cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for f in assets/audio/raw/*_letra_*.m4a; do
    n=$(basename "$f" | cut -c1)
    afconvert -f WAVE -d LEI16 "$f" "$TMP/raw_$n.wav"
    python3 tools/normalize.py "$TMP/raw_$n.wav" "$TMP/$n.wav"
    afconvert -f m4af -d aac -b 48000 -q 127 -s 3 "$TMP/$n.wav" "$TMP/$n.m4a"
    cp "$TMP/$n.m4a" "assets/audio/letras/$n.m4a"
done

{
    printf 'const AUDIO_B64 = {\n'
    for f in "$TMP"/?.m4a; do
        n=$(basename "$f" .m4a)
        printf "        %s: '%s',\n" "$n" "$(base64 -i "$f" | tr -d '\n')"
    done
    printf '    };'
} > "$TMP/audio_b64.js"

python3 - "$TMP/audio_b64.js" <<'EOF'
import re, sys
blob = open(sys.argv[1]).read()
path = 'index.html'
html = open(path).read()
new, count = re.subn(r'const AUDIO_B64 = \{.*?\n    \};', lambda m: blob, html, count=1, flags=re.S)
assert count == 1, 'bloco AUDIO_B64 não encontrado no index.html'
open(path, 'w').write(new)
print('index.html atualizado')
EOF

echo "Pronto: $(ls assets/audio/letras | wc -l | tr -d ' ') letras processadas."
