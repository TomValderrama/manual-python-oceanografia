# Errores y debugging

Cuando Python encuentra un problema, detiene la ejecución y muestra un **traceback** — el rastro del error. Saber leer ese mensaje es la habilidad más práctica para trabajar con código: ahorra tiempo y evita buscar soluciones al problema equivocado.

## Anatomía de un traceback

```python
import pandas as pd

def cargar_datos(ruta):
    df = pd.read_csv(ruta)
    return df['velocidad'].mean()

resultado = cargar_datos('datos.csv')
```

Si `datos.csv` no existe, Python muestra:

```
Traceback (most recent call last):
  File "script.py", line 7, in <module>
    resultado = cargar_datos('datos.csv')
  File "script.py", line 4, in cargar_datos
    df = pd.read_csv(ruta)
  File ".../pandas/io/parsers.py", line 912, in read_csv
    return _read(filepath_or_buffer, kwds)
FileNotFoundError: [Errno 2] No such file or directory: 'datos.csv'
```

Cómo leerlo:

1. **Ignorar el medio** — las líneas del traceback van de la llamada más externa a la más interna. Lo útil está al principio (tu código) y al final (el error).
2. **Última línea** — el tipo de error y el mensaje. Aquí: `FileNotFoundError: No such file or directory: 'datos.csv'`. Es lo primero que hay que leer.
3. **Tu código en el traceback** — buscar las líneas que referencian tu archivo (`script.py`), no las de librerías. Ahí está el origen del problema.

## Errores más comunes

### `FileNotFoundError` — archivo no encontrado

```python
df = pd.read_csv('datos.csv')
# FileNotFoundError: No such file or directory: 'datos.csv'
```

**Causa**: la ruta no existe o el script corre desde un directorio distinto al que contiene el archivo.

**Diagnóstico**:
```python
import os
print(os.getcwd())           # directorio actual desde donde corre el script
print(os.path.exists('datos.csv'))  # True/False
```

---

### `KeyError` — clave o columna inexistente

```python
df['velocidat']
# KeyError: 'velocidat'
```

**Causa**: el nombre de columna está mal escrito, tiene espacios ocultos, o la columna no existe en ese DataFrame.

**Diagnóstico**:
```python
print(df.columns.tolist())   # ver exactamente qué columnas hay
```

---

### `IndexError` — índice fuera de rango

```python
lista = [1, 2, 3]
lista[5]
# IndexError: list index out of range
```

**Causa**: se intenta acceder a una posición que no existe. Recuerda que el índice máximo es `len(lista) - 1`.

---

### `TypeError` — tipo incorrecto para la operación

```python
"Profundidad: " + 7
# TypeError: can only concatenate str (not "int") to str
```

**Causa**: se mezclan tipos incompatibles. Solución: convertir explícitamente.

```python
"Profundidad: " + str(7)      # OK
f"Profundidad: {7}"           # OK con f-string
```

---

### `ValueError` — valor incorrecto aunque el tipo es correcto

```python
int("3.5")
# ValueError: invalid literal for int() with base 10: '3.5'

pd.to_datetime("no es una fecha")
# ValueError: ...
```

**Causa**: el tipo es correcto (es un string) pero el contenido no es válido para la operación pedida.

---

### `AttributeError` — atributo o método inexistente

```python
lista = [1, 2, 3]
lista.mean()
# AttributeError: 'list' object has no attribute 'mean'
```

**Causa**: se llama un método que no existe en ese tipo. `.mean()` existe en arrays NumPy y Series de pandas, no en listas de Python.

---

### `NameError` — variable no definida

```python
print(resultado)
# NameError: name 'resultado' is not defined
```

**Causa**: la variable nunca fue asignada, o la celda que la define no se ejecutó todavía.

---

### `IndentationError` — indentación incorrecta

```python
if velocidad > 0:
print("positivo")
# IndentationError: expected an indented block
```

**Causa**: falta la indentación después de `if`, `for`, `def`, etc.

---

### `ModuleNotFoundError` — librería no instalada

```python
import xarray
# ModuleNotFoundError: No module named 'xarray'
```

**Solución**:
```bash
pip install xarray
# o
conda install xarray
```

## Debugging en Spyder

Para errores que no se entienden solo con el traceback, el debugger permite pausar el código en cualquier punto e inspeccionar el estado de las variables.

### Breakpoints

Un **breakpoint** es una marca que le dice a Python "pausa aquí". En Spyder:

- Hacer clic en el número de línea donde se quiere pausar (aparece un punto rojo)
- O posicionar el cursor en la línea y presionar `F12`

Luego ejecutar el script con **`F5`** en modo debug (botón con el insecto 🐛, o menú **Debug → Debug file**).

### Controles del debugger

| Acción | Atajo | Descripción |
|---|---|---|
| Continuar hasta el próximo breakpoint | `F9` | Sigue corriendo |
| Ejecutar línea actual | `F10` | Avanza una línea |
| Entrar a la función | `F11` | Entra al interior de la función llamada |
| Salir de la función | `Shift+F11` | Sale de la función actual |
| Detener debugging | `Shift+F12` | Termina el modo debug |

