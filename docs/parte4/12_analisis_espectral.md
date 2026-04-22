# Análisis espectral

El análisis espectral descompone una serie temporal en sus componentes de frecuencia, mostrando cuánta energía hay en cada período. En oceanografía se aplica principalmente al oleaje (para obtener el espectro de energía y extraer parámetros como Hm0 y Tp) y a las corrientes (para identificar mareas, inerciales y otras señales periódicas).

## Transformada de Fourier con NumPy

La FFT es el punto de partida para cualquier análisis espectral:

```python
import numpy as np

# Serie temporal de velocidad de corriente (N datos, dt segundos entre muestras)
N  = len(serie)
dt = 600   # 10 minutos en segundos
fs = 1 / dt   # frecuencia de muestreo (Hz)

# FFT
espectro = np.fft.rfft(serie - serie.mean())   # rfft: solo frecuencias positivas
freqs    = np.fft.rfftfreq(N, d=dt)            # Hz

# Potencia espectral
potencia = (np.abs(espectro) ** 2) / (N * fs)

# Convertir frecuencias a períodos (en horas)
with np.errstate(divide='ignore'):
    periodos_h = 1 / freqs / 3600
```

## Densidad espectral de potencia con Welch

El método de Welch es más robusto que la FFT directa porque promedia segmentos solapados, reduciendo el ruido estadístico:

```python
from scipy.signal import welch

# nperseg: número de muestras por segmento (elegir ~10% de N, potencia de 2)
freqs_w, psd = welch(
    serie - serie.mean(),
    fs=fs,
    nperseg=512,
    noverlap=256,
    window='hann'
)

periodos_w_h = 1 / freqs_w / 3600

import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(10, 5))
ax.semilogy(periodos_w_h, psd, color='navy', linewidth=0.8)
ax.set_xlim(0, 50)   # períodos hasta 50 h
ax.set_xlabel('Período (h)')
ax.set_ylabel('PSD ((m/s)²/Hz)')
ax.set_title('Espectro de densidad de potencia — Corriente 7 m')
ax.grid(True, which='both', alpha=0.3)

# Marcar componentes de marea
for periodo, nombre in [(24, 'K1'), (12.42, 'M2'), (6.21, 'M4')]:
    ax.axvline(periodo, color='firebrick', linewidth=0.8, linestyle='--', alpha=0.7)
    ax.text(periodo, ax.get_ylim()[1] * 0.5, nombre, color='firebrick', fontsize=8)
```

## Espectro de oleaje

Los parámetros integrados (Hm0, Tm02, Tp) se derivan del espectro de densidad de energía:

```python
def espectro_oleaje(eta, dt_s, nperseg=512):
    """
    Calcula el espectro de energía de una serie de superficie libre.
    Retorna freqs (Hz) y S (m²/Hz).
    """
    freqs, psd = welch(eta - eta.mean(), fs=1/dt_s,
                       nperseg=nperseg, window='hann')
    return freqs[1:], psd[1:]   # descartar componente DC

def momento_espectral(freqs, S, n):
    """Momento espectral de orden n: mₙ = ∫ fⁿ S(f) df."""
    return np.trapz(freqs**n * S, freqs)

freqs, S = espectro_oleaje(eta, dt_s=1800)   # muestras cada 30 min

m0  = momento_espectral(freqs, S, 0)
m2  = momento_espectral(freqs, S, 2)

Hm0  = 4 * np.sqrt(m0)         # altura significativa espectral (m)
Tm02 = np.sqrt(m0 / m2)        # período medio (s)
Tp   = 1 / freqs[np.argmax(S)] # período de pico (s)

print(f"Hm0  = {Hm0:.2f} m")
print(f"Tm02 = {Tm02:.1f} s")
print(f"Tp   = {Tp:.1f} s")
```

## Visualizar el espectro de oleaje

```python
fig, ax = plt.subplots(figsize=(9, 5))

ax.fill_between(freqs, S, alpha=0.3, color='steelblue')
ax.plot(freqs, S, color='navy', linewidth=1)

# Marcar frecuencia de pico
fp = freqs[np.argmax(S)]
ax.axvline(fp, color='firebrick', linestyle='--', linewidth=1,
           label=f'fp = {fp:.4f} Hz  (Tp = {1/fp:.1f} s)')

# Separar swell y viento localmente (límite convencional 0.1 Hz)
ax.axvspan(freqs.min(), 0.1, alpha=0.08, color='green', label='Swell (<0.1 Hz)')
ax.axvspan(0.1, freqs.max(),  alpha=0.08, color='orange', label='Sea (>0.1 Hz)')

ax.set_xlabel('Frecuencia (Hz)')
ax.set_ylabel('S(f)  (m²/Hz)')
ax.set_title(f'Espectro de oleaje — Hm0 = {Hm0:.2f} m, Tp = {Tp:.1f} s')
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)
fig.tight_layout()
```

## Identificar componentes de marea

Las mareas son señales periódicas con frecuencias bien conocidas:

```python
MAREAS = {
    'K1':  23.93,   # diurna
    'O1':  25.82,
    'M2':  12.42,   # semidiurna principal
    'S2':  12.00,
    'N2':  12.66,
    'M4':   6.21,   # cuarto-diurna
}

import pandas as pd

df_mareas = []
for nombre, periodo_h in MAREAS.items():
    f_central = 1 / (periodo_h * 3600)
    mascara = np.abs(freqs_w - f_central) < f_central * 0.05
    if mascara.any():
        energia = np.trapz(psd[mascara], freqs_w[mascara])
        df_mareas.append({'componente': nombre, 'período_h': periodo_h, 'energía': energia})

df_m = pd.DataFrame(df_mareas).sort_values('energía', ascending=False)
print(df_m.to_string(index=False))
```

## Espectrograma (espectro en tiempo)

Para ver cómo evoluciona el espectro a lo largo del tiempo:

```python
from scipy.signal import spectrogram

f_sg, t_sg, Sxx = spectrogram(
    serie - serie.mean(),
    fs=fs,
    nperseg=256,
    noverlap=192,
    window='hann'
)

fig, ax = plt.subplots(figsize=(12, 5))
im = ax.pcolormesh(t_sg / 3600, 1 / f_sg[1:] / 3600, np.log10(Sxx[1:]),
                   cmap='viridis', shading='gouraud')
ax.set_ylim(0, 30)   # períodos hasta 30 h
ax.set_xlabel('Tiempo (h)')
ax.set_ylabel('Período (h)')
ax.set_title('Espectrograma de velocidad de corriente')
fig.colorbar(im, ax=ax, label='log₁₀ PSD')
```

!!! tip "Efecto de ventana"
    Aplicar una ventana (Hann, Hamming) antes de la FFT reduce las fugas espectrales causadas por el truncamiento de la serie. `welch` aplica la ventana internamente; si usas `np.fft.rfft` directamente, multiplica la serie por `np.hanning(N)` antes de transformar.

!!! warning "Resolución espectral"
    La resolución frecuencial es `Δf = 1 / (N × dt)`. Series cortas tienen baja resolución y no pueden separar componentes de período similar (p. ej. M2 y S2, que difieren solo 0.42 h). Para estudios de marea se necesitan al menos 30 días de datos.

!!! tip "Spyder"
    `Ctrl + 1` comenta o descomenta la selección. `Ctrl + 2` inserta un separador de celda `# %%` en la posición del cursor.
