#!/bin/bash
# Publicar manual actualizado en el portafolio
# Uso: bash publicar.sh  (desde la carpeta manual-python-oceanografia/)

set -e

bash generar_pdf.sh

# Partir siempre desde el estado remoto (manual/ se regenera completo)
cd ../TomValderrama.github.io
git fetch origin
git reset --hard origin/main
cd -

mkdocs build --site-dir ../TomValderrama.github.io/manual
cp Python_de_Extremo_a_Extremo.pdf ../TomValderrama.github.io/manual/

cd ../TomValderrama.github.io
git add manual/
git diff --staged --quiet || git commit -m "Actualizar manual"
git push
