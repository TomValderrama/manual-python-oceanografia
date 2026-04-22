# Pandas

Pandas es la librería principal para manejo de datos tabulares. Su estructura central es el **DataFrame**: una tabla con filas y columnas etiquetadas, similar a una hoja de Excel pero operable desde código.

En el pipeline de Pelícanos, todos los datos de corrientes, viento y oleaje se manejan como DataFrames de Pandas.

```python
import pandas as pd
```

## Series y DataFrames

Una **Series** es una columna con índice. Un **DataFrame** es una tabla de Series con el mismo índice.

```python
# Series
velocidad = pd.Series([0.08, 0.09, 0.6, 0.07], name='velocidad')

# DataFrame desde diccionario
df = pd.DataFrame({
    'velocidad': [0.08, 0.09, 0.60, 0.07],
    'direccion': [  45,   90,  352,  180],
    'profundidad': [  3,    3,    7,    3],
})
```

## Explorar un DataFrame

```python
df.head()           # primeras 5 filas
df.tail(10)         # últimas 10 filas
df.shape            # (filas, columnas)
df.columns          # nombres de columnas
df.dtypes           # tipo de cada columna
df.describe()       # estadísticas básicas
df.info()           # resumen general: tipos, NaN, memoria
```

## Acceder a datos

```python
# Columna por nombre
df['velocidad']
df[['velocidad', 'direccion']]   # varias columnas

# Filas por posición (iloc)
df.iloc[0]          # primera fila
df.iloc[0:5]        # primeras 5 filas
df.iloc[2, 1]       # fila 2, columna 1

# Filas por etiqueta de índice (loc)
df.loc[0:4]
df.loc[:, 'velocidad':'direccion']   # rango de columnas
```

## Filtrado

```python
# Condición simple
df[df['velocidad'] > 0.5]

# Múltiples condiciones
df[(df['velocidad'] > 0.1) & (df['profundidad'] == 3)]
df[(df['direccion'] < 45) | (df['direccion'] > 315)]

# isin — valores en una lista
df[df['profundidad'].isin([3, 7, 15])]

# notna / isna
df[df['velocidad'].notna()]      # excluir NaN
df[df['velocidad'].isna()]       # solo NaN
```

## Series temporales

En oceanografía, el índice del DataFrame suele ser un `DatetimeIndex`. Esto permite filtrar y agrupar por tiempo de forma muy eficiente.

```python
# Crear índice temporal desde una columna
df['tiempo'] = pd.to_datetime(df['tiempo'])
df = df.set_index('tiempo')

# Filtrar por rango de fechas
df['2025-10':'2026-03']
df.loc['2025-10-01':'2026-03-30']

# Resamplear: promedios horarios, diarios, mensuales
df.resample('1h').mean()    # promedio cada hora
df.resample('1D').max()     # máximo diario
df.resample('1ME').mean()   # promedio mensual
```

### Timezone

Los datos del ADCP y la boya están en UTC. Para convertir a hora local (UTC-3):

```python
from datetime import timezone, timedelta

df.index = df.index.tz_localize('UTC')
df.index = df.index.tz_convert('America/Santiago')
```

## Operaciones por columna

```python
# Crear nuevas columnas
df['vel_nudos'] = df['velocidad'] * 1.944

# Operaciones sobre columnas existentes
df['u'] = df['velocidad'] * np.sin(np.radians(df['direccion']))
df['v'] = df['velocidad'] * np.cos(np.radians(df['direccion']))

# Reemplazar valores
df['velocidad'] = df['velocidad'].replace(-9999, np.nan)

# Aplicar función personalizada
def clasificar_beaufort(vel):
    if vel < 0.3:   return "calma"
    elif vel < 1.5: return "ventolina"
    elif vel < 3.3: return "brisa leve"
    else:           return "brisa moderada o más"

df['beaufort'] = df['velocidad'].apply(clasificar_beaufort)
```

## Estadísticas

```python
df['velocidad'].mean()
df['velocidad'].max()
df['velocidad'].std()
df['velocidad'].quantile(0.95)   # percentil 95

# Por columna
df.mean()
df.describe()

# Contar valores no nulos
df['velocidad'].count()
df['velocidad'].isna().sum()    # cantidad de NaN
```

## groupby — estadísticas por categoría

```python
# Estadísticas por profundidad
df.groupby('profundidad')['velocidad'].mean()
df.groupby('profundidad')['velocidad'].agg(['mean', 'max', 'std'])

# Estadísticas por mes
df.groupby(df.index.month)['velocidad'].mean()

# Por hora del día (patrón diurno)
df.groupby(df.index.hour)['velocidad'].mean()
```

### Ejemplo real: patrón diurno del viento

```python
patron_diurno = df.groupby(df.index.hour)['velocidad'].mean()
patron_diurno.index.name = 'hora'
```

## pivot_table — tabla de frecuencias

Las tablas de incidencia (velocidad × dirección) del informe se generan con pivot_table:

```python
# Tabla de frecuencia: velocidad × dirección
tabla = pd.pivot_table(
    df,
    values='velocidad',
    index='intervalo_vel',
    columns='octante',
    aggfunc='count',
    fill_value=0
)

# Normalizar a porcentaje
tabla_pct = tabla / tabla.values.sum() * 100
```

## merge y concat — combinar DataFrames

```python
# Concatenar DataFrames con la misma estructura (unir registros)
df_total = pd.concat([df_septiembre, df_octubre, df_noviembre])

# Merge por columna común (equivalente a JOIN de SQL)
df_merged = pd.merge(df_corrientes, df_oleaje, on='tiempo', how='inner')
```

## Manejar NaN

```python
df.dropna()                          # eliminar filas con cualquier NaN
df.dropna(subset=['velocidad'])      # solo si velocidad es NaN
df.fillna(0)                         # rellenar con 0
df['velocidad'].interpolate()        # interpolación lineal
df.ffill()                           # propagar último valor válido hacia adelante
```

## Leer y guardar datos

```python
# Leer
df = pd.read_csv('corrientes.csv', sep=';', parse_dates=['tiempo'])
df = pd.read_excel('corrientes.xlsx', sheet_name='VELOCIDAD')

# Guardar
df.to_csv('resultado.csv', index=False)
df.to_excel('resultado.xlsx', sheet_name='Datos', index=False)
```

!!! tip "Variable Explorer en Spyder"
    Hacer doble clic en un DataFrame en el Variable Explorer de Spyder abre una vista de tabla interactiva donde se pueden ordenar columnas y buscar valores, sin escribir ningún código adicional.
