# OCR de cartas batimétricas

Las cartas batimétricas —tanto cartas náuticas escaneadas (SHOA) como mosaicos de cartografía digital (Navionics)— contienen cientos de sondeos de profundidad representados como números dispersos sobre la imagen. Digitalizarlos manualmente implica hacer clic en cada número y escribir el valor. Con OpenCV y Tesseract el proceso se automatiza: Python detecta los números, los lee y los georeferencia en minutos.

## Dependencias

```bash
pip install opencv-python pytesseract pillow rasterio
# Tesseract (Windows): https://github.com/UB-Mannheim/tesseract/wiki
# Linux/WSL: sudo apt install tesseract-ocr
```

## Flujo general del pipeline

```
imagen (JPG/TIFF/GeoTIFF)
    ↓ preprocesamiento (umbralización, máscara de tierra)
    ↓ detección de regiones candidatas (contornos)
    ↓ Tesseract OCR sobre cada región
    ↓ filtro de valores plausibles
    ↓ georeferencia (GCP lineal o GeoTIFF)
    ↓ exportar CSV / XYZ
```

## Cargar y preprocesar la imagen

```python
import cv2
import numpy as np

# cv2.imdecode con fromfile maneja rutas con tildes y espacios en Windows
img_bgr  = cv2.imdecode(np.fromfile('carta_shoa.tiff', dtype=np.uint8), cv2.IMREAD_COLOR)
img_gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
img_rgb  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

h_px, w_px = img_gray.shape
print(f'Imagen: {w_px} × {h_px} px')
```

### Umbralización adaptativa (cartas B&N — SHOA)

Las cartas SHOA son blanco y negro con gradientes de iluminación. La umbralización adaptativa compensa variaciones de brillo locales:

```python
# Binarizar: texto negro sobre fondo blanco
img_bin = cv2.adaptiveThreshold(
    img_gray, 255,
    cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv2.THRESH_BINARY,
    blockSize=15,   # tamaño del vecindario local
    C=5             # constante restada a la media local
)

# Escalar × 3 para que Tesseract trabaje con números más grandes
ESCALA = 3
img_up = cv2.resize(img_bin, None, fx=ESCALA, fy=ESCALA,
                    interpolation=cv2.INTER_CUBIC)
```

### Máscara de tierra por color HSV (cartas Navionics)

Las cartas Navionics usan color: tierra = amarillo/verde, agua = azul. Enmascarar la tierra evita que OCR confunda textos de topografía con sondeos marinos:

```python
img_hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
H, S = img_hsv[:, :, 0], img_hsv[:, :, 1]

# Rangos en OpenCV: H está en [0, 179] (la mitad del ángulo estándar)
mask_tierra = (
    ((H >= 10) & (H <= 24) & (S > 45)) |   # amarillo tierra
    ((H >= 33) & (H <= 60) & (S > 35))      # verde intermareal
)

# Dilatar 2 iteraciones para cubrir bordes y píxeles de borde
kernel = np.ones((5, 5), np.uint8)
mask_tierra = cv2.dilate(mask_tierra.astype(np.uint8), kernel, iterations=2).astype(bool)

# Píxeles oscuros en zona de agua = candidatos a texto
UMBRAL_GRIS = 80
mask_texto = (img_gray < UMBRAL_GRIS) & (~mask_tierra)
mask_u8    = mask_texto.astype(np.uint8) * 255

# Eliminar ruido de compresión JPEG
mask_u8 = cv2.morphologyEx(mask_u8, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8))
```

## Detectar regiones candidatas

Cada número es un grupo de píxeles conectados. La dilatación horizontal conecta dígitos del mismo número antes de buscar contornos:

