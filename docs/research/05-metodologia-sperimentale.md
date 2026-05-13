# 05. Metodologia sperimentale e criteri di valutazione

## Obiettivo

La metodologia deve rispondere a una sola domanda: **il sistema e vendibile come soluzione indoor di bass spill control?** Non basta mostrare attenuazione in un grafico locale. Servono prove ripetibili su punti esterni, banda utile, impatto interno e stabilita operativa.

## 1. KPI che contano

| Categoria | KPI |
|---|---|
| acustici esterni | riduzione media al boundary, riduzione minima nel punto peggiore, performance per banda `31.5-125 Hz` |
| acustici interni | deviazione nei listening point di riferimento |
| operativi | tempo installazione, tempo commissioning, tempo retuning |
| affidabilita | burst, instabilita, fallback, uptime del controller |
| business-readiness | numero di venue che raggiungono il minimo tecnico |

## 2. Target iniziali di accettazione

Per il beachhead indoor valgono i target del piano:

- `4-8 dB` di riduzione media esterna in banda bassa critica;
- degrado interno circa entro `+-2 dB` nei punti di riferimento;
- commissioning completo in una giornata tecnica;
- nessuna instabilita udibile durante il run di test.

Se questi target non vengono raggiunti in modo ripetibile, il sistema non ha ancora una base commerciale solida.

## 3. Definizione rigorosa dei punti di misura

Per evitare autoinganni, ogni campagna deve distinguere chiaramente:

- `listening points` interni di riferimento;
- `boundary points` esterni di conformita;
- punti strutturali critici vicino a pareti o aperture;
- sensori usati dal controllore versus sensori usati solo per validazione.

Mescolare questi ruoli rende i risultati poco credibili.

## 4. Protocollo di test minimo

### Fase A - Baseline venue

- rilievo dei punti interni di riferimento;
- rilievo dei boundary point esterni;
- misura `ANC off` con programma musicale reale;
- raccolta della baseline per banda.

### Fase B - Calibrazione

- routing del riferimento da `mixer/DSP`;
- identificazione dei `secondary path`;
- verifica dei livelli e della sincronizzazione;
- salvataggio del profilo venue.

### Fase C - Run controllato

- attivazione del controllore;
- misura `ANC on` sugli stessi punti;
- verifica della differenza interna/esterna;
- log degli eventi di stabilita.

### Fase D - Robustezza operativa

- cambio preset o livello musicale;
- variazioni moderate di setup;
- verifica tempo di ricalibrazione o retuning.

## 5. Metriche quantitative base

La metrica energetica locale resta:

```math
\Delta L = 10\log_{10}\frac{\mathbb{E}[d^2(n)]}{\mathbb{E}[e^2(n)]}
```

ma nel prodotto va sempre riportata con contesto:

- punto di misura;
- banda o terza d'ottava;
- stato `ANC on/off`;
- condizione musicale usata.

## 6. Metriche aggiuntive utili

Oltre alla riduzione media conviene calcolare:

- riduzione minima nel punto peggiore;
- deviazione standard tra punti esterni;
- deviazione interna massima rispetto al baseline;
- tempo di settling dopo attivazione o retuning;
- percentuale di tempo in cui il sistema resta dentro i vincoli.

Se un sistema migliora la media ma peggiora molto il punto peggiore, la sua vendibilita resta dubbia.

## 7. Esperimenti raccomandati nel repository

| Esperimento | Scopo |
|---|---|
| secondary path baseline | validare la catena di calibrazione |
| `SISO` FxLMS baseline | verificare la catena attuale del repository |
| benchmark venue-oriented | futura baseline principale del progetto |
| sensitivity sweep | capire regioni operative di `mu`, `Lw`, `leakage`, `beta` |

I test su sorgenti mobili restano utili come stress test, ma non devono essere presentati come dimostrazione primaria di vendibilita del prodotto.

## 8. Disegno sperimentale minimo credibile

Per ogni scena servono almeno:

1. run `ANC off`;
2. run `ANC on`;
3. stessa scaletta o segmento musicale;
4. stessi punti di misura;
5. stesso assetto di sensori e sorgenti;
6. registrazione dei parametri del controllore.

Senza questo, il confronto tende a essere narrativo invece che misurabile.

## 9. Riproducibilita minima

Ogni campagna deve registrare:

- commit o stato del codice;
- configurazione venue;
- routing reference da `mixer/DSP`;
- posizione di emitter e sensori;
- parametri del controllore;
- file di calibrazione;
- seed o configurazione dei segnali sintetici;
- risultati numerici per punto e per banda.

## 10. Cosa deve contenere un report di pilot

Un report utile per decisioni prodotto o commerciali deve includere:

- configurazione della venue;
- schema di posizionamento emitter e sensori;
- routing del riferimento da `mixer/DSP`;
- KPI `off/on` per punto e per banda;
- grafici sintetici;
- problemi osservati;
- decisione: `go`, `retune`, `no-go`.

## 11. Kill criteria

Il progetto va rifocalizzato se:

- la riduzione utile esterna non e ripetibile;
- il degrado interno diventa commercialmente inaccettabile;
- il commissioning resta artigianale;
- il sistema richiede retuning continuo non scalabile.

## 12. Cosa rende un test credibile

- stesso contenuto musicale `ANC off` e `ANC on`;
- stessi punti di misura;
- stessa finestra temporale;
- numeri tabellari oltre ai plot;
- dichiarazione esplicita delle condizioni di fallimento.

## Sintesi

La metodologia non deve dimostrare che "l'algoritmo funziona qualche volta". Deve dimostrare che il sistema fornisce **riduzione esterna ripetibile, controllata e installabile** in una venue indoor reale.
