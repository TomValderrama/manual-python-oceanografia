# Manual de Python para Oceanografía

Manual práctico de Python aplicado al procesamiento de datos oceanográficos, basado en el código real del pipeline de [Pelícanos Oceanografía](https://github.com/TomValderrama).

## Contenidos

| Parte | Capítulos |
|-------|-----------|
| **I — Fundamentos** | Entorno Spyder, sintaxis, control de flujo, funciones y módulos |
| **II — Manejo de datos** | NumPy, Pandas, lectura de archivos (CSV, Excel, .mat, Word) |
| **III — Visualización** | Matplotlib, rosas de viento, figuras para informes |
| **IV — Análisis oceanográfico** | Estadísticas circulares, análisis espectral (FFT), filtros |
| **V — Automatización de informes** | python-docx, plantillas con placeholders, importación dinámica |
| **VI — Datos geoespaciales** | Rasterio, GeoPandas, coordenadas y mapas base |

## Ver el manual

### Localmente

```bash
pip install mkdocs-material
mkdocs serve
```

Abrir en el navegador: [Manual](https://tomvalderrama.github.io/manual/)

### En línea

Próximamente en GitHub Pages.

## Requisitos

```bash
pip install numpy pandas matplotlib scipy openpyxl python-docx windrose rasterio geopandas pyproj contextily
```
