# Glosario

Referencia rápida de términos usados en el manual.

---

## Python

**tipo de dato** (`type`)
: Clasificación que determina qué valores puede tener una variable y qué operaciones se le pueden aplicar. Los tipos fundamentales de Python son `float`, `int`, `str`, `bool` y `None`.

**float**
: Número de punto flotante (con decimales). En Python puro siempre es de 64 bits (~15 dígitos de precisión). En NumPy puede ser `float32` (32 bits, ~7 dígitos) o `float64`.

**int**
: Número entero sin parte decimal. En Python 3 no tiene límite de tamaño. Se usa para índices, contadores y cantidades discretas.

**str**
: Cadena de texto. Secuencia inmutable de caracteres Unicode.

**bool**
: Valor lógico: `True` o `False`. Es un subtipo de `int` (`True == 1`, `False == 0`).

**None**
: Ausencia de valor. Equivalente a `NULL` en SQL o `null` en otros lenguajes. Se verifica con `is None`, no con `== None`.

**NaN** (*Not a Number*)
: Valor especial de punto flotante que representa un dato faltante o inválido. `np.nan` en NumPy, generado automáticamente por pandas al leer celdas vacías. A diferencia de `None`, es de tipo `float` y permite operar con arrays numéricos. `NaN != NaN` es siempre `True` — para verificar usar `np.isnan()` o `pd.isna()`.

**lista**
: Colección ordenada y mutable de elementos de cualquier tipo. Se define con corchetes: `[1, "texto", True]`. Permite índices, slices y `.append()`.

**tupla**
: Como una lista pero inmutable — no se puede modificar después de creada. Se define con paréntesis: `(3.5, 270)`. Python la usa automáticamente para retornar múltiples valores de una función: `return media, std` devuelve una tupla.

**diccionario**
: Colección de pares clave-valor. Las claves son únicas. Se define con llaves: `{"lat": -31.9, "lon": -71.5}`. Acceso en O(1) por clave.

**índice** (`index`)
: Posición numérica de un elemento en una secuencia. En Python comienza en 0. Índices negativos cuentan desde el final: `lista[-1]` es el último elemento.

**slice**
: Selección de un rango de elementos: `lista[2:5]` extrae los elementos en posiciones 2, 3 y 4 (el límite superior no se incluye). También funciona en arrays y DataFrames.

**comprehension**
: Forma compacta de construir una lista, conjunto o diccionario. `[x*2 for x in lista if x > 0]` es equivalente a un `for` + `append` pero en una línea.

**función**
: Bloque de código con nombre que recibe parámetros, ejecuta una tarea y opcionalmente retorna un valor. Se define con `def`. Permite reutilizar lógica sin repetirla.

**módulo**
: Archivo `.py` que contiene funciones, clases y variables importables. `import numpy as np` carga el módulo numpy con el alias `np`.

**paquete**
: Carpeta que contiene módulos y un archivo `__init__.py`. Numpy, pandas y matplotlib son paquetes.

**scope** (alcance)
: Región del código donde una variable es visible. Las variables definidas dentro de una función son locales — no existen fuera de ella. Para compartir datos entre funciones, usar el valor de retorno.

**excepción**
: Error en tiempo de ejecución. Se captura con `try / except`. Los tipos más comunes: `FileNotFoundError`, `KeyError` (clave inexistente en dict), `IndexError` (índice fuera de rango), `TypeError` (tipo incorrecto), `ValueError` (valor inválido).

---

## Herramientas y entorno

**entorno virtual**
: Instalación aislada de Python con sus propios paquetes, independiente del sistema global. Permite que distintos proyectos usen versiones distintas de las mismas librerías sin conflictos.

**conda**
: Gestor de paquetes y entornos incluido en Anaconda. A diferencia de pip, resuelve dependencias binarias (C, Fortran) además de Python. Comandos principales: `conda create`, `conda activate`, `conda install`, `conda env export`.

**pip**
: Gestor de paquetes oficial de Python. Instala desde PyPI. Se usa junto con conda para paquetes que no están en los repositorios de conda.

**environment.yml**
: Archivo YAML que describe un entorno conda: nombre, canales, y lista de paquetes con versiones exactas. Se genera con `conda env export` y permite recrear el entorno exacto en otro equipo con `conda env create -f environment.yml`.

