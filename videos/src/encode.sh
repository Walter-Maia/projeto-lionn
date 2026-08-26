#!/bin/bash
# Gera os vídeos do hero a partir dos originais 4K do Pexels (videos/src/orig-N.mp4).
# PRIORIDADE: QUALIDADE INDISTINGUÍVEL DO MASTER (pedido do cliente) — peso é secundário.
# Calibrado por VMAF no trecho mais difícil (clipe 1, muito grão): H.264 CRF 20 tune film ≈ 97–98,
# AV1 CRF 22 ≈ 97,6. Denoise NENHUM: o grão fino do master é justamente o que dá a sensação de nitidez.
# - fps NATIVO de cada clipe (25 / 30 / 60) — nada de forçar 30 fps (frames duplicados = travadinha)
# - desktop: crop 1:1 de 2160² direto do master, SEM redimensionar (o hero é ~2:1, então 9:16 desperdiça
#   73% dos pixels; o recorte entrega pixel a pixel na faixa visível). Clipe 4 (paisagem): 2560x1440.
# - mobile (-sm): quadro inteiro 1080x1920 (clipe 4: crop 1:1 central em 1440²)
# - H.264 High (compatibilidade; decodificado por hardware em qualquer PC) + AV1 (~4x menor na mesma
#   qualidade; o JS só o usa quando mediaCapabilities garante decodificação eficiente)
# - teto VBV alto: só evita picos absurdos, não limita a qualidade normal
set -e
cd "$(dirname "$0")/.."
enc() { # enc <in> <vf> <fps> <out-base> <crf264> <max264M> <crfav1> <maxav1M>
  local in=$1 vf=$2 fps=$3 out=$4 c264=$5 m264=$6 cav1=$7 mav1=$8 g=$((fps*2))
  echo "[$(date +%T)] $out.mp4"
  ffmpeg -hide_banner -loglevel error -y -i "$in" -vf "$vf" -an \
    -c:v libx264 -profile:v high -preset slow -tune film -crf $c264 -maxrate ${m264}M -bufsize $((m264*2))M \
    -g $g -keyint_min $g -sc_threshold 0 -pix_fmt yuv420p -movflags +faststart "$out.mp4"
  echo "[$(date +%T)] $out.av1.mp4"
  ffmpeg -hide_banner -loglevel error -y -i "$in" -vf "$vf" -an \
    -c:v libsvtav1 -preset 4 -crf $cav1 -maxrate ${mav1}M -bufsize $((mav1*2))M -g $g -svtav1-params tune=0 \
    -pix_fmt yuv420p -movflags +faststart "$out.av1.mp4" 2>/dev/null
}
# clipe 1 — 2160x3840 @25 — faixa visível 9–36% da altura → crop topo
enc src/orig-1.mp4 "crop=2160:2160:0:0"                                   25 hero-1    20 40 22 24
enc src/orig-1.mp4 "scale=1080:1920:flags=lanczos"                        25 hero-1-sm 20 14 24  8
# clipe 2 — 2160x3840 @30 — faixa 16–43% → crop a partir de 1.4%
enc src/orig-2.mp4 "crop=2160:2160:0:52"                                  30 hero-2    20 26 22 24   # teto 26 Mbps: mantém o H.264 abaixo do limite de 100 MiB do GitHub
enc src/orig-2.mp4 "scale=1080:1920:flags=lanczos"                        30 hero-2-sm 20 14 24  8
# clipe 3 — 2160x3840 @60 — faixa 15–42% → crop topo (60 fps precisa de teto maior)
enc src/orig-3.mp4 "crop=2160:2160:0:0"                                   60 hero-3    20 50 22 30
enc src/orig-3.mp4 "scale=1080:1920:flags=lanczos"                        60 hero-3-sm 20 18 24 10
# clipe 4 — 3840x2160 @25 (paisagem) — desktop 2560x1440; mobile crop central 1:1
enc src/orig-4.mp4 "scale=2560:1440:flags=lanczos"                        25 hero-4    20 40 22 24
enc src/orig-4.mp4 "crop=2160:2160:840:0,scale=1440:1440:flags=lanczos"   25 hero-4-sm 20 14 24  8
echo "[$(date +%T)] DONE"
