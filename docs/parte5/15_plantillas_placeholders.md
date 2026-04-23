# Plantillas y placeholders

El autoinforme se basa en una plantilla Word preformateada (`.docx`) con marcadores de posición —**placeholders**— que Python reemplaza en tiempo de ejecución. Este enfoque separa el diseño visual (responsabilidad del Word) del contenido numérico (responsabilidad del script).

## Convención de placeholders

Los placeholders se escriben en la plantilla entre corchetes, en mayúsculas y con guiones bajos:

```
[PROYECTO]         → nombre del proyecto
[VEL_MAX_7M]       → velocidad máxima en la capa de 7 m
[DIR_PRED_7M]      → dirección predominante en 7 m
[FIGURA_ROSA_7M]   → imagen de rosa de corrientes en 7 m
[TABLA_INCIDENCIA] → tabla de incidencia
```

!!! tip "Nomenclatura consistente"
    Usar siempre el mismo formato en la plantilla y en el diccionario de reemplazos del script. Un error tipográfico en el placeholder deja el marcador sin reemplazar en el informe final, lo cual es fácil de detectar visualmente.

## Validar que todos los placeholders se reemplazaron

Antes de guardar el informe, verificar que no quedó ningún placeholder sin llenar:

```python
import re

def placeholders_pendientes(doc):
    """Retorna una lista de placeholders que no fueron reemplazados."""
    patron = re.compile(r'\[[A-Z_0-9]+\]')
    encontrados = set()
    for parrafo in todos_los_parrafos(doc):   # función del capítulo 14
        for match in patron.finditer(parrafo.text):
            encontrados.add(match.group())
    return sorted(encontrados)

pendientes = placeholders_pendientes(doc)
if pendientes:
    print(f"  ! Placeholders sin reemplazar: {pendientes}")
else:
    print("  ✓ Todos los placeholders reemplazados")
```

## Placeholders en tablas

Los placeholders pueden estar dentro de celdas de tablas. La función `todos_los_parrafos` del capítulo anterior ya los cubre, pero a veces se necesita reemplazar una celda completa:

```python
def reemplazar_en_tablas(doc, reemplazos: dict):
    """Reemplaza placeholders dentro de todas las celdas de todas las tablas."""
    for tabla in doc.tables:
        for fila in tabla.rows:
            for celda in fila.cells:
                for parrafo in celda.paragraphs:
                    for viejo, nuevo in reemplazos.items():
                        if viejo in parrafo.text:
                            reemplazar_en_parrafo(parrafo, viejo, str(nuevo))
```

## Placeholders que se repiten

Un mismo placeholder puede aparecer múltiples veces en el documento (p. ej. `[PROYECTO]` en el encabezado, en el cuerpo y en el pie de página). La función `reemplazar_en_doc` ya los reemplaza todos porque itera sobre todos los párrafos.

Para placeholders en **encabezados y pies de página**, hay que acceder explícitamente a las secciones:

```python
def reemplazar_en_encabezados_pies(doc, reemplazos: dict):
    for seccion in doc.sections:
        for parrafo in seccion.header.paragraphs:
            for viejo, nuevo in reemplazos.items():
                if viejo in parrafo.text:
                    reemplazar_en_parrafo(parrafo, viejo, str(nuevo))
        for parrafo in seccion.footer.paragraphs:
            for viejo, nuevo in reemplazos.items():
                if viejo in parrafo.text:
                    reemplazar_en_parrafo(parrafo, viejo, str(nuevo))
```

## Placeholder partido entre runs

Word a veces divide un placeholder en runs separados cuando el usuario activa la corrección automática o cuando lo escribe carácter a carácter. Por ejemplo `[VEL_MAX]` puede quedar como:

```
Run 1: "[VEL_"
Run 2: "MAX]"
```

En ese caso `viejo in parrafo.text` detecta el placeholder, pero `viejo in run.text` no encuentra nada. La solución es fusionar los runs antes de reemplazar:

```python
def fusionar_runs_parrafo(parrafo):
    """Fusiona todos los runs del párrafo en el primero, preservando el formato del primero."""
    if not parrafo.runs:
        return
    texto_total = parrafo.text
    for i, run in enumerate(parrafo.runs):
        run.text = texto_total if i == 0 else ''

def reemplazar_robusto(doc, reemplazos: dict):
    """Fusiona runs y luego reemplaza. Usar solo cuando hay placeholders partidos."""
    patron = re.compile(r'\[[A-Z_0-9]+\]')
    for parrafo in todos_los_parrafos(doc):
        if patron.search(parrafo.text):
            fusionar_runs_parrafo(parrafo)
        for viejo, nuevo in reemplazos.items():
            if viejo in parrafo.text:
                reemplazar_en_parrafo(parrafo, viejo, str(nuevo))
```

!!! warning "Fusionar runs borra el formato interno"
    Al fusionar todos los runs en uno solo, el texto queda con el formato del primer run (fuente, tamaño, negrita). Esto es aceptable si el placeholder ocupa su propio párrafo. Si el placeholder está en medio de un párrafo con texto mixto (parte en negrita, parte normal), la fusión puede romper el formato del párrafo completo.

## Diccionario de reemplazos por campaña

En el pipeline se construye el diccionario de reemplazos a partir de los datos calculados:

```python
def construir_reemplazos(df_stats, meta):
    """
    df_stats : DataFrame con estadísticas por profundidad
    meta     : dict con metadatos del proyecto (fechas, nombre, etc.)
    """
    reemplazos = {
        '[PROYECTO]':   meta['nombre'],
        '[EMPRESA]':    meta['empresa'],
        '[FECHA_INI]':  meta['fecha_inicio'].strftime('%d/%m/%Y'),
        '[FECHA_FIN]':  meta['fecha_fin'].strftime('%d/%m/%Y'),
        '[N_DATOS]':    str(meta['n_datos']),
    }

    # Estadísticas por profundidad
    for prof in df_stats.index:
        fila = df_stats.loc[prof]
        clave = str(prof).replace('.', '_')   # 7.5 → 7_5
        reemplazos[f'[VEL_MEDIA_{clave}M]'] = f"{fila['vel_media']:.2f}"
        reemplazos[f'[VEL_MAX_{clave}M]']   = f"{fila['vel_max']:.2f}"
        reemplazos[f'[DIR_PRED_{clave}M]']  = f"{fila['dir_pred']:.0f}°"

    return reemplazos
```

## Flujo recomendado

```python
from pathlib import Path
from docx import Document

def generar_informe_completo(ruta_plantilla, ruta_salida, meta, df_stats, figuras):
    doc = Document(ruta_plantilla)

    # 1. Reemplazar texto en cuerpo
    reemplazos = construir_reemplazos(df_stats, meta)
    reemplazar_robusto(doc, reemplazos)

    # 2. Reemplazar en encabezados y pies
    reemplazar_en_encabezados_pies(doc, reemplazos)

    # 3. Insertar figuras
    for placeholder, ruta_img in figuras.items():
        insertar_figura_en_placeholder(doc, placeholder, ruta_img)

    # 4. Validar
    pendientes = placeholders_pendientes(doc)
    if pendientes:
        print(f"  ! Sin reemplazar: {pendientes}")

    doc.save(ruta_salida)
    print(f"Informe generado: {ruta_salida.name}")
```
