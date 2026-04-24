# Sintaxis básica

Python es un lenguaje de tipado dinámico e indentado. No necesita declarar tipos de variables ni usar llaves `{}` para delimitar bloques — la estructura del código se define por la indentación.

## Variables y tipos

Python detecta el tipo de una variable automáticamente al asignarla. No es necesario declararlo. Los tipos fundamentales son:

### float — número decimal

Representa cualquier número con parte decimal. Internamente usa 64 bits (doble precisión), lo que da ~15 dígitos significativos de precisión.

```python
velocidad   = 3.5       # float
temperatura = -1.8      # float (puede ser negativo)
proporcion  = 0.73      # float entre 0 y 1

type(velocidad)   # <class 'float'>
```

Se usa para mediciones físicas: velocidades, temperaturas, coordenadas, profundidades. Cualquier número que pueda tener decimales debe ser float.

!!! warning "Precisión de float"
    Los floats tienen un error de representación inherente. `0.1 + 0.2` en Python da `0.30000000000000004`, no `0.3`. Esto rara vez afecta el análisis de datos, pero sí puede causar sorpresas en comparaciones exactas. Usar `round()` o `np.isclose()` en vez de `==` para comparar floats.

### int — número entero

Número sin parte decimal. En Python 3 no tiene límite de tamaño.

```python
n_muestras  = 186       # int
profundidad = 7         # int (metros exactos)
indice      = 0         # int — los índices siempre son int

type(n_muestras)   # <class 'int'>
```

Se usa para contadores, índices, cantidades discretas (número de archivos, de celdas, de meses).

```python
# La división entre ints en Python 3 siempre da float
7 / 2      # 3.5   (float)
7 // 2     # 3     (int — división entera)
7 % 2      # 1     (int — resto)
```

### str — texto

Secuencia de caracteres. Se define con comillas simples o dobles (equivalentes).

```python
nombre_proyecto = "Los Vilos Oct 2025"
unidad          = 'm/s'
ruta            = r'C:\Users\Tomas\datos.csv'   # r"..." ignora las barras invertidas
```

### bool — booleano

Solo dos valores posibles: `True` o `False`. Es un caso especial de int (`True == 1`, `False == 0`).

```python
datos_validos = True
es_negativo   = velocidad < 0   # bool resultado de una comparación

# Se usa en condiciones
if datos_validos:
    procesar(df)
```

### None — ausencia de valor

Representa "sin valor". Equivalente a `NULL` en otras lenguas.

```python
resultado = None   # aún no calculado

# Verificar si algo es None
if resultado is None:
    print("Aún no hay resultado")
```

### Resumen y conversión entre tipos

```python
# Verificar tipo
type(3.5)     # <class 'float'>
type(23)      # <class 'int'>
type("texto") # <class 'str'>
type(True)    # <class 'bool'>

# Convertir
int(3.9)      # 3     — trunca, no redondea
float(23)     # 23.0
str(186)      # '186'
int("23")     # 23    — solo si el string es un número válido
bool(0)       # False — 0 es falso, cualquier otro número es True
bool("")      # False — string vacío es falso
```

### ¿Cuándo importa el tipo?

```python
# Concatenar string con número da error
nombre = "Profundidad: " + 7          # TypeError
nombre = "Profundidad: " + str(7)     # OK: "Profundidad: 7"
nombre = f"Profundidad: {7}"          # OK con f-string (convierte automático)

# Operaciones entre int y float dan float
3 + 1.5    # 4.5 (float)
7 * 2.0    # 14.0 (float)
```

## El punto (.) en Python

El punto es el operador de acceso en Python. Aparece constantemente pero tiene tres usos distintos que conviene distinguir desde el principio.

**1. Acceso a módulo** — llama una función o clase que vive dentro de un módulo importado:

```python
import numpy as np
import pandas as pd

np.array([1, 2, 3])      # función array del módulo numpy
pd.read_csv('datos.csv') # función read_csv del módulo pandas
```

**2. Método de objeto** — ejecuta una función que pertenece a un objeto específico (los paréntesis indican que es una llamada):

