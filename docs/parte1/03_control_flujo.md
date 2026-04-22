# Control de flujo

El control de flujo determina qué código se ejecuta y cuándo. En procesamiento oceanográfico se usa constantemente: para filtrar datos, iterar sobre profundidades, manejar errores de lectura, etc.

## Condicionales: if / elif / else

```python
velocidad = 0.35

if velocidad >= 0.5:
    categoria = "alta"
elif velocidad >= 0.2:
    categoria = "moderada"
else:
    categoria = "baja"

print(f"Velocidad {categoria}: {velocidad} m/s")
```

### Condicional en una línea (ternario)

```python
etiqueta = "válido" if velocidad > 0 else "calma"
```

## Bucles: for

El bucle `for` itera sobre cualquier secuencia: listas, rangos, columnas de un DataFrame, archivos, etc.

```python
profundidades = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]

for prof in profundidades:
    print(f"Procesando capa a {prof} m")
```

### range()

```python
# range(inicio, fin, paso) — fin no se incluye
for i in range(0, 12):        # 0 a 11
    print(i)

for i in range(0, 24, 2):     # 0, 2, 4, ..., 22
    print(i)
```

### enumerate() — índice + valor

```python
meses = ["sep", "oct", "nov", "dic", "ene", "feb", "mar"]

for i, mes in enumerate(meses):
    print(f"Mes {i+1}: {mes}")
```

### Iterar sobre un diccionario

```python
stats = {"media": 3.93, "maxima": 18.2, "std": 2.8}

for nombre, valor in stats.items():
    print(f"{nombre}: {valor:.2f}")
```

## Bucles: while

```python
intentos = 0
while intentos < 3:
    print(f"Intento {intentos + 1}")
    intentos += 1
```

## break y continue

```python
for prof in profundidades:
    if prof > 15:
        break       # sale del bucle al llegar a 17 m

for prof in profundidades:
    if prof == 9:
        continue    # salta esta iteración, continúa con la siguiente
    print(prof)
```

## List comprehensions

Una forma compacta de construir listas a partir de otra secuencia. Muy usadas en el procesamiento de datos para transformar o filtrar colecciones:

```python
profundidades = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]

# Sin comprehension
dobles = []
for p in profundidades:
    dobles.append(p * 2)

# Con comprehension (equivalente, más conciso)
dobles = [p * 2 for p in profundidades]

# Con filtro
superficiales = [p for p in profundidades if p <= 7]
# → [3, 5, 7]
```

### Ejemplo real del pipeline

```python
# Buscar todos los archivos Excel de corrientes en un directorio
import os
archivos = [f for f in os.listdir(carpeta) if f.endswith('.xlsx')]
```

## Manejo de errores: try / except

Fundamental cuando se leen archivos o datos que pueden estar incompletos o corruptos:

```python
try:
    df = pd.read_csv('corrientes.csv')
except FileNotFoundError:
    print("Archivo no encontrado")
except Exception as e:
    print(f"Error inesperado: {e}")
```

### finally — código que siempre se ejecuta

```python
try:
    archivo = open('datos.txt')
    datos = archivo.read()
except FileNotFoundError:
    print("No se encontró el archivo")
finally:
    print("Proceso terminado")  # se ejecuta siempre
```

### Ejemplo real del pipeline

En el código de automatización de informes, el try/except se usa para detectar si un archivo de figuras existe antes de intentar insertarlo en el Word:

```python
try:
    doc.paragraphs[idx].runs[0].add_picture(ruta_figura, width=ancho)
except Exception as e:
    print(f"  ! No se pudo insertar figura: {e}")
```

## Combinando estructuras

Donde el control de flujo se vuelve útil de verdad es cuando se combinan varias capas. Las estructuras individuales son simples; la habilidad está en encadenarlas para resolver problemas reales.

### for + if: filtrar mientras se itera

