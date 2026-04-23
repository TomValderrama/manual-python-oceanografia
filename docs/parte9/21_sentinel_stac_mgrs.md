# Sentinel-2: API STAC de Copernicus y análisis de cobertura MGRS

**Sentinel-2** es el satélite de observación terrestre de la Agencia Espacial Europea (ESA). Tiene un ciclo de revisita de 5 días, captura imágenes a 10 m de resolución en el espectro visible e infrarrojo, y los datos son de libre acceso.

## El sistema de tiles MGRS

Las imágenes Sentinel-2 se organizan en el sistema **MGRS** (*Military Grid Reference System*): una grilla mundial de celdas de 100 km × 100 km identificadas por un código alfanumérico (por ejemplo `19HBB`, `18HYE`). Cada imagen descargada corresponde a un tile específico. Conocer qué tiles cubren tu zona de estudio es el primer paso antes de buscar o descargar imágenes.

## La API STAC de Copernicus

La plataforma **Copernicus Data Space Ecosystem** (sucesor de SciHub desde 2023) expone su catálogo de imágenes mediante el protocolo **STAC** (*SpatioTemporal Asset Catalog*): un estándar JSON para búsqueda de datos satelitales por área geográfica, período y colección. Solo se necesita Python — sin cuenta, sin Google, sin credenciales para consultar metadatos.

```bash
pip install pystac-client geopandas matplotlib shapely
```

## Buscar imágenes en un área

```python
import pystac_client

client = pystac_client.Client.open(
    "https://catalogue.dataspace.copernicus.eu/stac"
)

# Bounding box: [lon_min, lat_min, lon_max, lat_max]
BBOX = [-73.2, -35.3, -68.8, -31.3]   # RM, Valparaíso y O'Higgins

resultados = client.search(
    collections=["sentinel-2-l2a"],
    bbox=BBOX,
    datetime="2024-01-01/2024-01-31",
)
items = list(resultados.items())
print(f"Imágenes encontradas: {len(items)}")
```

## Extraer metadatos de cada imagen

Cada resultado (*item*) tiene propiedades de la escena. Las más útiles:

```python
import pandas as pd

registros = []
for item in items:
    p = item.properties
    registros.append({
        "id":        item.id,
        "datetime":  p.get("datetime"),
        "mgrs_tile": p.get("grid:code", "").replace("MGRS-", ""),
        "cloud_pct": p.get("eo:cloud_cover"),
        "geometry":  item.geometry,       # dict GeoJSON con el polígono del tile
    })

df = pd.DataFrame(registros)
df["datetime"] = pd.to_datetime(df["datetime"])
print(df[["datetime", "mgrs_tile", "cloud_pct"]].head(10))
```

| Campo | Descripción |
|-------|-------------|
| `mgrs_tile` | Código del tile (ej. `19HBB`) |
| `cloud_pct` | Porcentaje de cobertura de nubes (0–100) |
| `geometry` | Polígono del tile en coordenadas geográficas |

## Descarga masiva de metadatos: mes a mes

Para un análisis de largo plazo lo eficiente es descargar solo metadatos y guardar un CSV local para no repetir la consulta:

```python
import time, json
import pystac_client
import pandas as pd
from datetime import date

BBOX  = [-73.2, -35.3, -68.8, -31.3]
AÑOS  = [2021, 2022, 2023, 2024]
OUT   = "metadata_sentinel2.csv"

client = pystac_client.Client.open(
    "https://catalogue.dataspace.copernicus.eu/stac"
)

registros = []
for year in AÑOS:
    for month in range(1, 13):
        d0 = date(year, month, 1)
        d1 = date(year, month + 1, 1) if month < 12 else date(year + 1, 1, 1)
        print(f"{year}-{month:02d}...", end=" ", flush=True)

        for intento in range(3):
            try:
                items = list(client.search(
                    collections=["sentinel-2-l2a"],
                    bbox=BBOX,
                    datetime=f"{d0}/{d1}",
                ).items())
                break
            except Exception:
                time.sleep(10 * (intento + 1))
                client = pystac_client.Client.open(
                    "https://catalogue.dataspace.copernicus.eu/stac"
                )

        print(f"{len(items)} imágenes")
        for item in items:
            p = item.properties
            registros.append({
                "year":      year,
                "month":     month,
                "mgrs_tile": p.get("grid:code", "").replace("MGRS-", ""),
                "cloud_pct": p.get("eo:cloud_cover"),
                "datetime":  p.get("datetime"),
                "geometry":  json.dumps(item.geometry),
            })

df = pd.DataFrame(registros)
df.to_csv(OUT, index=False)
print(f"Guardado: {OUT}  ({len(df)} filas)")
```

