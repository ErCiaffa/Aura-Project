# File di supporto

## Inventario rapido

| File | Ruolo |
|---|---|
| `ANC_Calibration.mat` | artefatto di calibrazione `SISO` del repository |
| `ANC_Training_Data.csv` | log tabellare di segnali e residui |
| `sound_test_01.mp3` | asset audio di test |
| `README.md` | placeholder root non ancora allineato |
| `docs/RAW/*` | archivio sintetizzato di note legacy |

## `ANC_Calibration.mat`

Contiene attualmente:

- `s_est`
- `s_real_coeffs`
- `Fs`

E critico per `main_FxLMSFilter.mlx`. Se il file e assente o incoerente con la configurazione del test, il risultato non e affidabile.

## `ANC_Training_Data.csv`

Header osservato:

```text
Timestamp,Reference_Input_X,Primary_Noise_D,AntiNoise_Y,Residual_Error_E
```

Il file e utile per:

- analisi offline;
- confronto run-to-run;
- esportazione verso report e dataset;
- futura telemetria di benchmark.

Non e ancora la data layer del prodotto, ma e un buon prototipo di logging.

## `sound_test_01.mp3`

Asset di prova utile per:

- verificare `LoadAudioFile`;
- sperimentare contenuti reali;
- confrontare generatori sintetici e audio importato.

## `README.md` di root

Il file root contiene oggi solo `# Aura-Project`. Non va trattato come entrypoint documentale affidabile.

## `docs/RAW`

I file in `RAW/` sono stati ridotti a note archivistiche concise. Servono a conservare insight recuperabili senza lasciare in giro narrativa fuori focus.

## Regola operativa

Ogni volta che cambiano:

- frequenza di campionamento;
- struttura del plant;
- configurazione di benchmark;
- schema di logging;

gli artefatti di supporto vanno rigenerati o almeno rivalidati.
