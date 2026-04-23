# Outputs de CROCO-ROMS

CROCO (Coastal and Regional Ocean COmmunity model) es un modelo oceánico regional que simula temperatura, salinidad y corrientes en un dominio definido por el usuario. Sus archivos de salida están en formato **NetCDF4**: un estándar científico para almacenar datos multidimensionales con coordenadas etiquetadas (tiempo, profundidad, latitud, longitud).

La herramienta estándar para trabajar con estos archivos en Python es **xarray**, que carga los datos de forma diferida: lee la estructura del archivo sin traer todos los valores a memoria, y accede a ellos solo cuando se necesitan.

## Instalación

```bash
pip install xarray netcdf4 matplotlib cartopy scipy
```

## Abrir un archivo y explorar su estructura

```python
import xarray as xr

ds = xr.open_dataset('croco_his.nc')
print(ds)
```

La salida muestra dimensiones, variables y atributos globales:

```
Dimensions:     (ocean_time: 365, s_rho: 20, eta_rho: 150, xi_rho: 200)
Data variables:
    temp     (ocean_time, s_rho, eta_rho, xi_rho) float32
    salt     (ocean_time, s_rho, eta_rho, xi_rho) float32
    u        (ocean_time, s_rho, eta_u, xi_u)     float32
    v        (ocean_time, s_rho, eta_v, xi_v)     float32
    zeta     (ocean_time, eta_rho, xi_rho)        float32
    lon_rho  (eta_rho, xi_rho)                    float64
    lat_rho  (eta_rho, xi_rho)                    float64
    h        (eta_rho, xi_rho)                    float64
```

| Variable | Descripción |
|----------|-------------|
| `temp` | Temperatura potencial (°C) |
| `salt` | Salinidad (PSU) |
| `u`, `v` | Corrientes E-O y N-S (m/s) en grillas desplazadas |
| `zeta` | Elevación de la superficie libre (m) |
| `h` | Batimetría — profundidad del fondo (m) |
| `lon_rho`, `lat_rho` | Coordenadas de cada celda de la grilla (2D) |

## Coordenadas verticales sigma

CROCO no usa profundidades fijas: usa **coordenadas sigma** (σ), que siguen la forma del fondo oceánico. En superficie σ = 0 y en el fondo σ = -1. Los N niveles se distribuyen entre estos extremos, con mayor resolución donde el modelo lo requiera (cerca de la superficie o del fondo).

La dimensión `s_rho` indexa estos niveles: `isel(s_rho=-1)` es el nivel de **superficie** y `isel(s_rho=0)` es el más cercano al **fondo**.

## Mapa de temperatura superficial

```python
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

sst = ds['temp'].isel(ocean_time=0, s_rho=-1).values   # array 2D
lon = ds['lon_rho'].values
lat = ds['lat_rho'].values

fig, ax = plt.subplots(figsize=(9, 7),
                       subplot_kw={'projection': ccrs.PlateCarree()})
ax.add_feature(cfeature.COASTLINE, linewidth=0.8)
ax.add_feature(cfeature.LAND, facecolor='lightgray')

pc = ax.pcolormesh(lon, lat, sst, cmap='RdYlBu_r', vmin=8, vmax=20,
                   transform=ccrs.PlateCarree())
plt.colorbar(pc, ax=ax, label='Temperatura (°C)')
ax.set_title('SST — CROCO')
plt.tight_layout()
plt.savefig('sst.png', dpi=150)
```

## Serie temporal en un punto

Para extraer la evolución temporal de una variable en la celda más cercana a una coordenada:

```python
import numpy as np

def celda_mas_cercana(ds, lon_target, lat_target):
    """Retorna los índices (eta, xi) de la celda más cercana al punto."""
    lon = ds['lon_rho'].values
    lat = ds['lat_rho'].values
    dist = np.sqrt((lon - lon_target)**2 + (lat - lat_target)**2)
    eta_idx, xi_idx = np.unravel_index(dist.argmin(), dist.shape)
    return int(eta_idx), int(xi_idx)

eta_i, xi_i = celda_mas_cercana(ds, lon_target=-72.5, lat_target=-41.5)

sst_serie = ds['temp'].isel(s_rho=-1, eta_rho=eta_i, xi_rho=xi_i).values
tiempo    = ds['ocean_time'].values

plt.figure(figsize=(11, 3))
plt.plot(tiempo, sst_serie, lw=0.8, color='steelblue')
plt.ylabel('Temperatura (°C)')
plt.title(f'SST en ({ds["lon_rho"].values[eta_i, xi_i]:.2f}°, '
          f'{ds["lat_rho"].values[eta_i, xi_i]:.2f}°)')
plt.tight_layout()
```

