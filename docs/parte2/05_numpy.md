# NumPy

NumPy es la librería fundamental para cálculo numérico en Python. Su estructura central es el **array**: un arreglo multidimensional de valores del mismo tipo, mucho más eficiente que una lista de Python para operaciones matemáticas.

```python
import numpy as np
```

## Arrays

```python
# Desde una lista
velocidades = np.array([0.08, 0.09, 0.6, 0.07, 0.08, 0.09, 0.10])

# Array de ceros o unos
np.zeros(12)           # [0. 0. 0. ... 0.]
np.ones((3, 4))        # matriz 3×4 de unos

# Secuencias
np.arange(0, 24, 2)    # [0, 2, 4, ..., 22]
np.linspace(0, 1, 50)  # 50 puntos equiespaciados entre 0 y 1
```

### Arrays 2D — matrices

En corrientes se trabaja frecuentemente con matrices de `(tiempo × profundidad)`:

```python
# Matriz de velocidades: 5 ensembles × 11 profundidades
datos = np.array([
    [0.08, 0.09, 0.6,  0.07, 0.08, 0.09, 0.10, 0.09, 0.08, 0.07, 0.06],
    [0.07, 0.08, 0.55, 0.06, 0.07, 0.08, 0.09, 0.08, 0.07, 0.06, 0.05],
    # ...
])

datos.shape    # (5, 11) — filas × columnas
datos.ndim     # 2
datos.size     # 55 — total de elementos
```

## Operaciones vectorizadas

La ventaja de NumPy es que las operaciones se aplican a todo el array sin necesidad de un loop:

```python
vel = np.array([0.08, 0.09, 0.6, 0.07])

# Operaciones elemento a elemento
vel * 1.944        # convertir m/s a nudos
vel ** 2           # cuadrado de cada elemento
np.sqrt(vel)       # raíz cuadrada
np.log(vel)        # logaritmo natural

# Comparación — devuelve array de booleanos
vel > 0.5          # [False, False, True, False]
```

### Conversión velocidad/dirección ↔ componentes U, V

Esta operación es fundamental en oceanografía y aparece en múltiples scripts del pipeline:

```python
def uv_desde_vel_dir(velocidad, direccion_grad):
    """Convierte (velocidad, dirección) a componentes (U, V)."""
    dir_rad = np.radians(direccion_grad)
    u = velocidad * np.sin(dir_rad)   # componente Este
    v = velocidad * np.cos(dir_rad)   # componente Norte
    return u, v

def vel_dir_desde_uv(u, v):
    """Convierte (U, V) a (velocidad, dirección)."""
    velocidad  = np.sqrt(u**2 + v**2)
    direccion  = np.degrees(np.arctan2(u, v)) % 360
    return velocidad, direccion
```

## Indexación y slicing

```python
prof = np.array([3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23])

prof[0]        # 3  — primer elemento
prof[-1]       # 23 — último
prof[2:5]      # [7, 9, 11]
prof[::2]      # [3, 7, 11, 15, 19, 23] — cada dos

# En 2D: [fila, columna]
datos[0, :]    # primera fila completa (ensemble 0, todas las profundidades)
datos[:, 2]    # columna 2 completa (todos los ensembles, profundidad 7 m)
datos[1:3, 3:6]  # submatriz
```

### Indexación booleana — filtrado

```python
vel = np.array([0.08, 0.09, 0.6, 0.07, 0.55, 0.09])

# Seleccionar solo los valores > 0.5
vel[vel > 0.5]         # [0.6, 0.55]

# Reemplazar valores fuera de rango con NaN
vel[vel > 0.5] = np.nan
```

## Estadísticas

```python
vel = np.array([0.08, 0.09, 0.60, 0.07, 0.08])

np.mean(vel)        # media
np.median(vel)      # mediana
np.std(vel)         # desviación estándar
np.max(vel)         # máximo
np.min(vel)         # mínimo
np.percentile(vel, 95)  # percentil 95

np.argmax(vel)      # índice del máximo → 2
```

### Funciones que ignoran NaN

Cuando los datos tienen valores faltantes (`NaN`), usar las versiones `nan*`:

```python
np.nanmean(vel)
np.nanmax(vel)
np.nanstd(vel)
np.nanpercentile(vel, 95)
```

### Estadísticas por eje en matrices

```python
datos.mean(axis=0)   # media por profundidad (a lo largo del tiempo)
datos.mean(axis=1)   # media por ensemble (a lo largo de profundidades)
datos.max(axis=0)    # máximo por profundidad
```

## Funciones trigonométricas

NumPy trabaja en radianes. Para datos de dirección oceánica (en grados):

```python
np.radians(180)      # π
np.degrees(np.pi)    # 180.0

np.sin(np.radians(90))   # 1.0
np.cos(np.radians(0))    # 1.0

# arctan2 — dirección del vector (U, V)
u, v = 0.5, 0.5
direccion = np.degrees(np.arctan2(u, v)) % 360   # 45.0°
```

## NaN — valores faltantes

```python
np.nan                      # valor especial "Not a Number"
np.isnan(vel)               # array booleano: True donde hay NaN
np.isnan(vel).sum()         # cantidad de NaN
~np.isnan(vel)              # máscara de datos válidos

# Contar datos válidos
datos_validos = vel[~np.isnan(vel)]
```

## Operaciones útiles

```python
# Diferencia entre elementos consecutivos
np.diff(np.array([1, 3, 6, 10]))   # [2, 3, 4]

# Concatenar arrays
a = np.array([1, 2, 3])
b = np.array([4, 5, 6])
np.concatenate([a, b])             # [1, 2, 3, 4, 5, 6]

# Apilar matrices verticalmente
np.vstack([datos[:2, :], datos[3:, :]])

# Ordenar
np.sort(vel)                       # copia ordenada
vel.argsort()                      # índices que ordenarían el array

# Redondear
np.round(3.14159, 2)               # 3.14
```

!!! tip "NumPy vs listas de Python"
    Para operaciones matemáticas sobre grandes conjuntos de datos, NumPy es entre 10 y 100 veces más rápido que un loop sobre una lista Python. En series temporales de 6 meses con datos cada 10 minutos (~26.000 registros), esa diferencia es significativa.
