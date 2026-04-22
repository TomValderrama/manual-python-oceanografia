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

## Combinando todo: ejemplo oceanográfico

```python
profundidades = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
velocidades   = [0.08, 0.09, 0.6, 0.07, 0.08, 0.09, 0.10, 0.09, 0.08, 0.07, 0.06]

maxima = 0
prof_maxima = None

for prof, vel in zip(profundidades, velocidades):
    if vel > maxima:
        maxima = vel
        prof_maxima = prof

print(f"Velocidad máxima: {maxima} m/s a {prof_maxima} m de profundidad")
# → Velocidad máxima: 0.6 m/s a 7 m de profundidad
```
