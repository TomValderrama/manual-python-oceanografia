#!/bin/bash
# Genera PDF del manual usando Pandoc + XeLaTeX
# Uso: bash generar_pdf.sh

set -e

DOCS="docs"
SALIDA="Python_de_Extremo_a_Extremo.pdf"

# Detectar capítulos automáticamente: index.md primero, luego parte*/NN_*.md en orden
ARCHIVOS=(
  "$DOCS/index.md"
  $(find "$DOCS" -path "$DOCS/parte*/*.md" | sort)
)

# Construir --resource-path desde todas las carpetas parte* que existan
RESOURCE_PATH="."
for dir in "$DOCS"/parte*/; do
  RESOURCE_PATH="$RESOURCE_PATH:$dir"
done

echo "Generando PDF (${#ARCHIVOS[@]} archivos)..."

pandoc "${ARCHIVOS[@]}" \
  --pdf-engine=xelatex \
  --output="$SALIDA" \
  --from=markdown-smart \
  --lua-filter=admonitions.lua \
  --resource-path="$RESOURCE_PATH" \
  --toc \
  --toc-depth=2 \
  --number-sections \
  --include-in-header=pdf_header.tex \
  -V lang=es \
  -V geometry:margin=2.5cm \
  -V fontsize=11pt \
  -V mainfont="DejaVu Serif" \
  -V monofont="DejaVu Sans Mono" \
  -V monofontoptions="Scale=0.85" \
  -V colorlinks=true \
  -V linkcolor=teal \
  -V urlcolor=teal \
  --highlight-style=tango \
  --metadata title="Python de Extremo a Extremo" \
  --metadata subtitle="Automatización, Análisis Geoespacial y Visión Artificial" \
  --metadata author="Tomás Valderrama"

echo "PDF generado: $SALIDA"
