# Spyder vs VSCode

Spyder es el mejor punto de partida para análisis de datos: es simple, tiene Variable Explorer y está pensado para trabajar con datos desde el primer día. VSCode es más potente como editor y se adapta mejor cuando el código crece en proyectos multi-archivo.

Este capítulo compara ambos entornos y explica cómo hacer la transición cuando conviene.

## Comparativa directa

| | Spyder | VSCode |
|---|---|---|
| **Variable Explorer** | Integrado, visual, con doble clic en DataFrames | Requiere modo Jupyter interactivo |
| **Celdas `# %%`** | Nativo, `Ctrl+Enter` / `Shift+Enter` | Con extensión Python, funciona igual |
| **Autocompletado** | Básico | Avanzado (Pylance: tipos, docstrings, imports) |
| **Navegación entre archivos** | Limitada | Ir a definición entre módulos, búsqueda global |
| **Git** | No integrado | Diff visual, historial, blame por línea |
| **Terminal** | Consola IPython | Terminal bash/WSL real |
| **Backend Qt5** | Conflicto de event loop | Sin conflicto (Electron ≠ Qt) |
| **Refactoring** | Básico | Renombrar en todo el proyecto, mover código |
| **Curva de aprendizaje** | Baja | Media |
| **Instalación** | Anaconda | Descarga + extensión Python |

## Cuándo quedarse en Spyder

- Estás aprendiendo Python o explorando un dataset nuevo
- El flujo de trabajo es principalmente un script con celdas `# %%`
- El Variable Explorer es parte central de tu trabajo (inspeccionar DataFrames, arrays)
- El proyecto cabe en uno o dos archivos `.py`

## Cuándo migrar a VSCode

- El proyecto tiene varios módulos que se importan entre sí
- Usas Git activamente y quieres ver diffs sin salir del editor
- Desarrollas herramientas interactivas con matplotlib (clicks, sliders) y Qt5 te da problemas
- Necesitas conectarte a un servidor remoto (extensión Remote-SSH)
- Trabajas con múltiples lenguajes en el mismo proyecto (Python + bash + YAML + Markdown)

## Configurar VSCode para análisis de datos

### Instalación mínima

1. Descargar VSCode: [code.visualstudio.com](https://code.visualstudio.com)
2. Instalar extensiones:
   - **Python** (Microsoft) — soporte base
   - **Pylance** — autocompletado avanzado con inferencia de tipos

### Seleccionar el intérprete de Python

`Ctrl+Shift+P` → "Python: Select Interpreter" → elegir el Python de Anaconda (`conda base` o el entorno que uses).

### Celdas `# %%` en VSCode

Las celdas funcionan exactamente igual que en Spyder. Con la extensión Python instalada:

```python
# %% Cargar datos
import pandas as pd
df = pd.read_csv('corrientes.csv')

# %% Graficar
import matplotlib.pyplot as plt
plt.plot(df['velocidad'])
plt.show()
```

- `Shift+Enter` ejecuta la celda y avanza
- `Ctrl+Enter` ejecuta la celda sin avanzar
- Se abre un panel "Jupyter Interactive" donde aparecen los outputs

### Variable Explorer equivalente

El panel Jupyter Interactive muestra las variables activas. También se puede:

```python
# En la celda, inspeccionar directamente
df.head()        # muestra las primeras filas como tabla
df.dtypes        # tipos de columnas
df.describe()    # estadísticas
```

Para abrir un DataFrame como tabla visual: instalar la extensión **Data Wrangler** (Microsoft).

### Configurar el backend de matplotlib

En VSCode, el backend inline se activa automáticamente en el modo interactivo. Para ventanas separadas:

```python
%matplotlib tk    # Tkinter — funciona bien
%matplotlib qt5   # Qt5 — también funciona bien (sin conflicto con VSCode)
```

### Atajos equivalentes a Spyder

| Acción | Spyder | VSCode |
|---|---|---|
| Ejecutar celda | `Ctrl+Enter` | `Shift+Enter` |
| Ejecutar celda y avanzar | `Shift+Enter` | `Shift+Enter` |
| Ejecutar selección | `F9` | `Shift+Enter` (con selección) |
| Comentar / descomentar | `Ctrl+1` | `Ctrl+/` |
| Ir a definición | `Ctrl+G` | `F12` |
| Buscar en archivo | `Ctrl+F` | `Ctrl+F` |
| Buscar en todo el proyecto | — | `Ctrl+Shift+F` |
| Paleta de comandos | — | `Ctrl+Shift+P` |

### Terminal integrado

`Ctrl+ñ` (o `Ctrl+\``) abre una terminal bash/WSL real dentro de VSCode. Útil para correr scripts completos, git, o herramientas de línea de comandos:

```bash
python generar_informe.py
bash publicar.sh
git log --oneline -10
```

## Jupyter en VSCode

VSCode soporta notebooks `.ipynb` nativamente. Para abrir o crear uno: `Ctrl+Shift+P` → "Create new Jupyter Notebook".

La ventaja sobre JupyterLab clásico: el editor de VSCode (autocompletado, Pylance) funciona dentro de las celdas del notebook.

## Flujo mixto recomendado

No es necesario elegir uno y abandonar el otro. Un flujo práctico:

1. **Exploración inicial en Spyder**: Variable Explorer + celdas para entender el dataset
2. **Desarrollo en VSCode**: cuando el código se organiza en funciones y módulos
3. **Git en VSCode**: commits, diffs, historial
4. **Scripts finales**: archivos `.py` ejecutables desde terminal, sin depender de ningún IDE

El código escrito en Spyder funciona exactamente igual en VSCode y viceversa — son editores, no lenguajes distintos.
