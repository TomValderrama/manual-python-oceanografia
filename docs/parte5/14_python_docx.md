# python-docx

`python-docx` permite crear y modificar documentos Word (`.docx`) desde Python. En el pipeline de Pelícanos se usa para generar el informe final: rellenar texto, insertar figuras, construir tablas y aplicar formato, todo a partir de una plantilla base.

## Instalación

```
pip install python-docx
```

## Estructura de un documento .docx

Un documento Word se organiza en **párrafos** (objetos `Paragraph`) que contienen **runs** (objetos `Run`). Cada run es un fragmento de texto con formato uniforme (fuente, negrita, tamaño, color). Entender esta jerarquía es clave para hacer reemplazos de texto sin perder el formato.

```
Document
  └── paragraphs[]
        └── runs[]    ← texto + formato
  └── tables[]
        └── rows[]
              └── cells[]
                    └── paragraphs[]
                          └── runs[]
```

## Abrir y guardar

```python
from docx import Document

# Abrir plantilla existente
doc = Document('plantilla_informe.docx')

# Guardar con nuevo nombre (no sobreescribir la plantilla)
doc.save('informe_final.docx')
```

## Leer contenido

```python
# Todos los párrafos
for p in doc.paragraphs:
    if p.text.strip():
        print(repr(p.text[:80]))

# Texto completo de una tabla
for tabla in doc.tables:
    for fila in tabla.rows:
        celdas = [c.text.strip() for c in fila.cells]
        print(celdas)
```

## Reemplazar texto en párrafos

El método más directo, pero que puede romper el formato si un placeholder está dividido entre runs:

```python
def reemplazar_en_parrafo(parrafo, viejo, nuevo):
    """Reemplaza texto en el texto completo del párrafo preservando los runs."""
    if viejo in parrafo.text:
        for run in parrafo.runs:
            if viejo in run.text:
                run.text = run.text.replace(viejo, nuevo)
```

Para placeholders que pueden quedar divididos entre runs (problema común con autoformato de Word), usar reemplazo a nivel de XML:

```python
import re

def reemplazar_en_parrafo_robusto(parrafo, viejo, nuevo):
    """Reconstruye el texto del párrafo si el placeholder está partido."""
    texto_completo = parrafo.text
    if viejo not in texto_completo:
        return

    # Vaciar todos los runs excepto el primero
    for i, run in enumerate(parrafo.runs):
        if i == 0:
            run.text = texto_completo.replace(viejo, nuevo)
        else:
            run.text = ''
```

## Insertar figuras

```python
from docx.shared import Cm

def insertar_figura_en_placeholder(doc, placeholder, ruta_imagen, ancho_cm=14):
    """Reemplaza un placeholder de texto por una imagen."""
    for parrafo in doc.paragraphs:
        if placeholder in parrafo.text:
            parrafo.clear()
            run = parrafo.add_run()
            run.add_picture(str(ruta_imagen), width=Cm(ancho_cm))
            return True
    return False

insertar_figura_en_placeholder(doc, '[FIGURA_ROSA]', 'figuras/rosa_corrientes_7m.png')
```

## Construir tablas

```python
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

def agregar_tabla_estadisticas(doc, df_stats, placeholder='[TABLA_STATS]'):
    """
    Inserta un DataFrame como tabla Word en la posición del placeholder.
    """
    for i, parrafo in enumerate(doc.paragraphs):
        if placeholder not in parrafo.text:
            continue

        parrafo.clear()

        # Crear tabla: 1 fila de encabezado + filas de datos
        ncols = len(df_stats.columns) + 1   # +1 para índice
        tabla = doc.add_table(rows=1, cols=ncols)
        tabla.style = 'Table Grid'

        # Encabezado
        fila_enc = tabla.rows[0]
        fila_enc.cells[0].text = df_stats.index.name or ''
        for j, col in enumerate(df_stats.columns):
            fila_enc.cells[j + 1].text = col

        # Datos
        for idx, fila_datos in df_stats.iterrows():
            fila = tabla.add_row()
            fila.cells[0].text = str(idx)
            for j, val in enumerate(fila_datos):
                fila.cells[j + 1].text = f'{val:.2f}' if isinstance(val, float) else str(val)

        # Mover tabla al lugar del párrafo
        parrafo._element.addnext(tabla._tbl)
        break
```

## Aplicar formato a texto

```python
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

# Agregar párrafo con formato
p = doc.add_paragraph()
run = p.add_run('Velocidad máxima registrada: ')
run.bold = True
run.font.size = Pt(11)

run2 = p.add_run('0.62 m/s')
run2.font.color.rgb = RGBColor(0x00, 0x5B, 0x96)   # azul Pelícanos
run2.bold = True
```

## Iterar sobre cuerpo completo (párrafos + tablas)

Para aplicar reemplazos en todo el documento, incluyendo las celdas de las tablas:

```python
def todos_los_parrafos(doc):
    """Generador que yields todos los párrafos del documento (cuerpo y tablas)."""
    yield from doc.paragraphs
    for tabla in doc.tables:
        for fila in tabla.rows:
            for celda in fila.cells:
                yield from celda.paragraphs

def reemplazar_en_doc(doc, reemplazos: dict):
    """
    Aplica un diccionario {placeholder: valor} en todo el documento.
    """
    for parrafo in todos_los_parrafos(doc):
        for viejo, nuevo in reemplazos.items():
            if viejo in parrafo.text:
                reemplazar_en_parrafo(parrafo, viejo, str(nuevo))
```

## Flujo completo del autoinforme

```python
from pathlib import Path

def generar_informe(ruta_plantilla, ruta_salida, reemplazos, figuras):
    """
    ruta_plantilla : Path a la plantilla .docx
    ruta_salida    : Path donde se guardará el informe
    reemplazos     : dict {placeholder_texto: valor}
    figuras        : dict {placeholder_figura: ruta_imagen}
    """
    doc = Document(ruta_plantilla)

    # 1. Reemplazar texto
    reemplazar_en_doc(doc, reemplazos)

    # 2. Insertar figuras
    for placeholder, ruta_img in figuras.items():
        ok = insertar_figura_en_placeholder(doc, placeholder, ruta_img)
        if not ok:
            print(f"  ! Placeholder no encontrado: {placeholder}")

    doc.save(ruta_salida)
    print(f"Informe guardado: {ruta_salida}")

# Uso
generar_informe(
    ruta_plantilla = Path('plantillas/corrientes_v3.docx'),
    ruta_salida    = Path('informes/Los_Vilos_Corrientes_2025.docx'),
    reemplazos = {
        '[PROYECTO]':   'Los Vilos — Campaña octubre 2025',
        '[VEL_MAX]':    '0.62 m/s',
        '[DIR_PRED]':   'NNO (337°)',
        '[FECHA_INI]':  '01/10/2025',
        '[FECHA_FIN]':  '31/10/2025',
    },
    figuras = {
        '[FIGURA_ROSA]':    'figuras/rosa_corrientes_7m.png',
        '[FIGURA_SERIE]':   'figuras/serie_velocidad.png',
        '[FIGURA_HEATMAP]': 'figuras/heatmap_velocidad.png',
    }
)
```

!!! warning "Estilos y plantilla"
    Los estilos de Word (Título 1, Normal, Tabla Grid) están definidos en la plantilla. Si se crea un documento desde cero con `Document()`, los estilos por defecto de python-docx son distintos a los del template de Pelícanos. Siempre trabajar sobre la plantilla para conservar los estilos visuales del informe.