```python
# Conectar dígitos del mismo número horizontalmente
ANCHO_MAX_PX = 90   # hasta 4 dígitos
kw = max(6, int(ANCHO_MAX_PX * 0.55))
kernel_h = cv2.getStructuringElement(cv2.MORPH_RECT, (kw, 1))
mask_groups = cv2.dilate(mask_u8, kernel_h)

contours, _ = cv2.findContours(mask_groups, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Filtrar por tamaño esperado de un número (ajustar según zoom)
ALTO_MIN, ALTO_MAX = 6, 28
ANCHO_MIN, ANCHO_MAX = 4, 90

candidatos = []
for cnt in contours:
    x, y, w, h = cv2.boundingRect(cnt)
    if not (ALTO_MIN <= h <= ALTO_MAX and ANCHO_MIN <= w <= ANCHO_MAX):
        continue
    # Densidad mínima de píxeles oscuros (descartar cajas vacías)
    if mask_u8[y:y+h, x:x+w].mean() < 8:
        continue
    candidatos.append((x, y, w, h))

print(f'Candidatos a número: {len(candidatos)}')
```

## OCR con Tesseract

```python
import pytesseract
import re

# Windows: ajustar ruta al ejecutable de Tesseract
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Configuración: modo página 8 (un solo bloque de texto), solo dígitos y punto
config_tess = '--psm 8 --oem 3 -c tessedit_char_whitelist=0123456789.'
pat_num     = re.compile(r'^\d{1,4}(\.\d{1,2})?$')

PROF_MIN, PROF_MAX = 0.5, 9999.0
CONF_MINIMA = 45
ESCALA_OCR  = 4   # ampliar imagen para OCR
PAD = 5           # píxeles de margen alrededor del candidato

puntos_ocr = []

# Imagen binaria fondo blanco / texto negro para Tesseract
img_bin_ocr = np.where(mask_u8[:, :, np.newaxis] > 0,
                        np.zeros_like(img_rgb),
                        np.full_like(img_rgb, 255)).astype(np.uint8)

for x, y, w, h in candidatos:
    # Recortar con margen
    x1, y1 = max(0, x - PAD), max(0, y - PAD)
    x2, y2 = min(w_px, x+w+PAD), min(h_px, y+h+PAD)
    roi = img_bin_ocr[y1:y2, x1:x2]

    # Ampliar para OCR
    roi_up = cv2.resize(roi, None, fx=ESCALA_OCR, fy=ESCALA_OCR,
                         interpolation=cv2.INTER_NEAREST)

    datos = pytesseract.image_to_data(roi_up, config=config_tess,
                                       output_type=pytesseract.Output.DICT)

    for j, txt in enumerate(datos['text']):
        txt = str(txt).strip()
        if not pat_num.match(txt):
            continue
        try:
            val = float(txt)
        except ValueError:
            continue
        if not (PROF_MIN <= val <= PROF_MAX):
            continue
        if int(datos['conf'][j]) < CONF_MINIMA:
            continue

        # Centro del bbox en coordenadas de imagen original
        puntos_ocr.append({
            'col':     x + w / 2.0,
            'row':     y + h / 2.0,
            'depth_m': val,
            'conf':    int(datos['conf'][j])
        })
        break   # un número por región

print(f'Sondeos detectados: {len(puntos_ocr)}')
```

### Modos PSM de Tesseract

| PSM | Cuándo usar |
|-----|-------------|
| `8`  | Una sola palabra/número por recorte (recomendado para candidatos ya recortados) |
| `11` | Texto disperso sobre toda la imagen (útil para OCR sobre imagen completa) |
| `6`  | Un bloque de texto uniforme |

## Deduplicar sondeos solapados

```python
# Conservar el de mayor confianza entre puntos a menos de 15 px de distancia
pts = sorted(puntos_ocr, key=lambda p: -p['conf'])
pts_unicos = []
for p in pts:
    if all(np.hypot(p['row'] - u['row'], p['col'] - u['col']) > 15
           for u in pts_unicos):
        pts_unicos.append(p)

print(f'Tras deduplicar: {len(pts_unicos)} sondeos únicos')
```

## Georeferencia

### Opción A — GeoTIFF (automática con rasterio)

Si la imagen ya viene georeferenciada (p. ej. GeoTIFF con EPSG:4326):

```python
import rasterio
from rasterio.transform import xy as rxy

with rasterio.open('navionics_area.tif') as src:
    tf = src.transform

def px_a_geo(col, row):
    lon, lat = rxy(tf, row, col)
    return float(lon), float(lat)
```

