# Archivio teoria: FxLMS quick reference

## Stato del file

Questa e una nota rapida di archivio. Per la spiegazione operativa usare `../research/03-controllore-fxlms.md`.

## Formula essenziale

```math
\mathbf{w}(n+1)=\mathbf{w}(n)+\mu e(n)\mathbf{x}_f(n)
```

con:

```math
\mathbf{x}_f(n)=\hat{s}(n)*\mathbf{x}(n)
```

## Significato pratico

- il riferimento arriva a monte dal sistema audio;
- il `secondary path` corregge il gradiente;
- il controllore cerca di ridurre il residuo sui sensori;
- nel prodotto reale questa logica diventa `MIMO`.

## Limite da ricordare

Il `FxLMS` non risolve da solo:

- commissioning;
- modellazione venue;
- supervisione robusta;
- vincoli di qualita sonora interna.

Serve quindi come base teorica, non come descrizione completa del prodotto.