```python
velocidades = [0.3, 0.8, 0.1, 0.5]
velocidades.append(0.6)    # método append de la lista
velocidades.sort()         # método sort de la lista

df['vel'].mean()           # método mean de la Series de pandas
df.dropna()                # método dropna del DataFrame
```

**3. Atributo de objeto** — accede a una propiedad del objeto, sin llamarla (sin paréntesis):

```python
df.shape       # (filas, columnas) — es un dato, no una función
df.columns     # lista de nombres de columnas
arr.dtype      # tipo de dato del array NumPy
```

La diferencia entre método y atributo: si tiene paréntesis `()` es una llamada que ejecuta algo; si no los tiene es una propiedad que ya existe.

**Encadenamiento** — se pueden combinar varios niveles en una sola línea:

```python
doc.paragraphs[2].runs[0].text   # atributo del objeto dentro de una lista dentro de otro objeto
df['vel'].dropna().mean()        # método sobre el resultado de otro método
```

En MATLAB no existe este patrón — las funciones son independientes (`mean(vel)`, `size(df)`). En Python los objetos llevan sus propias funciones consigo.

## Strings (texto)

```python
empresa = "Compas Marine"
centro  = "Los Vilos"

# Concatenación
titulo = empresa + " — " + centro

# f-strings (la forma moderna y más legible)
titulo = f"{empresa} — {centro}"

# Formateo con decimales
promedio = 3.93
texto = f"Velocidad promedio: {promedio:.2f} m/s"
# → "Velocidad promedio: 3.93 m/s"

# Métodos útiles
"Los Vilos".upper()       # 'LOS VILOS'
"  texto  ".strip()       # 'texto'
"a,b,c".split(",")        # ['a', 'b', 'c']
"corrientes".replace("e", "a")  # 'corriantes'
```

## Listas

Las listas almacenan secuencias de elementos de cualquier tipo:

```python
profundidades = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
meses = ["sep", "oct", "nov", "dic", "ene", "feb", "mar"]

# Acceso por índice (empieza en 0, no en 1 como MATLAB)
profundidades[0]    # 3   — primer elemento
profundidades[-1]   # 23  — último elemento
profundidades[-2]   # 21  — penúltimo

# Operaciones
len(profundidades)          # 11
profundidades.append(25)    # agrega al final
profundidades.sort()        # ordena en lugar
sum(profundidades)          # suma
```

### Slicing — seleccionar rangos

La sintaxis es `[inicio:fin:paso]`. El índice `fin` **no se incluye**:

```python
p = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
#    0  1  2  3   4   5   6   7   8   9  10

p[2:5]    # [7, 9, 11]      — índices 2, 3, 4 (el 5 no entra)
p[:4]     # [3, 5, 7, 9]    — desde el inicio hasta el índice 3
p[7:]     # [17, 19, 21, 23] — desde el índice 7 hasta el final
p[::2]    # [3, 7, 11, 15, 19, 23] — uno de cada dos (paso 2)
p[::-1]   # [23, 21, ..., 3]       — invertir la lista
```

En NumPy y pandas el slicing funciona igual y se puede aplicar a filas y columnas:

```python
import numpy as np

A = np.array([[1, 2, 3, 4],
              [5, 6, 7, 8],
              [9, 10, 11, 12]])

A[0, :]      # [1, 2, 3, 4]   — primera fila, todas las columnas
A[:, 1]      # [2, 6, 10]     — todas las filas, columna 1
A[0:2, 1:3]  # [[2,3],[6,7]]  — filas 0-1, columnas 1-2
```

El equivalente en MATLAB sería `A(1,:)`, `A(:,2)`, `A(1:2, 2:3)` — la diferencia es que Python empieza en 0 y el índice final no se incluye.

## Tuplas

Las tuplas son secuencias **inmutables**: se definen igual que una lista pero con paréntesis, y no se pueden modificar después de creadas.

```python
coordenadas = (-31.9, -71.5)           # (lat, lon)
rango       = (0, 23)                  # profundidad mínima y máxima
rgb         = (30, 144, 255)           # color fijo

# Acceso — igual que lista
coordenadas[0]    # -31.9
coordenadas[-1]   # -71.5
```

