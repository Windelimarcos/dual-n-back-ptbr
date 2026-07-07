# Dual N-Back em Português

Versão em português brasileiro do jogo de treino cerebral **Dual N-Back**, adaptada do
[dual-n-back.io](https://dual-n-back.io) ([código original](https://github.com/jperryhouts/Dual-N-Back),
GPL v3, de Jonathan Perry-Houts). Pensada para uso no celular.

**Jogue:** abra o `index.html` no navegador — ou acesse a versão publicada no GitHub Pages.

## O que é

A cada 3 segundos, um quadrado acende e uma letra é falada. Seu trabalho é apontar
quando a posição ou a letra repete a de exatamente **N** passos atrás. Indo bem, o N
sobe; indo mal, desce (nunca abaixo de 1). O nível e o histórico ficam salvos no
navegador. Praticar ~20 rodadas por dia melhora a memória de trabalho
([Jaeggi et al., 2003](http://jtoomim.org/brain-training/jaeggi2003-describing-dualnback.pdf)).

## Estrutura

- `index.html` — o app inteiro (HTML + CSS + JS + áudio embutido em base64). Sem dependências nem build.
- `assets/audio/raw/` — gravações originais das 14 letras em pt-BR.
- `assets/audio/letras/` — versões normalizadas/comprimidas usadas para gerar o base64.
- `tools/gerar_audio.sh` — regenera os áudios e re-embute no `index.html` (macOS: usa `afconvert`).

## Publicar no GitHub Pages

1. Suba o repositório para o GitHub.
2. Em *Settings → Pages*, escolha *Deploy from a branch*, branch `master`, pasta `/ (root)`.
3. O jogo fica em `https://<seu-usuario>.github.io/<repo>/`.

## Licença

[GPL v3](LICENSE) — trabalho derivado do Dual-N-Back Game © 2017 Jonathan Perry-Houts.
As gravações de voz em pt-BR são desta versão.
