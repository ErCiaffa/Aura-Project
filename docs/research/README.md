# Ricerca tecnica

Questa sezione traduce il `plan.md` in termini fisici, algoritmici e sperimentali. Il punto di partenza non e "come cancellare tutto", ma **come ridurre in modo ripetibile il bass spill indoor** senza degradare l'esperienza sonora interna oltre limiti accettabili.

## Due livelli di lettura

| Livello | Documento | Uso |
|---|---|---|
| quadro completo | `00-teoria-completa-sistema-anc-indoor.md` | riferimento teorico unico e denso |
| capitoli specialistici | `01-05` | approfondimenti ordinati per tema |

## Mappa dei capitoli

| Domanda | Documento |
|---|---|
| Qual e la teoria completa del sistema? | `00-teoria-completa-sistema-anc-indoor.md` |
| Perche il prodotto parte dalla bassa frequenza e dall'indoor? | `01-fondamenti-fisici-anc.md` |
| Perche la calibrazione multi-canale e decisiva? | `02-identificazione-secondary-path.md` |
| Come si passa dal baseline `FxLMS` al controllore prodotto? | `03-controllore-fxlms.md` |
| Quale modello spaziale serve per una venue reale? | `04-sorgenti-mobili-e-propagazione-3d.md` |
| Come si dimostra che il sistema e vendibile? | `05-metodologia-sperimentale.md` |

## Presupposti canonici

- Il riferimento principale arriva da `mixer`, `DSP` o uscita `sub`, non da un sistema solo microfonico.
- Il controllo target e `MIMO` con supervisione su sensori interni e microfoni di confine.
- Il cuore operativo e un `Edge DSP Controller`, non uno script offline.
- Le metriche decisive sono esterne: riduzione al confine, stabilita, tempo di commissioning, preservazione interna.

## Cosa non fa questa sezione

- Non presenta l'outdoor come focus primario.
- Non descrive il progetto come sostituto completo dell'isolamento passivo.
- Non tratta il repository corrente come prodotto gia industrializzato.
