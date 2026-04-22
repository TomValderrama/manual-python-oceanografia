# Lectura de archivos

Un pipeline de datos oceanográficos lee de múltiples fuentes y formatos: CSV del datalogger de viento, Excel de procesamiento, archivos `.mat` de MATLAB (STORM2), binarios del Nortek (`.prf`), y documentos Word para extracción de metadata.

## Archivos de texto y CSV

```python
import pandas as pd

# CSV estándar
df = pd.read_csv('viento.csv')

# Opciones comunes
df = pd.read_csv(
    'viento.csv',
    sep=';',                         # separador de columna
    decimal=',',                     # decimal con coma (datos europeos)
    skiprows=2,                      # saltar filas de encabezado
    encoding='latin-1',              # encoding para tildes
    parse_dates=['fecha'],           # convertir columna a datetime
    index_col='fecha',               # usar fecha como índice
    na_values=['-9999', 'N/A', '']  # valores a tratar como NaN
)
```

### Detectar encoding

Si el archivo tiene tildes y aparecen caracteres extraños, probar:

```python
for enc in ['utf-8', 'latin-1', 'cp1252']:
    try:
        df = pd.read_csv('archivo.csv', encoding=enc)
        print(f"Funciona con: {enc}")
        break
    except UnicodeDecodeError:
        continue
```

## Archivos Excel

```python
# Hoja por nombre
df = pd.read_excel('corrientes.xlsx', sheet_name='VELOCIDAD')

# Primera hoja
df = pd.read_excel('corrientes.xlsx', sheet_name=0)

# Leer todas las hojas
hojas = pd.read_excel('corrientes.xlsx', sheet_name=None)
# hojas es un dict: {'VELOCIDAD': df1, 'DIRECCION': df2, ...}

for nombre, df in hojas.items():
    print(f"Hoja '{nombre}': {df.shape}")
```

### Leer varias hojas del Excel de procesamiento

En el pipeline de corrientes, el Excel de procesamiento tiene múltiples hojas con estadísticas, tablas de incidencia y vectores progresivos:

```python
hojas_requeridas = ['NOTAS', 'TABLAS_INCIDENCIA', 'UV', 'VECTOR_PROGRESIVO']

datos = {}
for hoja in hojas_requeridas:
    try:
        datos[hoja] = pd.read_excel(ruta_excel, sheet_name=hoja)
    except Exception as e:
        print(f"  ! No se encontró la hoja '{hoja}': {e}")
```

## Archivos MATLAB (.mat)

Los datos del equipo de oleaje STORM2 (Nortek) se exportan en formato `.mat`. Se leen con `scipy.io`:

```python
from scipy.io import loadmat

mat = loadmat('datos_storm2.mat')

# mat es un diccionario con las variables del workspace de MATLAB
print(mat.keys())

# Extraer variables
Hm0 = mat['Hm0'].flatten()      # flatten convierte (N,1) → (N,)
Tp  = mat['Tp'].flatten()
tiempo = mat['time'].flatten()
```

### Convertir tiempo MATLAB a datetime de Python

MATLAB guarda el tiempo como número de días desde el 0-ene-0000. Para convertir a pandas:

```python
import pandas as pd
import numpy as np

def matlab_datenum_a_datetime(datenum):
    return pd.to_datetime(datenum - 719529, unit='D', origin='unix')

timestamps = matlab_datenum_a_datetime(tiempo)
```

## Archivos JSON

```python
import json

# Leer
with open('config.json', 'r', encoding='utf-8') as f:
    config = json.load(f)

empresa = config['empresa']

# Guardar
with open('estado.json', 'w', encoding='utf-8') as f:
    json.dump(config, f, ensure_ascii=False, indent=2)
```

## Archivos de texto plano

```python
# Leer completo
with open('notas.txt', 'r', encoding='utf-8') as f:
    contenido = f.read()

# Leer línea por línea
with open('log.txt', 'r') as f:
    for linea in f:
        print(linea.strip())

# Escribir
with open('resultado.txt', 'w', encoding='utf-8') as f:
    f.write("Velocidad máxima: 0.6 m/s\n")
    f.write("Profundidad: 7 m\n")
```

## Buscar archivos con glob y os

En el pipeline es frecuente buscar archivos por patrón sin saber el nombre exacto:

```python
import glob
import os

# Todos los Excel en una carpeta
archivos = glob.glob('/ruta/carpeta/*.xlsx')

# Recursivo (busca en subcarpetas también)
archivos = glob.glob('/ruta/**/*.xlsx', recursive=True)

# Filtrar con condición
excels_corrientes = [
    f for f in glob.glob('/ruta/*.xlsx')
    if 'corriente' in f.lower()
]

# Listar archivos y carpetas
os.listdir('/ruta/carpeta')

# Verificar si existe
os.path.exists('/ruta/archivo.csv')

# Construir rutas de forma segura (funciona en Windows y Linux)
ruta = os.path.join('/ruta/base', 'subcarpeta', 'archivo.csv')
```

## Documentos Word (.docx)

Python-docx permite leer texto desde documentos Word, útil para extraer metadata de informes anteriores:

```python
from docx import Document

doc = Document('informe.docx')

# Leer todos los párrafos
for parrafo in doc.paragraphs:
    if parrafo.text.strip():
        print(parrafo.text)

# Leer tablas
for tabla in doc.tables:
    for fila in tabla.rows:
        celdas = [celda.text for celda in fila.cells]
        print(celdas)
```

### Leer .docx sin python-docx (XML directo)

Para extraer texto con más control, el `.docx` es en realidad un archivo ZIP con XML adentro:

```python
import zipfile
import re

def extraer_texto_docx(ruta):
    with zipfile.ZipFile(ruta) as z:
        xml = z.read('word/document.xml').decode('utf-8')
    # Eliminar etiquetas XML
    texto = re.sub(r'<[^>]+>', ' ', xml)
    texto = re.sub(r'\s+', ' ', texto).strip()
    return texto
```

## Manejo de rutas con pathlib

La librería `pathlib` ofrece una forma más moderna de trabajar con rutas:

```python
from pathlib import Path

carpeta = Path('/mnt/c/Users/Tomas/PELICANOS Dropbox/Proyectos2025')
archivo = carpeta / 'Los Vilos' / 'corrientes.csv'

archivo.exists()        # True/False
archivo.suffix          # '.csv'
archivo.stem            # 'corrientes'
archivo.parent          # carpeta Los Vilos
archivo.name            # 'corrientes.csv'

# Listar archivos
list(carpeta.glob('*.xlsx'))
list(carpeta.rglob('*.csv'))   # recursivo
```

!!! warning "Rutas en Windows desde WSL"
    Al usar Python desde WSL (Windows Subsystem for Linux), las rutas de Windows se acceden como `/mnt/c/...`. Las rutas con espacios deben ir entre comillas o manejarse con `Path`:
    ```python
    ruta = Path('/mnt/c/Users/Tomas/PELICANOS Dropbox/archivo.csv')
    ```

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