### Inspeccionar variables en el debugger

Mientras el código está pausado, el **Variable Explorer** muestra el estado actual de todas las variables. También se puede escribir en la consola IPython para evaluar expresiones:

```python
# Con el código pausado, en la consola:
df.shape
df['velocidad'].isna().sum()
type(resultado)
```

## Estrategias de debugging

### 1. Leer el error antes de buscar en Google

El mensaje de error dice exactamente qué pasó y dónde. `KeyError: 'velocidad'` es más útil que buscar "pandas error". Leer el traceback completo toma 10 segundos y frecuentemente resuelve el problema.

### 2. Reducir el problema

Si el error ocurre en un loop que procesa 100 archivos, ejecutar primero con uno solo:

```python
# En vez de:
for archivo in archivos:
    procesar(archivo)

# Primero probar con el primero:
procesar(archivos[0])
```

### 3. Imprimir el estado intermedio

El método más simple y más efectivo:

```python
def procesar(df):
    print(f"shape: {df.shape}")        # ¿cuántas filas/columnas?
    print(f"columnas: {df.columns.tolist()}")
    print(f"NaN: {df.isna().sum()}")
    resultado = df['velocidad'].mean()
    print(f"resultado: {resultado}")
    return resultado
```

### 4. Verificar suposiciones

Los errores frecuentemente ocurren porque el dato no tiene el formato que se espera:

```python
# Antes de operar, verificar
print(type(df['velocidad'].iloc[0]))   # ¿es float o string?
print(df['velocidad'].dtype)           # ¿numpy float o object?
print(df.index[:3])                    # ¿cómo se ve el índice?
```

### 5. `assert` para detectar condiciones inesperadas

```python
df = pd.read_csv('datos.csv')
assert len(df) > 0, "El DataFrame está vacío"
assert 'velocidad' in df.columns, f"Columna 'velocidad' no encontrada. Columnas: {df.columns.tolist()}"
```

Si la condición es falsa, Python lanza un `AssertionError` con el mensaje — más claro que esperar a que falle más adelante.

## logging — alternativa a print para pipelines

`print` es suficiente para exploración interactiva. En un pipeline automático que corre sin supervisión, `logging` tiene ventajas concretas: cada mensaje tiene timestamp, nivel de severidad, y se puede escribir a un archivo sin tocar el código.

```python
import logging

# Configuración básica — una sola vez al inicio del script
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s  %(levelname)-8s  %(message)s',
    datefmt='%H:%M:%S',
    handlers=[
        logging.StreamHandler(),                        # consola
        logging.FileHandler('pipeline.log', 'w')       # archivo
    ]
)

logger = logging.getLogger(__name__)
```

```python
# Usar en el código en vez de print
logger.debug('Detalle interno útil para debugging')      # solo visible en nivel DEBUG
logger.info('Leyendo archivo corrientes_oct2024.csv')    # progreso normal
logger.warning('Columna "dir" tiene 3% de NaN')         # algo inesperado pero no fatal
logger.error('No se encontró el archivo de viento')     # error que impide continuar
```

```python
# Patrón para el pipeline de archivos
for archivo in archivos:
    try:
        df = pd.read_csv(archivo)
        logger.info(f'OK  {archivo}  ({len(df)} filas)')
    except FileNotFoundError:
        logger.warning(f'No encontrado: {archivo}')
    except Exception as e:
        logger.error(f'Error en {archivo}: {e}')
```

Salida en consola y en `pipeline.log`:
```
14:32:01  INFO      OK  oct2024.csv  (8640 filas)
14:32:02  INFO      OK  nov2024.csv  (8352 filas)
14:32:02  WARNING   No encontrado: dic2024.csv
14:32:03  INFO      OK  ene2025.csv  (8928 filas)
```

**Cuándo usar logging en vez de print**: cuando el script corre automáticamente (por ejemplo, desde un cron o un bat), cuando se necesita guardar el historial de ejecuciones, o cuando se quiere poder aumentar el nivel de detalle (`DEBUG`) sin modificar el código.

## Errores silenciosos

Los más difíciles de detectar son los que no producen error pero dan un resultado incorrecto. Ejemplos frecuentes:

```python
# División entera en vez de float (Python 2 vs 3)
7 / 2    # 3.5 en Python 3 — correcto
7 // 2   # 3   — si esto era lo que querías, bien; si no, error silencioso

# NaN que se propagan sin aviso
velocidad = np.array([1.0, np.nan, 3.0])
print(velocidad.mean())   # nan — no hay error, pero el resultado es inútil
print(np.nanmean(velocidad))  # 2.0 — correcto

# Filtrado que elimina más datos de los esperados
df_filtrado = df[df['velocidad'] > 0.5]
# Si df_filtrado está vacío, las operaciones siguientes dan NaN o error lejano
print(f"Filas después de filtrar: {len(df_filtrado)}")  # verificar siempre
```
