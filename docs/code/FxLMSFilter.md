# `FxLMSFilter.m`

## Ruolo

`FxLMSFilter.m` e il **baseline controller** piu vicino alla visione prodotto, ma resta una implementazione `SISO` da laboratorio. Va interpretato come precursore del futuro controllore `MIMO` eseguito su `Edge DSP Controller`.

## Firma reale

```matlab
obj = FxLMSFilter(Lw, s_est, mu, epsilon, leakage, beta)
```

```matlab
[y, e_out] = step(x_in, e_in)
```

| Argomento | Significato |
|---|---|
| `Lw` | lunghezza del filtro di controllo |
| `s_est` | stima FIR del `secondary path` |
| `mu` | step-size nominale |
| `epsilon` | regolarizzazione numerica |
| `leakage` | smorzamento dei pesi |
| `beta` | memoria della stima IIR di potenza |

## Cosa implementa

Il file calcola:

1. riferimento filtrato `x_f(n)` tramite `s_est`;
2. stima di potenza a costo basso;
3. aggiornamento `Leaky-NLMS`;
4. sintesi dell'uscita di controllo `y(n)`.

Equazioni operative:

```math
x_f(n)=\hat{\mathbf{s}}^T \mathbf{x}_s(n)
```

```math
P(n)=\beta P(n-1)+(1-\beta)x_f^2(n)
```

```math
\mu_n=\frac{\mu}{P(n)+\varepsilon}
```

```math
\mathbf{w}(n+1)=\lambda \mathbf{w}(n)+\mu_n e(n)\mathbf{x}_f(n)
```

## Perche e coerente con la roadmap

Il prodotto canonico richiede un riferimento anticipato acquisito da `mixer/DSP`. `FxLMSFilter.m` e coerente con questa logica perche:

- parte da un ingresso di riferimento esplicito `x_in`;
- usa il `secondary path` per correggere il gradiente;
- rappresenta bene il cuore matematico del controllo `feed-forward`.

## Dove si ferma il file attuale

| Tema | Stato attuale | Necessita prodotto |
|---|---|---|
| topologia | `SISO` | `MIMO` |
| sensori | un errore alla volta | array interni + boundary mic |
| obiettivo | riduzione locale dell'errore | riduzione spill con vincoli interni |
| adattamento plant | `s_est` statico | tracking e retuning controllato |
| sicurezza | nessun safe mode | supervisione robusta |

## Stato interno

I buffer privati hanno una struttura chiara:

- `x_s_buff`: finestra usata per il calcolo `filtered-x`;
- `xf_buff`: regressore filtrato usato nel gradiente;
- `x_buff`: finestra usata per sintetizzare `y(n)`;
- `w`: coefficienti del controllore;
- `P`: stima scalare della potenza.

## Nota documentale importante

La firma attuale del costruttore richiede `6` argomenti. Un blocco `try` presente in `OfflineSystemID.m` usa ancora una chiamata placeholder non aggiornata. La lettura corretta e quella della classe stessa.

## Tuning pratico

| Parametro | Effetto principale |
|---|---|
| `Lw` | copertura temporale vs costo computazionale |
| `mu` | velocita di adattamento vs stabilita |
| `epsilon` | protezione a bassa energia |
| `leakage` | robustezza vs bias |
| `beta` | smoothing della stima di potenza |

## Come va usato nella documentazione prodotto

Quando si descrive l'architettura commerciale:

- `FxLMSFilter.m` va citato come baseline concettuale;
- non va presentato come controller finale installabile;
- va collegato al futuro `MimoFxLMSController.m` e al `CalibrationSession`.

## Sintesi

`FxLMSFilter.m` e il ponte piu diretto tra repository e roadmap. E tecnicamente rilevante, ma non basta da solo a rappresentare il sistema indoor MIMO per `bass spill control`.