```python
profundidades = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
velocidades   = [0.08, 0.09, 0.6, 0.07, 0.08, 0.09, 0.10, 0.09, 0.08, 0.07, 0.06]

# Recorrer dos listas a la vez con zip()
for prof, vel in zip(profundidades, velocidades):
    if vel > 0.5:
        print(f"Alerta en {prof} m: velocidad = {vel:.2f} m/s")
```

`zip()` empareja dos listas elemento a elemento: en cada vuelta del for, `prof` y `vel` corresponden al mismo índice.

### for + if + acumulador: encontrar el máximo con contexto

```python
maxima = 0
prof_maxima = None

for prof, vel in zip(profundidades, velocidades):
    if vel > maxima:
        maxima = vel
        prof_maxima = prof

print(f"Velocidad máxima: {maxima} m/s a {prof_maxima} m de profundidad")
# → Velocidad máxima: 0.6 m/s a 7 m de profundidad
```

El acumulador (`maxima`, `prof_maxima`) guarda el resultado parcial mientras el loop avanza. Al terminar, tiene la respuesta final.

### for + try/except: procesar lotes sin que un error detenga todo

```python
import pandas as pd

archivos = ['oct2024.csv', 'nov2024.csv', 'dic_corrupto.csv', 'ene2025.csv']
dataframes = []

for nombre in archivos:
    try:
        df = pd.read_csv(nombre)
        dataframes.append(df)
        print(f"OK: {nombre} ({len(df)} filas)")
    except FileNotFoundError:
        print(f"  ! No encontrado: {nombre}")
    except Exception as e:
        print(f"  ! Error en {nombre}: {e}")

df_total = pd.concat(dataframes)
```

Sin el `try/except`, el primer archivo problemático detendría el script y perderías los datos buenos que venían después. Con él, el loop sigue y al final tienes todo lo que se pudo leer.

### for anidado: recorrer filas y columnas

```python
profundidades = [5, 10, 20]
meses = ['oct', 'nov', 'dic']

for mes in meses:
    for prof in profundidades:
        # aquí iría la lógica para cada combinación mes × profundidad
        print(f"Procesando {mes} a {prof} m")
```

Útil cuando se necesita hacer algo para cada combinación de dos listas. Ojo: si cada lista tiene N elementos, el loop interno se ejecuta N² veces. Con listas grandes, conviene pensar si hay una forma vectorizada (NumPy/Pandas) que sea más eficiente.

### Comprehension con condición vs for + if

Cuando el objetivo es construir una lista filtrada, la comprehension es más clara:

```python
# for + if (más verboso)
superficiales = []
for p in profundidades:
    if p <= 7:
        superficiales.append(p)

# comprehension (equivalente, más directo)
superficiales = [p for p in profundidades if p <= 7]
```

La comprehension se lee de corrido: "lista de p, para cada p en profundidades, si p ≤ 7". Úsala cuando la lógica cabe en una línea. Si hay condiciones anidadas o el cuerpo del loop hace varias cosas, el for explícito es más fácil de leer y modificar.

### Patrón completo: lectura + filtrado + reporte

```python
import os
import pandas as pd

carpeta = 'datos/'
resultados = []

for archivo in os.listdir(carpeta):
    if not archivo.endswith('.csv'):
        continue   # saltar archivos que no son CSV

    try:
        df = pd.read_csv(os.path.join(carpeta, archivo))
        vel_max = df['velocidad'].max()
        resultados.append({'archivo': archivo, 'vel_max': vel_max})

    except Exception as e:
        print(f"  ! {archivo}: {e}")

# Ordenar por velocidad máxima
resultados.sort(key=lambda x: x['vel_max'], reverse=True)

for r in resultados:
    print(f"{r['archivo']:30s}  vel_max = {r['vel_max']:.2f} m/s")
```

Este patrón — iterar sobre archivos, saltar los irrelevantes, capturar errores, acumular resultados, ordenar y reportar — aparece constantemente en scripts de análisis real.

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