## Perfil vertical: convertir sigma a metros

Para graficar una variable en función de la profundidad real es necesario convertir los niveles sigma. La conversión usa la batimetría local (`h`), la superficie libre (`zeta`) y los parámetros del modelo:

```python
def sigma_a_profundidad(h, zeta, theta_s, theta_b, hc, N, vtransform=2):
    """
    Calcula la profundidad en metros de cada nivel sigma en un punto.
    Retorna array de longitud N (valores negativos bajo la superficie).
    """
    sc = (1.0 / N) * (np.arange(1, N + 1) - N - 0.5)

    if vtransform == 2:
        csrf = (1 - np.cosh(theta_s * sc)) / (np.cosh(theta_s) - 1)
        csb  = (np.exp(theta_b * sc) - 1) / (1 - np.exp(-theta_b))
        Cs   = (1 - theta_b) * csrf + theta_b * csb
        z0   = (hc * sc + h * Cs) / (hc + h)
        z    = zeta * (1 + z0) + h * z0
    else:
        cff1 = 1.0 / np.sinh(theta_s)
        Cs   = (1 - theta_b) * cff1 * np.sinh(theta_s * sc) + \
               theta_b * (0.5 / np.tanh(0.5 * theta_s) *
               np.tanh(theta_s * (sc + 0.5)) - 0.5)
        z    = hc * sc + (h - hc) * Cs + zeta * (1 + hc * sc / h + Cs)
    return z

# Leer parámetros desde los atributos globales del archivo
theta_s    = ds.attrs['theta_s']
theta_b    = ds.attrs['theta_b']
hc         = ds.attrs['hc']
N          = ds.dims['s_rho']
vtransform = int(ds.attrs.get('Vtransform', 2))

h_pt    = float(ds['h'].values[eta_i, xi_i])
zeta_pt = float(ds['zeta'].isel(ocean_time=0).values[eta_i, xi_i])
z = sigma_a_profundidad(h_pt, zeta_pt, theta_s, theta_b, hc, N, vtransform)

temp_perfil = ds['temp'].isel(ocean_time=0, eta_rho=eta_i, xi_rho=xi_i).values
salt_perfil = ds['salt'].isel(ocean_time=0, eta_rho=eta_i, xi_rho=xi_i).values

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(8, 6), sharey=True)
ax1.plot(temp_perfil, z, 'o-', color='tomato', ms=4)
ax1.set_xlabel('Temperatura (°C)'); ax1.set_ylabel('Profundidad (m)')
ax2.plot(salt_perfil, z, 'o-', color='steelblue', ms=4)
ax2.set_xlabel('Salinidad (PSU)')
for ax in (ax1, ax2):
    ax.invert_yaxis()
    ax.grid(True, lw=0.5)
plt.suptitle('Perfil T-S')
plt.tight_layout()
```

## Sección transversal

Un corte longitudinal a índice `eta_rho` constante:

```python
eta_corte = 75   # fila de la grilla (latitud fija)

temp_secc = ds['temp'].isel(ocean_time=0, eta_rho=eta_corte).values  # (N, xi_rho)
lon_secc  = ds['lon_rho'].values[eta_corte, :]
h_secc    = ds['h'].values[eta_corte, :]
zeta_secc = ds['zeta'].isel(ocean_time=0).values[eta_corte, :]

# Profundidad real en cada columna: shape (N, xi_rho)
z_secc = np.array([
    sigma_a_profundidad(h_secc[xi], zeta_secc[xi],
                        theta_s, theta_b, hc, N, vtransform)
    for xi in range(len(lon_secc))
]).T

fig, ax = plt.subplots(figsize=(12, 5))
pc = ax.pcolormesh(
    np.tile(lon_secc, (N, 1)),
    z_secc, temp_secc,
    cmap='RdYlBu_r', shading='auto'
)
plt.colorbar(pc, ax=ax, label='Temperatura (°C)')
ax.set_xlabel('Longitud'); ax.set_ylabel('Profundidad (m)')
ax.set_title('Sección de temperatura')
plt.tight_layout()
```

!!! tip "Lazy loading y memoria"
    `xr.open_dataset` no carga los datos en memoria hasta que los usas. Si solo necesitas algunas variables, extráelas antes de hacer cálculos:
    ```python
    temp = ds['temp'].isel(ocean_time=0, s_rho=-1).values   # solo aquí lee del disco
    ```

!!! tip "Múltiples archivos"
    CROCO suele generar un archivo por período. Para abrirlos como una sola serie temporal:
    ```python
    ds = xr.open_mfdataset('croco_his_Y*.nc', combine='by_coords')
    ```
