# Estadísticas circulares

Los datos de dirección (viento, corrientes, oleaje) son **circulares**: 0° y 360° son el mismo ángulo, por lo que promediar linealmente da resultados absurdos. Si una serie tiene mediciones de 10° y 350°, el promedio lineal es 180° (Sur), pero el promedio circular correcto es 0° (Norte). Python incluye herramientas para manejar esta circularidad correctamente.

## Media y desviación estándar circular

`scipy.stats` provee `circmean` y `circstd` que trabajan directamente en grados o radianes:

```python
from scipy.stats import circmean, circstd
import numpy as np

# Las funciones esperan radianes por defecto; high/low definen el rango
direcciones_deg = np.array([350, 5, 10, 355, 2, 358])

media_circ = circmean(direcciones_deg, high=360, low=0)
std_circ   = circstd( direcciones_deg, high=360, low=0)

print(f"Media circular:  {media_circ:.1f}°")
print(f"Desv. estándar:  {std_circ:.1f}°")
```

### Cálculo manual con vectores unitarios

El mismo resultado se obtiene convirtiendo cada ángulo a un vector unitario y promediando sus componentes:

```python
def media_circular(angulos_deg):
    rad = np.radians(angulos_deg)
    sin_m = np.nanmean(np.sin(rad))
    cos_m = np.nanmean(np.cos(rad))
    media = np.degrees(np.arctan2(sin_m, cos_m)) % 360
    return media

def concentracion_circular(angulos_deg):
    """Longitud del vector resultante medio (R̄). Rango [0, 1]: 1 = perfectamente concentrado."""
    rad = np.radians(angulos_deg)
    sin_m = np.nanmean(np.sin(rad))
    cos_m = np.nanmean(np.cos(rad))
    return np.sqrt(sin_m**2 + cos_m**2)

print(f"Media:        {media_circular(direcciones_deg):.1f}°")
print(f"Concentración R̄: {concentracion_circular(direcciones_deg):.3f}")
```

## Dirección predominante

La dirección predominante no es necesariamente la media circular; en vientos bimodales (p. ej. brisa diurna que alterna Norte/Sur) la media puede apuntar a un sector vacío. En ese caso se usa la **moda** por octante:

```python
def direccion_predominante(direcciones_deg, n_sectores=8):
    """Retorna el centro del sector con mayor frecuencia."""
    ancho = 360 / n_sectores
    sectores = (np.floor((direcciones_deg % 360) / ancho) * ancho + ancho / 2).astype(int)
    valores, conteos = np.unique(sectores, return_counts=True)
    return valores[np.argmax(conteos)]

print(f"Dirección predominante: {direccion_predominante(direcciones_deg)}°")
```

## Diferencia angular

Para calcular la diferencia entre dos ángulos de forma correcta (resultado siempre en [-180°, 180°]):

```python
def diferencia_angular(a, b):
    """Diferencia a - b en el rango [-180, 180]."""
    diff = (a - b + 180) % 360 - 180
    return diff

# Ejemplo: diferencia entre dirección modelada y observada
dir_modelo = 320.0
dir_obs    = 15.0
print(f"Diferencia: {diferencia_angular(dir_modelo, dir_obs):.1f}°")
# → -55.0° (el modelo es 55° más hacia el oeste)
```

## Error cuadrático medio circular

Métrica estándar para evaluar el desempeño de un modelo de dirección:

```python
def rmse_circular(dir_modelo, dir_obs):
    diffs = diferencia_angular(np.asarray(dir_modelo), np.asarray(dir_obs))
    return np.sqrt(np.nanmean(diffs**2))

# Comparar dirección de corriente modelada vs. medida
rmse_dir = rmse_circular(df['dir_modelo'], df['dir_obs'])
print(f"RMSE direccional: {rmse_dir:.1f}°")
```

## Estadísticas por sector en el pipeline

En el autoinforme de corrientes se calculan estadísticas separadas por octante para la tabla de incidencia:

```python
import pandas as pd

def tabla_incidencia(df, col_vel, col_dir, n_sectores=8):
    """
    Retorna DataFrame con frecuencia, velocidad media y máxima por sector.
    """
    ancho = 360 / n_sectores
    nombres_sectores = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO']

    # Asignar sector a cada registro
    df = df.copy()
    df['sector_idx'] = (np.floor((df[col_dir] % 360) / ancho)).astype(int) % n_sectores
    df['sector'] = df['sector_idx'].map(dict(enumerate(nombres_sectores)))

    resumen = df.groupby('sector').agg(
        n=(col_vel, 'count'),
        vel_media=(col_vel, 'mean'),
        vel_max=(col_vel, 'max')
    )
    resumen['frecuencia_%'] = (resumen['n'] / len(df) * 100).round(1)

    return resumen[['frecuencia_%', 'vel_media', 'vel_max']]

tabla = tabla_incidencia(df_corrientes, 'velocidad', 'direccion')
print(tabla.to_string())
```

## Histograma direccional

Visualizar la distribución de direcciones en una barra circular es más informativo que un histograma cartesiano:

```python
import matplotlib.pyplot as plt

def histograma_direccional(direcciones_deg, n_sectores=16, titulo=''):
    ancho = 360 / n_sectores
    bordes = np.arange(0, 361, ancho)
    conteos, _ = np.histogram(direcciones_deg % 360, bins=bordes)
    centros = bordes[:-1] + ancho / 2

    fig, ax = plt.subplots(subplot_kw={'projection': 'polar'}, figsize=(6, 6))
    ax.set_theta_zero_location('N')
    ax.set_theta_direction(-1)

    theta = np.radians(centros)
    ax.bar(theta, conteos / len(direcciones_deg) * 100,
           width=np.radians(ancho * 0.85),
           color='steelblue', edgecolor='white', alpha=0.8)

    ax.set_title(titulo or 'Distribución direccional (%)', pad=15)
    return fig, ax
```

!!! tip "Calma o datos faltantes"
    Cuando la velocidad es cero (calma), la dirección no tiene significado físico. Antes de calcular estadísticas circulares, filtrar los registros con velocidad inferior al umbral de arranque del instrumento (típicamente 0.02 m/s en correntómetros, 0.5 m/s en anemómetros).

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
