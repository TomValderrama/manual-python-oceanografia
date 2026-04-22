# Sintaxis básica

Python es un lenguaje de tipado dinámico e indentado. No necesita declarar tipos de variables ni usar llaves `{}` para delimitar bloques — la estructura del código se define por la indentación.

## Variables y tipos

```python
# Números
velocidad = 3.5          # float
profundidad = 23         # int
n_celdas = 12            # int

# Texto
instrumento = "Nortek Aquadopp"
unidad = 'm/s'

# Booleano
datos_validos = True

# None (ausencia de valor)
resultado = None
```

Python detecta el tipo automáticamente. Se puede verificar con `type()`:

```python
type(velocidad)   # <class 'float'>
type(n_celdas)    # <class 'int'>
```

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

# Acceso por índice (empieza en 0)
profundidades[0]    # 3
profundidades[-1]   # 23 (último)
profundidades[2:5]  # [7, 9, 11] (slice)

# Operaciones
len(profundidades)          # 11
profundidades.append(25)    # agrega al final
profundidades.sort()        # ordena en lugar
sum(profundidades)          # suma
```

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

## Conversión de tipos

```python
int("23")        # 23
float("3.5")     # 3.5
str(186)         # "186"
list((1, 2, 3))  # [1, 2, 3]
```

!!! warning "Error frecuente"
    En Python 3, dividir dos enteros siempre devuelve float: `7 / 2 = 3.5`. Para división entera usa `//`.

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
