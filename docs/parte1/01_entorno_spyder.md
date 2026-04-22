# Entorno Spyder

Spyder es el entorno de desarrollo recomendado para análisis científico en Python. A diferencia de otros editores, está diseñado específicamente para trabajar con datos: tiene un explorador de variables integrado, una consola interactiva y permite ejecutar código por secciones.

## Instalación

La forma más sencilla es instalar **Anaconda**, que incluye Python, Spyder y las librerías científicas principales:

[https://www.anaconda.com/download](https://www.anaconda.com/download)

## La interfaz de Spyder

Spyder tiene tres paneles principales:

```
┌─────────────────────┬──────────────────────┐
│                     │  Variable Explorer   │
│      Editor         │  (variables activas) │
│    (tu código)      ├──────────────────────┤
│                     │  Consola IPython     │
│                     │  (resultados)        │
└─────────────────────┴──────────────────────┘
```

- **Editor**: donde escribes y guardas tu script `.py`
- **Consola IPython**: donde se ejecuta el código y se muestran resultados
- **Variable Explorer**: muestra todas las variables activas, sus tipos y valores — muy útil para inspeccionar DataFrames y arrays

## Ejecutar código

| Acción | Atajo |
|--------|-------|
| Ejecutar el script completo | `F5` |
| Ejecutar la línea actual | `F9` |
| Ejecutar una selección | Seleccionar + `F9` |
| Ejecutar una celda | `Ctrl + Enter` |
| Ejecutar celda y avanzar | `Shift + Enter` |

## Atajos de edición esenciales

| Acción | Atajo |
|--------|-------|
| Comentar / descomentar selección | `Ctrl + 1` |
| Insertar separador de celda `# %%` | `Ctrl + 2` |
| Duplicar línea | `Ctrl + D` |
| Mover línea arriba / abajo | `Alt + ↑ / ↓` |
| Buscar en el archivo | `Ctrl + F` |
| Ir a definición de función | `Ctrl + G` |

`Ctrl + 1` es especialmente útil para desactivar temporalmente un bloque de código sin borrarlo. `Ctrl + 2` inserta un `# %%` en la posición del cursor, creando una nueva celda ejecutable en ese punto.

## Celdas de código

Las celdas permiten dividir el script en bloques ejecutables de forma independiente, similar a un notebook pero dentro de un archivo `.py` normal.

Se definen con `# %%`:

```python
# %% Cargar datos
import pandas as pd
df = pd.read_csv('corrientes.csv')

# %% Graficar
import matplotlib.pyplot as plt
plt.plot(df['velocidad'])
plt.show()
```

Cada bloque `# %%` se puede ejecutar por separado con `Ctrl + Enter`. Esto es muy útil para procesar datos paso a paso sin reejecutar todo el script.

## Variable Explorer

El explorador de variables muestra en tiempo real:

- Nombre y tipo de cada variable
- Dimensiones de arrays y DataFrames
- Vista previa de los valores

Se puede hacer doble clic en un DataFrame para abrirlo en una tabla interactiva, o en un array para ver su contenido completo.

## Consola IPython

La consola acepta comandos directos sin necesidad de estar en el editor:

```python
# Ver las primeras filas de un DataFrame
df.head()

# Ver el tipo de una variable
type(df)

# Obtener ayuda de una función
help(pd.read_csv)
# o más rápido:
pd.read_csv?
```

## Configuración recomendada

Algunas opciones útiles en **Tools → Preferences**:

- **Editor → mostrar números de línea**: facilita depuración
- **IPython console → Graphics → Backend: Inline**: los gráficos aparecen en la consola (recomendado para análisis)
- **IPython console → Graphics → Backend: Tkinter**: cada gráfico abre en ventana separada, liviana e interactiva (zoom, pan, guardar)
- **IPython console → Graphics → Backend: Qt5**: similar a Tkinter pero más pesado; en algunos equipos es lento o inestable

También se puede cambiar el backend por sesión desde la consola sin tocar las preferencias:

```python
%matplotlib inline   # figuras en consola
%matplotlib tk       # ventana Tkinter interactiva
%matplotlib qt5      # ventana Qt5
```

### Cuándo usar cada backend

| Situación | Backend |
|---|---|
| Explorar datos, iterar rápido | Inline |
| Revisar figura con zoom o hacer clics sobre ella | Tkinter |
| Script automático que solo guarda PNG | `matplotlib.use('Agg')` antes de importar pyplot |

!!! tip "Recomendación"
    Usar **Inline** como predeterminado. Cambiar a **Tkinter** cuando se necesita interactividad (zoom, edición de puntos, inspector de coordenadas). Qt5 solo vale la pena si Tkinter falla o se necesitan widgets más complejos.
