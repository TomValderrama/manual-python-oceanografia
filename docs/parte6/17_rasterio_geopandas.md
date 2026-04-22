# Rasterio y GeoPandas

En el contexto oceanográfico, los datos geoespaciales aparecen en dos formas: **rasters** (grillas de valores, como batimetría, temperatura SST o campos de viento en grilla) y **vectores** (puntos, líneas y polígonos, como estaciones de medición, líneas de costa o polígonos de áreas de estudio). `rasterio` maneja rasters; `geopandas` maneja vectores.

## Instalación

```
pip install rasterio geopandas
```

## Leer un raster con rasterio

Un raster GeoTIFF contiene una o varias bandas de valores sobre una grilla georreferenciada:

```python
import rasterio
import numpy as np

with rasterio.open('batimetria_zona.tif') as src:
    # Metadatos
    print(f"CRS:        {src.crs}")          # sistema de coordenadas
    print(f"Dimensiones: {src.width} × {src.height}")
    print(f"Bandas:     {src.count}")
    print(f"Bounding box: {src.bounds}")
    print(f"Resolución:  {src.res}")          # (dx, dy) en unidades del CRS

    # Leer banda 1
    datos = src.read(1).astype(float)         # array 2D (filas × columnas)
    datos[datos == src.nodata] = np.nan       # convertir nodata a NaN

    # Coordenadas del centroide de cada celda
    transform = src.transform
```

## Obtener coordenadas de la grilla

```python
import rasterio
from rasterio.transform import xy

with rasterio.open('batimetria_zona.tif') as src:
    datos = src.read(1).astype(float)
    filas, cols = np.indices(datos.shape)
    lons, lats = xy(src.transform, filas, cols)
    lons = np.array(lons)
    lats = np.array(lats)
```

## Extraer el valor en un punto

Para extraer el valor del raster en una coordenada (lat, lon):

```python
from rasterio.sample import sample_gen

def extraer_valor(raster_path, lon, lat):
    """Extrae el valor del raster en el punto (lon, lat)."""
    with rasterio.open(raster_path) as src:
        valores = list(src.sample([(lon, lat)]))
    return valores[0][0]

# Profundidad en la ubicación de una estación
prof = extraer_valor('batimetria.tif', lon=-71.52, lat=-29.90)
print(f"Profundidad: {prof:.1f} m")
```

## Leer un shapefile con GeoPandas

```python
import geopandas as gpd

# Línea de costa de Chile
costa = gpd.read_file('costa_chile.shp')
print(costa.crs)
print(costa.head())

# Filtrar por atributo
costa_4ta = costa[costa['region'] == 'Coquimbo']
```

## Crear un GeoDataFrame desde coordenadas

```python
import pandas as pd
import geopandas as gpd
from shapely.geometry import Point

# Estaciones de medición
estaciones = pd.DataFrame({
    'nombre': ['Los Vilos', 'Coquimbo', 'La Serena'],
    'lon':    [-71.52,      -71.35,     -71.25],
    'lat':    [-31.90,      -29.96,     -29.91],
    'vel_media': [0.12, 0.09, 0.14]
})

gdf_estaciones = gpd.GeoDataFrame(
    estaciones,
    geometry=gpd.points_from_xy(estaciones.lon, estaciones.lat),
    crs='EPSG:4326'   # WGS84 geográfico
)
```

## Reproyectar

```python
# De WGS84 (EPSG:4326) a UTM zona 19S (EPSG:32719)
gdf_utm = gdf_estaciones.to_crs('EPSG:32719')
print(gdf_utm.geometry[0])   # coordenadas en metros
```

## Operaciones espaciales básicas

```python
# Buffer de 5 km alrededor de cada estación
gdf_buffer = gdf_utm.copy()
gdf_buffer['geometry'] = gdf_utm.geometry.buffer(5000)   # metros

# Intersección: estaciones dentro de un polígono de estudio
area_estudio = gpd.read_file('area_estudio.shp').to_crs('EPSG:32719')
estaciones_en_area = gpd.sjoin(gdf_utm, area_estudio, how='inner', predicate='within')

# Distancia más cercana entre puntos y costa
gdf_utm['dist_costa_m'] = gdf_utm.geometry.apply(
    lambda p: costa.to_crs('EPSG:32719').distance(p).min()
)
```

## Exportar resultados

```python
# Guardar como shapefile
gdf_estaciones.to_file('estaciones_resultado.shp')

# Guardar como GeoJSON (más portable, sin limitación de nombre de columna)
gdf_estaciones.to_file('estaciones_resultado.geojson', driver='GeoJSON')

# Guardar raster modificado
with rasterio.open('batimetria.tif') as src:
    meta = src.meta.copy()
    datos = src.read(1).astype(float)

datos_suavizado = datos.copy()   # ... algún procesamiento

meta.update(dtype='float32')
with rasterio.open('batimetria_suavizada.tif', 'w', **meta) as dst:
    dst.write(datos_suavizado.astype('float32'), 1)
```

## Estadísticas zonales

Calcular estadísticas del raster dentro de cada polígono:

```python
from rasterstats import zonal_stats

# Profundidad media dentro de cada área de estudio
stats = zonal_stats(
    'areas_estudio.shp',
    'batimetria.tif',
    stats=['mean', 'min', 'max', 'std'],
    nodata=-9999
)

for area, s in zip(areas_estudio.itertuples(), stats):
    print(f"{area.nombre}: prof_media = {s['mean']:.1f} m")
```

!!! tip "Sistema de coordenadas"
    Antes de cualquier operación espacial (buffer, distancias, áreas), reproyectar todos los datos a un CRS métrico como UTM. Los cálculos de distancia en grados (WGS84) son incorrectos y varían con la latitud. Para Chile central usar EPSG:32719 (UTM zona 19 Sur).

!!! warning "Archivos shapefile"
    Un shapefile en realidad son varios archivos (`.shp`, `.shx`, `.dbf`, `.prj`). Al copiar o mover shapefiles, mover todos los archivos con el mismo nombre base. La alternativa moderna y más portable es GeoPackage (`.gpkg`) o GeoJSON.

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
