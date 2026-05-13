# Archivio tecnico: note legacy recuperate

## Stato del file

Questo documento non e piu una specifica di progetto. E un estratto archivistico di idee ancora utili, ripulite dalla narrativa fuori focus.

## Cosa resta valido

| Insight | Perche resta utile |
|---|---|
| `FxLMS` con `leakage` e stima IIR di potenza | buona baseline per il repository corrente |
| ritardo frazionario e propagazione realistica | necessario per simulazioni fisicamente credibili |
| il `secondary path` non puo essere trattato come dettaglio | la calibrazione resta un elemento centrale del prodotto |
| il passaggio a `MIMO` e obbligatorio | una venue reale non e controllabile seriamente in `SISO` |
| servono safe mode e supervisione | la stabilita non puo essere lasciata implicita |

## Cosa e stato scartato

- focus su rumore industriale come mercato iniziale;
- narrativa da "cancellazione totale";
- enfasi su sorgenti mobili come caso d'uso principale;
- uso del materiale come source of truth.

## Come riusare questo archivio

Usarlo solo per recuperare:

- osservazioni di robustezza;
- motivazioni per `MIMO`;
- idee su tracking del plant e supervisione;
- spunti per ottimizzazione del runtime.

Per decisioni operative fare sempre riferimento a:

- `../plan.md`
- `../research/`
- `../code/`
