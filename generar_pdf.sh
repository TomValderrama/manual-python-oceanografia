#!/bin/bash
# Genera PDF del manual usando Pandoc + XeLaTeX
# Uso: bash generar_pdf.sh

set -e

DOCS="docs"
SALIDA="Python_de_Extremo_a_Extremo.pdf"

# Orden de capítulos
ARCHIVOS=(
  "$DOCS/index.md"
  "$DOCS/parte1/01_entorno_spyder.md"
  "$DOCS/parte1/02_sintaxis.md"
  "$DOCS/parte1/03_control_flujo.md"
  "$DOCS/parte1/04_funciones_modulos.md"
  "$DOCS/parte2/05_numpy.md"
  "$DOCS/parte2/06_pandas.md"
  "$DOCS/parte2/07_lectura_archivos.md"
  "$DOCS/parte3/08_matplotlib.md"
  "$DOCS/parte3/09_rosas_polares.md"
  "$DOCS/parte3/10_figuras_informes.md"
  "$DOCS/parte4/11_estadisticas_circulares.md"
  "$DOCS/parte4/12_analisis_espectral.md"
  "$DOCS/parte4/13_filtros_interpolacion.md"
  "$DOCS/parte5/14_python_docx.md"
  "$DOCS/parte5/15_plantillas_placeholders.md"
  "$DOCS/parte5/16_importacion_dinamica.md"
  "$DOCS/parte6/17_rasterio_geopandas.md"
  "$DOCS/parte6/18_coordenadas_mapas.md"
  "$DOCS/parte7/19_ocr_batimetria.md"
  "$DOCS/parte8/20_croco_outputs.md"
  "$DOCS/parte9/21_sentinel_stac_mgrs.md"
)

echo "Generando PDF..."

pandoc "${ARCHIVOS[@]}" \
  --pdf-engine=xelatex \
  --output="$SALIDA" \
  --resource-path=".:docs/parte1:docs/parte2:docs/parte3:docs/parte4:docs/parte5:docs/parte6:docs/parte7" \
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