## Contar imágenes por tile y mes

```python
import pandas as pd

df = pd.read_csv("metadata_sentinel2.csv")

conteo = (df.groupby(["year", "month", "mgrs_tile"])
            .size()
            .reset_index(name="n_images"))

# Tiles con mayor cobertura total
por_tile = df.groupby("mgrs_tile").size().sort_values(ascending=False)
print(por_tile.head(10).to_string())
```

## Intersectar tiles con una región de estudio

Para quedarse solo con los tiles que caen dentro de tu zona de interés:

```python
import json, geopandas as gpd
from shapely.geometry import shape
from shapely.ops import unary_union

df = pd.read_csv("metadata_sentinel2.csv")

# Reconstruir polígono real de cada tile (unión de todas sus escenas)
df["geom_obj"] = df["geometry"].apply(lambda g: shape(json.loads(g)))
tile_geoms = df.groupby("mgrs_tile")["geom_obj"].apply(unary_union)

tiles_gdf  = gpd.GeoDataFrame({"geometry": tile_geoms}, crs="EPSG:4326")
region_gdf = gpd.read_file("mi_region.geojson")   # polígono de la zona de estudio

tiles_en_region = set(
    gpd.sjoin(tiles_gdf, region_gdf[["geometry"]],
              how="inner", predicate="intersects").index.unique()
)
print(f"Tiles dentro de la región: {len(tiles_en_region)}")
```

## Visualizar cobertura mensual en un mapa

```python
import matplotlib.pyplot as plt
import geopandas as gpd

mes    = df[(df["year"] == 2024) & (df["month"] == 1)]
conteo = mes.groupby("mgrs_tile").size().reset_index(name="n")

tiles_mes = gpd.GeoDataFrame(
    conteo.assign(geometry=conteo["mgrs_tile"].map(tile_geoms)),
    crs="EPSG:4326"
).dropna(subset=["geometry"])

fig, ax = plt.subplots(figsize=(8, 9))
tiles_mes.plot(ax=ax, column="n", cmap="YlOrRd",
               edgecolor="gray", linewidth=0.4, alpha=0.85,
               legend=True, legend_kwds={"label": "Imágenes / tile"})
region_gdf.boundary.plot(ax=ax, edgecolor="steelblue", linewidth=0.8)
ax.set_title("Cobertura Sentinel-2 — Enero 2024")
ax.set_xlabel("Longitud"); ax.set_ylabel("Latitud")
plt.tight_layout()
plt.savefig("cobertura_enero_2024.png", dpi=150)
```

!!! tip "Filtrar por nubosidad antes de descargar"
    La nubosidad está disponible en los metadatos, lo que permite filtrar antes de descargar cualquier imagen:
    ```python
    df_claras = df[df["cloud_pct"] < 20]
    print(f"Imágenes con <20% nubes: {len(df_claras)} de {len(df)}")
    ```

!!! tip "Sin cuenta requerida"
    La API STAC de Copernicus es pública: no requiere registro para consultar metadatos. La cuenta gratuita en `dataspace.copernicus.eu` solo es necesaria si se quieren descargar los archivos de imagen completos (`.SAFE`, `.tif`).
