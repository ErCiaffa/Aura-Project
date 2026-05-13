# `AdaptiveLMSFilter.m`

## Ruolo

`AdaptiveLMSFilter` e il controllore piu semplice del repository. Va letto come **baseline didattica** per capire il loop adattativo, non come candidato al prodotto indoor di `bass spill control`.

## Interfaccia

```matlab
obj = AdaptiveLMSFilter(filterLength, stepSize, useNLMS)
```

```matlab
[y, e] = step(x_in, d_in)
```

Metodi disponibili:

- `reset()`
- `step(x_in, d_in)`
- `getWeights()`

## Cosa fa

La classe:

- mantiene un buffer del riferimento;
- calcola l'uscita FIR `y(n)`;
- calcola l'errore `e(n)=d(n)-y(n)`;
- aggiorna i pesi via `LMS` o `NLMS`.

Nel caso `NLMS`:

```math
\mathbf{w}(n+1)=\mathbf{w}(n)+
\frac{\mu}{\|\mathbf{x}(n)\|^2+\varepsilon}e(n)\mathbf{x}(n)
```

## Perche resta utile

E utile per:

- verificare che il loop sample-by-sample funzioni;
- creare una baseline contro `FxLMS`;
- mostrare quanto il `secondary path` sia determinante.

## Perche non e il controller prodotto

Il prodotto canonico richiede:

- riferimento `feed-forward` da `mixer/DSP`;
- filtraggio `Filtered-x`;
- gestione del `secondary path`;
- topologia `MIMO`;
- esecuzione su `Edge DSP Controller`.

`AdaptiveLMSFilter.m` non copre nessuno di questi punti in modo completo.

## Lettura corretta nel contesto del piano

Usare questo file per rispondere a una domanda semplice: "qual e il minimo sindacale del loop adattativo?". Non usarlo per inferire prestazioni o architettura del sistema commerciale target.
