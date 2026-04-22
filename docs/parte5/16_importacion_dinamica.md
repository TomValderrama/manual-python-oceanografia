# Importación dinámica

El autoinforme es un script genérico que puede procesar cualquier campaña. La configuración específica de cada proyecto (rutas, parámetros, profundidades, nombre de empresa) vive en un módulo Python separado que se carga en tiempo de ejecución según el nombre del proyecto. Esto elimina la necesidad de editar el script central cada vez que se agrega una nueva campaña.

## El problema: configuración por proyecto

Sin importación dinámica, el script tendría bloques `if/elif`:

```python
# MAL: requiere modificar el script central para cada proyecto
if proyecto == 'los_vilos':
    from configs import los_vilos as cfg
elif proyecto == 'coquimbo':
    from configs import coquimbo as cfg
elif proyecto == 'iquique':
    from configs import iquique as cfg
# ... y así indefinidamente
```

Con importación dinámica, el script central no cambia nunca:

```python
# BIEN: el script carga automáticamente el módulo correcto
import importlib
cfg = importlib.import_module(f'configs.{nombre_proyecto}')
```

## importlib.import_module

```python
import importlib

def cargar_config(nombre_proyecto):
    """
    Carga el módulo de configuración para el proyecto indicado.
    Lanza ImportError con mensaje claro si no existe.
    """
    nombre_modulo = f'configs.{nombre_proyecto}'
    try:
        modulo = importlib.import_module(nombre_modulo)
    except ModuleNotFoundError:
        raise FileNotFoundError(
            f"No existe configuración para '{nombre_proyecto}'. "
            f"Crear el archivo configs/{nombre_proyecto}.py"
        )
    return modulo

# Uso
cfg = cargar_config('los_vilos_oct2025')

ruta_datos = cfg.RUTA_DATOS
profundidades = cfg.PROFUNDIDADES
empresa = cfg.EMPRESA
```

## Estructura de un módulo de configuración

Cada proyecto tiene un archivo en `configs/`:

```
autoinforme/
  configs/
    __init__.py          ← vacío, hace de configs un paquete
    los_vilos_oct2025.py
    coquimbo_mar2025.py
    iquique_ene2026.py
  autoinforme.py         ← script central (nunca se modifica)
```

Un módulo de configuración típico:

```python
# configs/los_vilos_oct2025.py
from pathlib import Path

PROYECTO     = 'Los Vilos — Campaña octubre 2025'
EMPRESA      = 'Puerto Los Vilos S.A.'
FECHA_INICIO = '2025-10-01'
FECHA_FIN    = '2025-10-31'

RUTA_BASE    = Path('/mnt/c/Users/Tomas/PELICANOS Dropbox/Proyectos2025/Los Vilos')
RUTA_DATOS   = RUTA_BASE / 'datos' / 'corrientes_procesadas.xlsx'
RUTA_FIGURAS = RUTA_BASE / 'figuras_magnitud'
RUTA_SALIDA  = RUTA_BASE / 'informe' / 'Los_Vilos_Corrientes_Oct2025.docx'
PLANTILLA    = Path('plantillas') / 'corrientes_v3.docx'

PROFUNDIDADES = [3, 5, 7, 9, 11, 13, 15]
BINS_VEL      = [0, 0.05, 0.1, 0.2, float('inf')]
```

## Verificar que el módulo tiene los atributos necesarios

```python
ATRIBUTOS_REQUERIDOS = [
    'PROYECTO', 'EMPRESA', 'FECHA_INICIO', 'FECHA_FIN',
    'RUTA_DATOS', 'RUTA_FIGURAS', 'RUTA_SALIDA', 'PLANTILLA',
    'PROFUNDIDADES',
]

def validar_config(cfg, nombre_proyecto):
    faltantes = [attr for attr in ATRIBUTOS_REQUERIDOS if not hasattr(cfg, attr)]
    if faltantes:
        raise AttributeError(
            f"Configuración '{nombre_proyecto}' incompleta. "
            f"Faltan: {faltantes}"
        )
```

## Recargar un módulo modificado

Durante el desarrollo, si se edita el archivo de configuración con el script ya corriendo en Spyder, hay que recargar el módulo para ver los cambios:

```python
import importlib

cfg = importlib.import_module('configs.los_vilos_oct2025')

# Después de editar el archivo:
importlib.reload(cfg)
```

## Listar proyectos disponibles

```python
from pathlib import Path

def listar_proyectos(carpeta_configs='configs'):
    carpeta = Path(carpeta_configs)
    proyectos = [
        p.stem for p in carpeta.glob('*.py')
        if p.stem != '__init__'
    ]
    return sorted(proyectos)

print("Proyectos disponibles:")
for p in listar_proyectos():
    print(f"  {p}")
```

## Patrón del script central

El script `autoinforme.py` recibe el nombre del proyecto por argumento de línea de comandos o por input interactivo:

```python
import sys
import importlib

def main():
    if len(sys.argv) > 1:
        nombre_proyecto = sys.argv[1]
    else:
        proyectos = listar_proyectos()
        print("Proyectos disponibles:")
        for i, p in enumerate(proyectos):
            print(f"  [{i}] {p}")
        idx = int(input("Seleccionar: "))
        nombre_proyecto = proyectos[idx]

    cfg = cargar_config(nombre_proyecto)
    validar_config(cfg, nombre_proyecto)

    print(f"\nProcesando: {cfg.PROYECTO}")

    # El resto del pipeline usa cfg.RUTA_DATOS, cfg.PROFUNDIDADES, etc.
    datos = cargar_datos(cfg.RUTA_DATOS)
    stats = calcular_estadisticas(datos, cfg.PROFUNDIDADES)
    generar_figuras(datos, stats, cfg.RUTA_FIGURAS)
    generar_informe(cfg.PLANTILLA, cfg.RUTA_SALIDA, cfg, stats)

if __name__ == '__main__':
    main()
```

!!! tip "Alternativa con JSON"
    Si la configuración es puramente datos (sin paths que necesiten `Path` o expresiones Python), se puede guardar como JSON y cargar con `json.load`. La ventaja de módulos `.py` es que permiten expresiones, herencia entre configs y paths relativos calculados con `Path(__file__).parent`.
