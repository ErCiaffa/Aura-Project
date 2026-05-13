# Live Script del progetto

I file `.mlx` sono notebook di laboratorio. Non sono librerie riusabili e non rappresentano ancora il workflow del prodotto commerciale.

## Stato dei testbench

| File | Ruolo attuale | Rilevanza strategica |
|---|---|---|
| `main.mlx` | smoke test dei generatori | utile per sanity check |
| `main_ANC_test.mlx` | baseline con `AdaptiveLMSFilter` | test legacy di confronto |
| `main_FxLMSFilter.mlx` | demo corrente della pipeline `FxLMS` | testbench principale attuale |

## `main.mlx`

Serve come verifica minima di:

- generazione segnali;
- plotting base;
- ascolto rapido di output sintetici.

Non ha ruolo diretto nella validazione del prodotto.

## `main_ANC_test.mlx`

Va letto come test di confronto:

- usa una baseline `LMS/NLMS`;
- non rappresenta il controller prodotto;
- mostra perche il semplice adattamento senza `Filtered-x` non basta.

E utile come benchmark negativo o didattico, non come demo commerciale.

## `main_FxLMSFilter.mlx`

E il testbench piu importante del repository corrente perche unisce:

- calibrazione;
- generazione scenario;
- controllo `FxLMS`;
- visualizzazione del residuo.

Anche qui, pero, il frame corretto e questo:

- dimostra la fattibilita della baseline `SISO`;
- non dimostra ancora il sistema indoor `MIMO` per venue;
- non usa ancora un flusso di `reference ingest` da `mixer/DSP` realistico per installazione.

## Come andrebbero evoluti

Secondo il piano, i testbench da privilegiare diventano:

- `main_Venue_IndoorBenchmark.mlx`
- `main_Venue_PilotScenario.mlx`
- `main_Outdoor_PerimeterScenario.mlx`

Tra questi, il benchmark indoor deve diventare il principale.

## Ordine di uso consigliato oggi

1. `main.mlx`
2. `OfflineSystemID.m`
3. `main_ANC_test.mlx`
4. `main_FxLMSFilter.mlx`

## Sintesi

I `.mlx` attuali sono utili per laboratorio e debug. La loro evoluzione necessaria e trasformarsi in benchmark ufficiali per venue indoor con KPI comparabili.
