# Coordenadas y mapas

La visualización geoespacial en el pipeline incluye dos tareas: convertir coordenadas entre sistemas de referencia (UTM ↔ geográfico) y generar mapas de contexto para el informe. Los mapas sitúan la zona de estudio, marcan las estaciones y muestran resultados con color codificado por variable.

## Conversión UTM ↔ lat/lon con pyproj

```python
from pyproj import Transformer

# Definir transformador WGS84 ↔ UTM 19S
wgs84_a_utm  = Transformer.from_crs('EPSG:4326', 'EPSG:32719', always_xy=True)
utm_a_wgs84  = Transformer.from_crs('EPSG:32719', 'EPSG:4326', always_xy=True)

# Convertir un punto geográfico a UTM
lon, lat = -71.52, -31.90
este, norte = wgs84_a_utm.transform(lon, lat)
print(f"Este: {este:.1f} m, Norte: {norte:.1f} m")

# Convertir de vuelta
lon2, lat2 = utm_a_wgs84.transform(este, norte)
print(f"Lon: {lon2:.6f}°, Lat: {lat2:.6f}°")
```

### Convertir un DataFrame de coordenadas

```python
import pandas as pd
from pyproj import Transformer

def utm_a_geo(df, col_este='Este', col_norte='Norte', zona_utm='EPSG:32719'):
    """Agrega columnas Lon y Lat a un DataFrame con coordenadas UTM."""
    t = Transformer.from_crs(zona_utm, 'EPSG:4326', always_xy=True)
    lons, lats = t.transform(df[col_este].values, df[col_norte].values)
    df = df.copy()
    df['Lon'] = lons
    df['Lat'] = lats
    return df

df_estaciones = utm_a_geo(df_estaciones)
```

## Mapa de contexto con GeoPandas y Matplotlib

```python
import geopandas as gpd
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as mcolors
import numpy as np

def mapa_estaciones(gdf_estaciones, col_valor, titulo='',
                    ruta_costa='costa_chile.shp', ruta_salida=None):
    """
    Genera un mapa con la línea de costa y las estaciones
    coloreadas por col_valor.
    """
    costa = gpd.read_file(ruta_costa)

    fig, ax = plt.subplots(figsize=(8, 10))

    # Línea de costa
    costa.plot(ax=ax, color='darkgreen', linewidth=0.5, alpha=0.7)

    # Estaciones coloreadas por el valor de interés
    vmin = gdf_estaciones[col_valor].min()
    vmax = gdf_estaciones[col_valor].max()
    norm = mcolors.Normalize(vmin=vmin, vmax=vmax)
    cmap = cm.YlOrRd

    sc = ax.scatter(
        gdf_estaciones.geometry.x,
        gdf_estaciones.geometry.y,
        c=gdf_estaciones[col_valor],
        cmap=cmap, norm=norm,
        s=80, zorder=5, edgecolors='black', linewidths=0.5
    )

    # Etiquetas de estación
    for _, row in gdf_estaciones.iterrows():
        ax.annotate(
            row['nombre'],
            xy=(row.geometry.x, row.geometry.y),
            xytext=(5, 5), textcoords='offset points',
            fontsize=8
        )

    plt.colorbar(sc, ax=ax, label=col_valor, shrink=0.6)

    ax.set_xlabel('Longitud (°)')
    ax.set_ylabel('Latitud (°)')
    ax.set_title(titulo)
    ax.grid(True, linestyle='--', alpha=0.4)
    fig.tight_layout()

    if ruta_salida:
        fig.savefig(ruta_salida, dpi=150, bbox_inches='tight')
        plt.close(fig)

    return fig, ax
```

## Mapa de fondo con contextily (imágenes de satélite/OpenStreetMap)