**YAML** (*YAML Ain't Markup Language*)
: Formato de texto para configuración y datos estructurados. Más legible que JSON: no usa comillas en strings simples y admite comentarios con `#`. Estándar para archivos de configuración de proyectos y pipelines. Se lee en Python con `yaml.safe_load()` del paquete `pyyaml`.

**tqdm**
: Librería para barras de progreso. Envuelve cualquier iterable: `for x in tqdm(lista)` muestra una barra con porcentaje, velocidad y tiempo estimado. Especialmente útil en loops que procesan decenas o cientos de archivos.

**logging**
: Módulo de la librería estándar de Python para registrar mensajes de diagnóstico. A diferencia de `print`, cada mensaje tiene timestamp y nivel de severidad (`DEBUG`, `INFO`, `WARNING`, `ERROR`). Permite escribir simultáneamente a consola y a un archivo de log sin modificar el código.

---

## NumPy

**array**
: Estructura de datos central de NumPy. Arreglo multidimensional de elementos del mismo tipo. A diferencia de una lista, permite operaciones matemáticas directas sobre todos sus elementos sin loop.

**dtype**
: Tipo de dato de los elementos de un array NumPy. Los más comunes: `float64` (64 bits, predeterminado para floats), `float32` (32 bits, usado en modelos numéricos y datos satelitales para ahorrar memoria), `int32`, `int64`, `bool`. Se verifica con `array.dtype` y se convierte con `array.astype(np.float64)`.

**float32 vs float64**
: `float64` tiene ~15 dígitos significativos de precisión; `float32` tiene ~7. Los archivos NetCDF de modelos oceánicos (CROCO) y datos satelitales suelen usar `float32` para reducir tamaño en disco. Al operar entre `float32` y `float64`, NumPy convierte todo a `float64` automáticamente.

**shape**
: Tupla con las dimensiones de un array. `(186, 11)` significa 186 filas y 11 columnas. `array.shape`, `array.ndim` (número de dimensiones), `array.size` (total de elementos).

**vectorización**
: Aplicar una operación a todos los elementos de un array sin escribir un loop explícito. `vel * 1.944` convierte todos los valores a nudos en una sola instrucción, más rápido que un `for`.

**broadcasting**
: Regla de NumPy que permite operar arrays de distinto tamaño cuando sus formas son compatibles. Operaciones entre un array y un escalar, o entre arrays de formas como `(N,)` y `(N, M)`, se "expanden" automáticamente.

**máscara booleana**
: Array de `True`/`False` del mismo tamaño que otro array, usado para seleccionar o modificar elementos. `vel[vel > 0.5]` aplica una máscara generada por la comparación.

---

## Pandas

**DataFrame**
: Tabla de datos con filas y columnas etiquetadas. Equivalente a una hoja de Excel pero operable desde código. Cada columna es una `Series`.

**Series**
: Columna de un DataFrame: array unidimensional con un índice. Tiene nombre, dtype y las mismas operaciones que un array NumPy.

**índice** (`Index`)
: Etiquetas de las filas. Por defecto es numérico (0, 1, 2…). En series temporales es un `DatetimeIndex`. El índice es lo que usa `loc` para seleccionar filas.

**DatetimeIndex**
: Índice de fechas y horas. Permite filtrar por rango (`df['2025-10':'2026-03']`), resamplear (`df.resample('1h').mean()`) y agrupar por hora, día o mes.

**`loc` vs `iloc`**
: `loc` selecciona por **etiqueta** del índice; `iloc` selecciona por **posición** numérica. Con un índice numérico parecen iguales, pero con `DatetimeIndex` la diferencia es crucial: `df.loc['2025-10-01']` filtra por fecha, `df.iloc[0]` siempre es la primera fila.

**resampleo** (`resample`)
: Cambiar la resolución temporal de una serie. `df.resample('1h').mean()` agrupa en ventanas de 1 hora y calcula la media de cada una.

**groupby**
: Divide el DataFrame en grupos según el valor de una columna, aplica una función a cada grupo y combina los resultados. Equivalente a una tabla dinámica por categoría.

**rolling**
: Ventana deslizante sobre una Serie temporal. `df['vel'].rolling('1h').mean()` calcula la media del último hora en cada punto. Se usa para suavizar series con ruido de alta frecuencia.

**pd.cut**
: Divide una columna continua en intervalos discretos con etiquetas. `pd.cut(df['vel'], bins=[0, 0.1, 0.5, 1.0], labels=['calma','leve','fuerte'])` asigna una categoría a cada valor. Se usa para construir tablas de incidencia velocidad × dirección.

**merge**
: Une dos DataFrames por una columna común, equivalente a un JOIN de SQL. El parámetro `how` controla qué filas se conservan: `inner` (solo matches), `left` (todas las del primero), `outer` (todas las de ambos).

**concat**
: Apila DataFrames con la misma estructura vertialmente (más filas) u horizontalmente (más columnas). Se usa para unir datos de distintos períodos antes de calcular estadísticas globales.

**pathlib.Path**
: Clase de la librería estándar para manejar rutas de archivos de forma orientada a objetos y multiplataforma. `Path('/ruta') / 'subcarpeta' / 'archivo.csv'` construye rutas sin concatenar strings con `/` o `os.path.join`.

---

## Visualización

**Figure**
: El contenedor principal de matplotlib. Todo gráfico existe dentro de una `Figure`. Se crea con `plt.figure()` o `plt.subplots()`. Controla el tamaño total (`figsize`) y el guardado (`fig.savefig()`).

**Axes**
: El panel de dibujo dentro de una Figure. Contiene los ejes X e Y, los datos graficados, etiquetas y leyenda. Una Figure puede tener varios Axes (subplots).

**backend**
: Motor que matplotlib usa para renderizar y mostrar figuras. `Agg`: sin ventana, renderiza a memoria (para guardar archivos). `TkAgg`: ventana Tkinter interactiva, estable en Spyder. `Qt5Agg`: ventana Qt5, puede interferir con el event loop de Spyder. `inline`: hook de IPython sobre Agg que embebe la figura como imagen en la consola.

**event loop**
: Bucle de escucha continua de eventos (clics, teclado, redimensionado) que necesita cualquier ventana de escritorio para responder al usuario. Python solo puede correr un event loop a la vez en el hilo principal, por eso `plt.show()` bloquea la ejecución hasta que se cierra la ventana.

**matplotlib.widgets**
: Módulo de matplotlib que provee controles interactivos dentro del canvas de una figura: `Slider`, `Button`, `CheckButtons`, `RadioButtons`. No requieren construir una aplicación Qt o Tk completa, pero están limitados al espacio del gráfico.

**FuncAnimation**
: Clase de `matplotlib.animation` que crea animaciones llamando repetidamente a una función de actualización. El resultado se puede mostrar en vivo o exportar como GIF (requiere pillow) o MP4 (requiere ffmpeg).

**GridSpec**
: Clase de `matplotlib.gridspec` para layouts de subplots con tamaños desiguales. Permite definir `height_ratios` y `width_ratios` para que algunos paneles sean más grandes que otros, y posicionar cada Axes en celdas arbitrarias de la grilla.

**twin axes**
: Técnica de matplotlib para superponer dos variables con escalas distintas en el mismo panel. `ax2 = ax1.twinx()` crea un eje Y derecho que comparte el eje X con el izquierdo. Útil para comparar velocidad y temperatura en la misma serie temporal.

**PyQt5**
: Librería para construir aplicaciones de escritorio completas en Python usando el framework Qt5. Permite crear ventanas con menús, botones y tablas, y embeber matplotlib como un widget (`FigureCanvasQTAgg`). Más potente que `matplotlib.widgets` pero más complejo. Los scripts PyQt5 deben correrse fuera de Spyder.

---

## Formatos y estándares

**NetCDF** (`.nc`)
: Formato científico para datos multidimensionales con coordenadas etiquetadas (tiempo, profundidad, latitud, longitud). Estándar en oceanografía y meteorología. Se lee con `xarray`.

**xarray Dataset**
: Estructura de datos para archivos NetCDF. Equivalente a un diccionario de arrays NumPy con coordenadas nombradas. Permite seleccionar por nombre de coordenada: `ds['temp'].sel(ocean_time='2024-01-01')`.

**coordenadas sigma (σ)**
: Sistema de coordenadas verticales usado en modelos oceánicos (CROCO, ROMS) donde σ = 0 es la superficie y σ = −1 es el fondo. Los niveles siguen la forma del fondo en vez de ser planos horizontales fijos.

**STAC** (*SpatioTemporal Asset Catalog*)
: Estándar JSON para catálogos de datos geoespaciales. Permite buscar imágenes satelitales por área, fecha y colección mediante una API REST, sin descargar los archivos.

**MGRS** (*Military Grid Reference System*)
: Sistema de grilla mundial que divide la superficie terrestre en celdas de 100 km × 100 km identificadas por un código alfanumérico (ej. `19HBB`). Sentinel-2 organiza sus imágenes por tile MGRS.

**GCP** (*Ground Control Points*, puntos de control terrestre)
: Pares de puntos con coordenadas conocidas en píxeles y en el mundo real. Se usan para georreferenciar imágenes: ajustar la transformación píxel → coordenada geográfica.

**OCR** (*Optical Character Recognition*, reconocimiento óptico de caracteres)
: Proceso de extraer texto desde una imagen. En el manual se usa para digitalizar valores de profundidad desde cartas batimétricas escaneadas, combinando OpenCV (preprocesamiento) y Tesseract (reconocimiento).

**ADCP** (*Acoustic Doppler Current Profiler*)
: Instrumento oceanográfico que mide velocidad y dirección de corrientes a múltiples profundidades usando el efecto Doppler sobre partículas en suspensión. Genera matrices de datos (tiempo × profundidad).
