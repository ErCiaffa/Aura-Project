# `Wave3DVisualizer.m`

## Ruolo

`Wave3DVisualizer.m` e il layer di lettura delle prestazioni. Non genera il controllo, ma trasforma i run MATLAB in output interpretabili.

## Funzioni pubbliche

| Funzione | Cosa mostra |
|---|---|
| `plotDbTracking(t, d, e, fs)` | andamento temporale e differenza energetica in dB |
| `plotSpectrogram3D(y, fs, title_str, ...)` | waterfall tempo-frequenza |

## Perche resta utile nel piano

La roadmap prodotto richiede KPI chiari. Anche se il file e ancora offline e locale, introduce una disciplina corretta:

- confronto `prima/dopo`;
- lettura per banda;
- attenzione alla stabilita nel tempo;
- interpretazione visiva del residuo.

## Logica di `plotDbTracking`

La potenza e mediata su finestra mobile e poi convertita in dB:

```math
P_d(n)=\mathrm{movmean}(d^2(n),N_w)
```

```math
P_e(n)=\mathrm{movmean}(e^2(n),N_w)
```

```math
\Delta_{\mathrm{dB}} \approx \overline{d_{dB}} - \overline{e_{dB}}
```

Questo approccio e corretto per un debug tecnico di base.

## Limiti rispetto al prodotto

Il file non copre ancora cio che serve a un sistema commerciale:

- mappe multi-punto interne ed esterne;
- report per `boundary microphones`;
- dashboard per commissioning venue;
- confronto multi-run e multi-preset;
- esportazione strutturata di KPI.

## Evoluzione attesa

Nel prodotto finale la logica di questo file dovrebbe confluire in un `PerformanceMonitor` capace di mostrare:

- riduzione media e minima al confine;
- deviazione nei listening point;
- stato del controller e alert;
- storico venue e trend di degrado.

## Sintesi

`Wave3DVisualizer.m` e utile oggi come strumento di QA tecnica. Domani deve diventare la base della reportistica KPI del sistema indoor `bass spill control`.