```python
import contextily as ctx

fig, ax = plt.subplots(figsize=(9, 9))

# Graficar estaciones (en WebMercator EPSG:3857)
gdf_web = gdf_estaciones.to_crs('EPSG:3857')
gdf_web.plot(ax=ax, color='red', markersize=60, zorder=4)

# Agregar mapa base desde internet
ctx.add_basemap(ax, source=ctx.providers.CartoDB.Positron, zoom=10)

ax.set_axis_off()
ax.set_title('Zona de estudio')
```

!!! warning "contextily requiere internet"
    `contextily` descarga las teselas del mapa desde servidores externos. En equipos sin conexión usar el shapefile de costa en su lugar.

## Grilla de campo vectorial (corrientes)

Para visualizar un campo de corrientes interpolado en una grilla:

```python
from scipy.interpolate import griddata

# Puntos de medición dispersos
lons = gdf_estaciones.geometry.x.values
lats = gdf_estaciones.geometry.y.values
u_vals = gdf_estaciones['u_media'].values   # componente E-O
v_vals = gdf_estaciones['v_media'].values   # componente N-S

# Grilla regular de interpolación
lon_grid = np.linspace(lons.min() - 0.1, lons.max() + 0.1, 30)
lat_grid = np.linspace(lats.min() - 0.1, lats.max() + 0.1, 30)
LON, LAT = np.meshgrid(lon_grid, lat_grid)

U = griddata((lons, lats), u_vals, (LON, LAT), method='linear')
V = griddata((lons, lats), v_vals, (LON, LAT), method='linear')

fig, ax = plt.subplots(figsize=(9, 9))
ax.quiver(LON, LAT, U, V, np.sqrt(U**2 + V**2),
          cmap='YlOrRd', scale=5, width=0.003, alpha=0.8)
ax.scatter(lons, lats, c='black', s=20, zorder=5)
ax.set_xlabel('Longitud (°)')
ax.set_ylabel('Latitud (°)')
ax.set_title('Campo de corriente media superficial')
ax.set_aspect('equal')
```

## Recortar raster a área de estudio

```python
import rasterio
from rasterio.mask import mask
import geopandas as gpd
from shapely.geometry import mapping

area = gpd.read_file('area_estudio.shp').to_crs('EPSG:4326')

with rasterio.open('batimetria_nacional.tif') as src:
    out_image, out_transform = mask(
        src,
        [mapping(geom) for geom in area.geometry],
        crop=True,
        nodata=np.nan
    )
    out_meta = src.meta.copy()

out_meta.update({
    'driver': 'GTiff',
    'height': out_image.shape[1],
    'width':  out_image.shape[2],
    'transform': out_transform
})

with rasterio.open('batimetria_zona.tif', 'w', **out_meta) as dst:
    dst.write(out_image)
```

## Calcular distancia a la costa

```python
from pyproj import Geod

geod = Geod(ellps='WGS84')

def distancia_a_la_costa_km(lon_estacion, lat_estacion, gdf_costa):
    """
    Calcula la distancia mínima en km de un punto a la línea de costa.
    """
    gdf_utm = gdf_costa.to_crs('EPSG:32719')
    from shapely.geometry import Point
    punto_utm = gpd.GeoDataFrame(geometry=[Point(lon_estacion, lat_estacion)],
                                  crs='EPSG:4326').to_crs('EPSG:32719').geometry[0]
    dist_m = gdf_utm.geometry.distance(punto_utm).min()
    return dist_m / 1000

for _, row in gdf_estaciones.iterrows():
    d = distancia_a_la_costa_km(row.geometry.x, row.geometry.y, costa)
    print(f"{row['nombre']}: {d:.1f} km de la costa")
```

!!! tip "Selección del sistema de coordenadas"
    Para Chile, UTM zona 19 Sur (EPSG:32719) cubre desde 66°O hasta 60°O, incluyendo toda la costa continental. La zona 18 Sur (EPSG:32718) cubre desde 72°O hasta 66°O y es necesaria para el extremo sur y la región de Los Lagos. Verificar siempre que los datos de entrada estén en el CRS correcto antes de operar.
