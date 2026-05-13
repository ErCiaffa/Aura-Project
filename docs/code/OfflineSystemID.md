# `OfflineSystemID.m`

## Ruolo

`OfflineSystemID.m` e la baseline di calibrazione del repository. Stima offline un `secondary path` `SISO` e salva il risultato in `ANC_Calibration.mat`.

## Cosa fa davvero

Lo script:

1. definisce i parametri di identificazione;
2. costruisce un plant sintetico;
3. eccita il plant con rumore bianco;
4. stima `s_est` tramite `NLMS`;
5. esporta l'artefatto di calibrazione.

## Parametri principali nel file

| Parametro | Valore attuale |
|---|---:|
| `Fs` | `48000` |
| `T_probe` | `2 s` |
| `Ls` | `256` |
| `D` | `15` campioni |
| `target_snr` | `30 dB` |

## Equazione di stima

```math
\hat{\mathbf{s}}(n+1)=
\hat{\mathbf{s}}(n)+
\mu \frac{e(n)\mathbf{v}(n)}{\|\mathbf{v}(n)\|^2+\varepsilon}
```

Questa scelta e coerente con una baseline robusta e leggibile.

## Output

Il file salva:

- `s_est`
- `s_real_coeffs`
- `Fs`

in `ANC_Calibration.mat`.

## Valore nel contesto prodotto

Questo script e importante perche mostra il principio di commissioning: il controllore non puo funzionare senza una stima del plant. Ma il prodotto finale richiede molto di piu:

- piu path tra piu emitter e piu sensori;
- routing del riferimento da `mixer/DSP`;
- preset venue;
- verifica KPI prima/dopo;
- integrazione nel `Edge DSP Controller` e nel software installatore.

## Limiti espliciti

- calibrazione `SISO`;
- plant simulato, non venue reale;
- nessuna gestione di drift o tracking online;
- nessun workflow di commissioning multi-zona.

## Nota tecnica

Il blocco finale di test verso `FxLMSFilter` contiene una chiamata placeholder non allineata alla firma reale del costruttore. La funzione utile del file resta la generazione di `s_est`, non l'inizializzazione del controller in quello specifico blocco `try`.

## Sintesi

`OfflineSystemID.m` e una buona baseline per capire la calibrazione. Per il prodotto va evoluto in una vera `CalibrationSession` multi-canale, venue-aware e integrata nel flusso installativo.
