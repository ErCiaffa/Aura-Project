# Archivio ricerca: FxLMS

## Stato del file

Questa nota raccoglie solo i concetti di ricerca ancora coerenti con il piano prodotto. Non sostituisce `../research/03-controllore-fxlms.md`.

## Punti confermati

- `MIMO FxLMS` e la baseline algoritmica piu realistica per la prima generazione.
- `Leaky-NLMS` resta una scelta prudente per la fase iniziale.
- La qualita della stima del `secondary path` domina stabilita e performance.
- Il riferimento da `mixer/DSP` riduce il rischio di causalita rispetto a soluzioni solo microfoniche.
- La validazione va fatta su KPI di venue, non su attenuazione puntuale astratta.

## Punti da trattare come step successivi

| Tema | Stato corretto |
|---|---|
| `FxRLS`, `Kalman`, MPC | interesse di roadmap, non base prodotto immediata |
| plant tracking online | importante, ma dopo la baseline indoor valida |
| strategie premium | solo dopo prova commerciale del core |

## Richiamo pratico

Ogni discussione su `FxLMS` va ricondotta a queste domande:

1. migliora la riduzione al boundary?
2. preserva il suono interno?
3. resta stabile con setup reali?
4. e installabile in tempi commercialmente utili?