**¿Por qué no simplemente usar una lista?** La inmutabilidad comunica intención: si algo es una tupla, el lector del código sabe que ese valor no va a cambiar. También tienen otro uso frecuente: las funciones que devuelven múltiples valores en Python devuelven una tupla.

```python
def estadisticas(datos):
    return np.mean(datos), np.std(datos)   # devuelve tupla

media, std = estadisticas(vel)   # desempaquetado automático
```

```python
# Diferencia clave con lista
lista = [1, 2, 3]
lista[0] = 99       # OK — las listas son mutables

tupla = (1, 2, 3)
tupla[0] = 99       # TypeError: 'tuple' object does not support item assignment
```

Se usa para: coordenadas geográficas, rangos fijos de profundidad o tiempo, pares clave-valor, y cualquier conjunto de valores relacionados que no deba cambiar.

## Diccionarios

Los diccionarios almacenan pares clave-valor. Son muy usados para configuración:

```python
config = {
    "empresa": "Compas Marine",
    "centro":  "Los Vilos",
    "lat":     -31.9,
    "lon":     -71.5,
    "prof_max": 23
}

# Acceso
config["empresa"]          # "Compas Marine"
config.get("lat", None)    # -31.9 (con valor por defecto si no existe)

# Modificar
config["prof_max"] = 25

# Iterar
for clave, valor in config.items():
    print(f"{clave}: {valor}")
```

## Indentación

Python usa la indentación (4 espacios) para delimitar bloques. No hay llaves ni `end`:

```python
# Correcto
if velocidad > 0.5:
    print("Velocidad alta")
    print("Revisar datos")

# Error — la indentación inconsistente produce IndentationError
if velocidad > 0.5:
print("Velocidad alta")   # ← falta indentación
```

## Comentarios

```python
# Comentario de una línea

velocidad_max = 0.6  # m/s — comentario al final de línea

"""
Comentario de
múltiples líneas
(también se usa como docstring de funciones)
"""
```

## Operadores

```python
# Aritméticos
3 + 2     # 5
10 / 3    # 3.333...
10 // 3   # 3 (división entera)
10 % 3    # 1 (módulo / resto)
2 ** 3    # 8 (potencia)

# Comparación
5 > 3     # True
5 == 5    # True (igualdad, no asignación)
5 != 4    # True

# Lógicos
True and False   # False
True or False    # True
not True         # False

# Útil con pandas: operadores por elemento
velocidad > 0.1          # Series de booleanos
(vel > 0.1) & (dir < 90) # AND elemento a elemento
```

## Referencias y copias

En MATLAB, asignar una variable siempre crea una copia independiente:

```matlab
% MATLAB
b = a(:, 1:3);   % b es una copia — modificar b no afecta a
```

En Python, asignar una variable **no copia** los objetos mutables (listas, arrays, DataFrames) — crea una segunda referencia al mismo objeto en memoria:

```python
a = [1, 2, 3, 4, 5]
b = a            # b apunta al mismo objeto que a
b[0] = 99
print(a)         # [99, 2, 3, 4, 5] — a también cambió
```

Para obtener una copia real, hay que pedirla explícitamente:

```python
# Listas
b = a.copy()
b = a[:]         # slice completo también copia

# NumPy
import numpy as np
A = np.array([[1, 2, 3, 4],
              [5, 6, 7, 8]])

B = A.copy()            # copia completa — equivalente a b = a en MATLAB
B = A[:, 0:3].copy()    # equivalente a b = A(:, 1:3) en MATLAB

# Sin .copy(), un slice de NumPy es una vista del original:
B = A[:, 0:3]    # B comparte memoria con A
B[0, 0] = 99     # modifica A también

# pandas
df2 = df.copy()
```

!!! warning "Vistas en NumPy"
    Un slice de NumPy sin `.copy()` es una **vista**: ocupa cero memoria extra y cualquier modificación afecta al array original. Útil para eficiencia, pero puede generar bugs si no se tiene en cuenta.

## Conversión de tipos

```python
int("23")        # 23
float("3.5")     # 3.5
str(186)         # "186"
list((1, 2, 3))  # [1, 2, 3]
```

!!! warning "Error frecuente"
    En Python 3, dividir dos enteros siempre devuelve float: `7 / 2 = 3.5`. Para división entera usa `//`.
