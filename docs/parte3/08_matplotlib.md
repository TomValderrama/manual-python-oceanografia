# Matplotlib

Matplotlib es la librería de visualización estándar en Python. Permite crear desde gráficos simples hasta figuras multipanel complejas listas para publicación.

```python
import matplotlib.pyplot as plt
import numpy as np
```

## Gráfico básico

```python
tiempo = np.arange(0, 186)
velocidad = np.random.normal(3.93, 2.8, 186)

plt.figure(figsize=(12, 4))
plt.plot(tiempo, velocidad, color='steelblue', linewidth=0.8)
plt.xlabel('Día')
plt.ylabel('Velocidad (m/s)')
plt.title('Serie temporal de velocidad del viento')
plt.tight_layout()
plt.savefig('serie_viento.png', dpi=150)
plt.show()
```

## Figure y Axes — la estructura correcta

Para figuras con múltiples paneles o más control, se trabaja directamente con objetos `Figure` y `Axes`:

```python
fig, ax = plt.subplots(figsize=(12, 4))

ax.plot(tiempo, velocidad, color='steelblue', linewidth=0.8)
ax.set_xlabel('Día')
ax.set_ylabel('Velocidad (m/s)')
ax.set_title('Serie temporal')
ax.grid(True, alpha=0.3)

fig.tight_layout()
fig.savefig('serie_viento.png', dpi=150)
```

## Múltiples paneles

### subplot simple

```python
fig, axes = plt.subplots(3, 1, figsize=(12, 10), sharex=True)

axes[0].plot(tiempo, Hm0, color='navy')
axes[0].set_ylabel('Hm0 (m)')

axes[1].plot(tiempo, Tm, color='teal')
axes[1].set_ylabel('Tm (s)')

axes[2].plot(tiempo, Dm, color='darkorange', marker='.', markersize=1, linestyle='none')
axes[2].set_ylabel('Dm (°)')
axes[2].set_xlabel('Tiempo')

fig.tight_layout()
```

### subplot2grid — paneles de distinto tamaño

```python
fig = plt.figure(figsize=(14, 8))

ax1 = plt.subplot2grid((2, 3), (0, 0), colspan=2)   # fila 0, cols 0-1
ax2 = plt.subplot2grid((2, 3), (0, 2))               # fila 0, col 2
ax3 = plt.subplot2grid((2, 3), (1, 0), colspan=3)   # fila 1, ancho completo
```

## Tipos de gráfico

```python
# Línea
ax.plot(x, y, color='steelblue', linewidth=1, linestyle='--', label='velocidad')

# Puntos
ax.scatter(x, y, c=colores, s=20, alpha=0.5, cmap='viridis')

# Barras
ax.bar(meses, promedios, color='teal', edgecolor='white')

# Histograma
ax.hist(velocidad, bins=20, color='steelblue', edgecolor='white', density=True)

# Área rellena
ax.fill_between(tiempo, y_min, y_max, alpha=0.3, color='steelblue')

# Línea horizontal / vertical de referencia
ax.axhline(y=6, color='red', linestyle='--', linewidth=0.8, label='umbral')
ax.axvline(x=45, color='gray', linestyle=':')
```

## Colores y estilos

```python
# Colores nombrados
'steelblue', 'navy', 'teal', 'darkorange', 'firebrick', 'gray'

# Hex
'#2196F3'

# Escala de grises
'0.5'   # gris medio

# Transparencia
ax.plot(x, y, color='steelblue', alpha=0.7)

# Colormaps — para datos continuos
cmap = plt.cm.viridis
cmap = plt.cm.RdBu_r   # divergente, útil para anomalías
```

## Ejes y etiquetas

```python
ax.set_xlim(0, 186)
ax.set_ylim(0, 20)

# Ticks personalizados
ax.set_xticks([0, 30, 60, 90, 120, 150, 180])
ax.set_xticklabels(['sep', 'oct', 'nov', 'dic', 'ene', 'feb', 'mar'])
ax.tick_params(axis='x', rotation=45)

# Formato de números en eje
from matplotlib.ticker import PercentFormatter
ax.yaxis.set_major_formatter(PercentFormatter(decimals=1))

# Escala logarítmica
ax.set_yscale('log')
```

## Leyenda y anotaciones

```python
ax.plot(x, y1, label='Velocidad media')
ax.plot(x, y2, label='Percentil 95')
ax.legend(loc='upper right', fontsize=9)

# Anotación de texto
ax.text(0.02, 0.95, f'Máximo: {vmax:.2f} m/s',
        transform=ax.transAxes,   # coordenadas relativas al axes (0-1)
        fontsize=9, verticalalignment='top')

# Flecha con texto
ax.annotate('Evento energético', xy=(45, 3.0), xytext=(60, 3.5),
            arrowprops=dict(arrowstyle='->', color='red'))
```

## Mapas de calor (heatmap)

Muy usado en corrientes para visualizar velocidad por tiempo y profundidad:

```python
# datos: matriz (n_tiempos × n_profundidades)
im = ax.pcolormesh(tiempos, profundidades, datos.T,
                   cmap='RdBu_r', vmin=-0.3, vmax=0.3)
fig.colorbar(im, ax=ax, label='Velocidad (m/s)')
ax.set_ylabel('Profundidad (m)')
ax.invert_yaxis()   # profundidad creciente hacia abajo
```

## Guardar figuras

```python
fig.savefig('figura.png', dpi=150, bbox_inches='tight')
fig.savefig('figura.pdf', bbox_inches='tight')    # vectorial
fig.savefig('figura.svg', bbox_inches='tight')    # vectorial editable

plt.close(fig)   # liberar memoria — importante en scripts que generan muchas figuras
```

### PDF multipágina

```python
from matplotlib.backends.backend_pdf import PdfPages

with PdfPages('informe_figuras.pdf') as pdf:
    for mes in meses:
        fig, ax = plt.subplots()
        ax.plot(datos_mes[mes])
        ax.set_title(mes)
        pdf.savefig(fig)
        plt.close(fig)
```

## Backend gráfico

El backend controla cómo se muestran las figuras:

```python
import matplotlib
matplotlib.use('Qt5Agg')   # ventana interactiva (ideal en Spyder)
# o
matplotlib.use('Agg')      # sin ventana, solo guardar a archivo (ideal en scripts automáticos)
```

En Spyder se configura desde **Preferences → IPython console → Graphics → Backend**.

!!! tip "plt.close() en scripts automáticos"
    Cuando un script genera decenas de figuras (como el autoinforme), es importante cerrar cada figura después de guardarla con `plt.close(fig)`. De lo contrario Matplotlib acumula todas en memoria y Spyder puede volverse lento o colapsar.

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
