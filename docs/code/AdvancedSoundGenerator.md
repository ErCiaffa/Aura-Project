# `AdvancedSoundGenerator.m`

## Ruolo

`AdvancedSoundGenerator.m` e il motore del digital twin attuale. Genera segnali di test e modella propagazione semplificata. Nella roadmap prodotto resta importante, ma deve evolvere da generatore generico a **sorgente e propagazione venue-oriented**.

## Metodi pubblici principali

| Metodo | Uso attuale | Lettura corretta nel piano |
|---|---|---|
| `Jackhammer(...)` | stress test legacy non stazionario | utile per robustezza, non per go-to-market |
| `MovingJackhammer(...)` | scenario mobile con reference near-field | stress test, non benchmark primario |
| `ClubNoise(...)` | contenuto low-end tipo venue | il piu vicino al caso d'uso commerciale |
| `Propagator(...)` | ritardo, `1/r`, assorbimento | utile come blocco di base |
| `PinkNoise(...)` | eccitazione larga banda | utile per test e identificazione |
| `LoadAudioFile(...)` / `LoadAudioFolder(...)` | ingest di audio reale | ponte verso benchmark con programma musicale |

## Nota importante su `MovingJackhammer`

La firma reale e:

```matlab
[y, x_ref, distVec, fs] = MovingJackhammer(...)
```

dove:

- `y` e il segnale propagato;
- `x_ref` e la reference vicino sorgente;
- `distVec` e la distanza istantanea.

Questo va trattato come contratto canonico del metodo.

## Cosa fa bene oggi

Il file implementa gia tre idee utili:

- ritardo frazionario tramite `dsp.VariableFractionalDelay`;
- attenuazione geometrica approssimata `1/r`;
- assorbimento atmosferico con curva `ISO 9613-1` approssimata.

In forma sintetica:

```math
D(n)=\frac{r(n)}{c}f_s
```

```math
A(r)\propto \frac{1}{r}
```

Questi mattoni sono corretti come base di simulazione.

## Dove va riallineato al prodotto

La visione commerciale richiede che il file si sposti verso:

- sorgenti musicali indoor, non macchinari come narrativa principale;
- modelli di leakage path verso boundary e aperture;
- supporto a benchmark con riferimento proveniente da `mixer/DSP`;
- scenari con piu emitter e piu sensori.

## Priorita di lettura dei generatori

| Priorita | Metodo | Motivo |
|---|---|---|
| alta | `ClubNoise` | piu vicino al caso d'uso `bass spill control` |
| media | `Propagator` | blocco fisico riusabile |
| media | `LoadAudioFile` | ponte verso contenuti reali |
| bassa | `Jackhammer` / `MovingJackhammer` | stress test, non beachhead |

## Limiti attuali

- nessuna modellazione esplicita di room modes;
- nessuna geometria venue multi-zona;
- nessuna matrice `MIMO` di sensori/attuatori;
- nessun modello di pareti, aperture e boundary points come oggetti di primo livello.

## Implicazione pratica

`AdvancedSoundGenerator.m` non va eliminato. Va invece rifocalizzato. Il suo compito futuro e simulare **venue indoor con contenuto musicale reale e leakage misurabile**, non solo sorgenti "difficili" in senso astratto.