### Opción B — GCPs manuales (cartas escaneadas SHOA)

Cuando la imagen no tiene georreferencia embebida, se usan puntos de control (GCPs): pares (fila_px, col_px) → (lon, lat) de referencias conocidas en la carta:

```python
import numpy as np

# GCPs: (fila_px, col_px, lon, lat)
GCPS = [
    ( 100,  200, -72.600, -41.500),   # esquina superior izquierda
    ( 100, 3800, -71.900, -41.500),   # esquina superior derecha
    (2900,  200, -72.600, -42.200),   # esquina inferior izquierda
    (2900, 3800, -71.900, -42.200),   # esquina inferior derecha
]

gcps = np.array(GCPS, dtype=float)
A    = np.column_stack([gcps[:, 1], gcps[:, 0], np.ones(len(gcps))])

coef_lon, _, _, _ = np.linalg.lstsq(A, gcps[:, 2], rcond=None)
coef_lat, _, _, _ = np.linalg.lstsq(A, gcps[:, 3], rcond=None)

def px_a_geo(col, row):
    v = np.array([col, row, 1.0])
    return float(coef_lon @ v), float(coef_lat @ v)

# Verificar error en los propios GCPs
for fila, col, lon_r, lat_r in GCPS:
    lon_e, lat_e = px_a_geo(col, fila)
    err_m = np.hypot((lon_e - lon_r) * 111000, (lat_e - lat_r) * 111000)
    print(f'  Error en GCP: {err_m:.0f} m')
```

!!! tip "Precisión con GCPs"
    Con 4 GCPs en las esquinas el error típico es 50–150 m. Agregar referencias internas de la retícula (intersecciones de meridianos y paralelos impresos en la carta) baja el error a 10–30 m. Con 8+ GCPs bien distribuidos la transformación lineal converge a la precisión de escaneo.

## Exportar a CSV y XYZ

```python
import pandas as pd

registros = []
for p in pts_unicos:
    lon, lat = px_a_geo(p['col'], p['row'])
    registros.append({'lon': lon, 'lat': lat, 'depth_m': p['depth_m']})

df = pd.DataFrame(registros).sort_values('depth_m').reset_index(drop=True)

# CSV para QGIS
df.to_csv('batimetria.csv', index=False, float_format='%.6f')

# XYZ (lon lat profundidad) para Blue Kenue / SWAN
df[['lon', 'lat', 'depth_m']].to_csv(
    'batimetria.xyz', sep=' ', index=False, header=False, float_format='%.6f')

print(f'Exportados: {len(df)} sondeos')
print(f'Rango: {df["depth_m"].min():.1f} – {df["depth_m"].max():.1f} m')
```

## Visualizar resultado

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(9, 7))
sc = ax.scatter(df['lon'], df['lat'],
                c=df['depth_m'], cmap='Blues_r',
                s=15, edgecolors='k', linewidths=0.2, vmin=0)
plt.colorbar(sc, ax=ax, label='Profundidad (m)')
ax.set_xlabel('Longitud (°)')
ax.set_ylabel('Latitud (°)')
ax.set_title(f'Batimetría digitalizada — {len(df)} puntos')
ax.set_aspect('equal')
plt.tight_layout()
plt.savefig('batimetria_mapa.png', dpi=150, bbox_inches='tight')
plt.show()
```

!!! warning "Unidades en cartas SHOA"
    Las cartas SHOA antiguas pueden estar en **pies** o **brazas**, no en metros. Verificar en el margen de la carta. Para convertir: 1 pie = 0.3048 m, 1 braza = 1.8288 m.

!!! tip "Guardar sesión para no repetir OCR"
    El OCR sobre una imagen grande puede tardar varios minutos. Guardar los resultados en JSON permite retomarlos sin re-procesar:
    ```python
    import json
    with open('sesion.json', 'w') as f:
        json.dump(pts_unicos, f)
    # Cargar al reiniciar:
    # with open('sesion.json') as f: pts_unicos = json.load(f)
    ```
