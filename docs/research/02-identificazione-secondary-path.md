# 02. Identificazione del secondary path

## Ruolo nel prodotto

In un sistema venue-oriented, il `secondary path` e la catena che collega ogni emitter ANC a ogni sensore rilevante. Include:

- conversione `D/A` o interfaccia audio;
- amplificazione;
- trasduttore;
- propagazione nell'ambiente indoor;
- risposta di pareti, aperture e boundary;
- microfono;
- conversione `A/D`.

Nel prodotto finale questa catena e **multi-canale**:

```math
\mathbf{S}(z)=
\begin{bmatrix}
S_{11}(z) & \dots & S_{1M}(z) \\
\vdots & \ddots & \vdots \\
S_{N1}(z) & \dots & S_{NM}(z)
\end{bmatrix}
```

dove `M` e il numero di emitter e `N` il numero di sensori.

## 1. Perche il secondary path domina il problema

Il controllore non deve solo sapere "cosa sta per uscire dal mixer". Deve anche sapere **come** quell'azione si trasformera in pressione acustica nei punti misurati.

In formula:

```math
\mathbf{e}(n)=\mathbf{d}(n)-\mathbf{S}(z)\mathbf{y}(n)
```

Se `\mathbf{S}(z)` e stimata male:

- il gradiente del controllore e distorto;
- la fase del contributo secondario e sbagliata;
- la convergenza rallenta o diventa instabile.

## 2. Perche la calibrazione e decisiva

Il controllore usa il riferimento proveniente da `mixer/DSP`, ma aggiorna i pesi in funzione di come quell'azione passa davvero attraverso il sistema fisico. Senza `\hat{S}(z)`:

- il gradiente e temporalmente disallineato;
- la fase e stimata male;
- la stabilita peggiora rapidamente.

La calibrazione non e un accessorio del prodotto. E parte della value proposition, perche rende installabile e ripetibile il sistema.

## 3. Stato attuale vs target

| Livello | Stato nel repository | Target prodotto |
|---|---|---|
| topologia | `SISO` | `MIMO` |
| procedura | `OfflineSystemID.m` | commissioning guidato via installer software |
| sorgente di prova | rumore bianco sintetico | sweep, probe e routine venue-specific |
| output | `ANC_Calibration.mat` | profilo venue, mapping sensori, KPI pre/post |
| aggiornamento | snapshot offline | tracking e retuning controllato |

## 4. Formulazione base `SISO`

Nel caso elementare usato oggi dal repository:

```math
d_s(n) = s(n) * v(n) + \eta(n)
```

e si stima un FIR `\hat{s}(n)` con:

```math
\hat{d}_s(n)=\hat{\mathbf{s}}^T(n)\mathbf{v}(n)
```

```math
e_{id}(n)=d_s(n)-\hat{d}_s(n)
```

```math
\hat{\mathbf{s}}(n+1)=
\hat{\mathbf{s}}(n)+
\mu_{id}\frac{e_{id}(n)\mathbf{v}(n)}
{\|\mathbf{v}(n)\|^2+\varepsilon_{id}}
```

Questa logica resta utile come baseline, ma non esaurisce la calibrazione richiesta dal prodotto indoor MIMO.

## 5. Generalizzazione `MIMO`

Nel caso realistico, per ogni emitter `m` e sensore `k` esiste un percorso `S_{km}(z)`. La stima completa e quindi una matrice di filtri:

```math
\hat{\mathbf{S}}(z)=
\begin{bmatrix}
\hat{S}_{11}(z) & \cdots & \hat{S}_{1M}(z) \\
\vdots & \ddots & \vdots \\
\hat{S}_{N1}(z) & \cdots & \hat{S}_{NM}(z)
\end{bmatrix}
```

Questo implica che il commissioning non possa limitarsi a un solo sweep o a un solo vettore `s_est`.

## 6. Condizioni di identificabilita

Una procedura di identificazione ha senso solo se:

- il segnale di prova eccita bene la banda di interesse;
- i canali sono sincronizzati correttamente;
- il rumore di misura non domina il segnale;
- la lunghezza del modello cattura ritardo e memoria utili;
- il plant non cambia troppo durante la misura.

Se una di queste condizioni manca, il problema non e "algoritmico" ma di setup o di commissioning.

## 7. Flusso di commissioning raccomandato

```mermaid
flowchart LR
    A["Venue Survey"] --> B["Sensor / Emitter Mapping"]
    B --> C["Reference Routing da Mixer/DSP"]
    C --> D["Probe / Sweep Session"]
    D --> E["Secondary Path Estimation"]
    E --> F["Stability Check"]
    F --> G["Preset Venue + KPI Baseline"]
```

## 8. Quali segnali usare in commissioning

Nel repository attuale il segnale di sonda e rumore bianco. In una pipeline piu matura hanno senso:

- rumore bianco o rosa per baseline larga banda;
- sweep logaritmici per separare meglio ampiezza e fase;
- burst controllati per test rapidi installativi;
- routine multi-canale con sequenze ortogonali o time-multiplexing.

La scelta corretta dipende dal compromesso tra:

- tempo di misura;
- SNR disponibile;
- banda da eccitare;
- robustezza rispetto alla venue.

## 9. Criteri di qualita della stima

Una stima utile deve rispettare tre condizioni:

1. allineamento temporale corretto;
2. coerenza di magnitudo nella banda `25-160 Hz`;
3. errore di fase sufficientemente basso da non compromettere il gradiente del controllore.

Nel prodotto reale contano soprattutto le bande terze d'ottava critiche, non una buona media astratta su tutto lo spettro.

## 10. Errore di fase e conseguenze pratiche

Nel controllo attivo l'errore di fase pesa piu dell'errore moderato di magnitudo. Se `\hat{S}(z)` riproduce male la fase nella banda target:

- il `Filtered-x` diventa poco rappresentativo;
- il passo utile si riduce;
- il leakage necessario aumenta;
- la riduzione massima raggiungibile cala.

Questa e una delle ragioni per cui la calibrazione venue-aware e un asset di prodotto, non un passaggio accessorio.

## 11. Limiti della procedura attuale

`OfflineSystemID.m` e utile come testbench, ma oggi presenta limiti evidenti rispetto alla visione prodotto:

- stima un solo percorso;
- non rappresenta pareti, aperture e sensori multipli;
- non gestisce drift di impianto o retuning operativo;
- non produce un artefatto di commissioning pronto per installazione commerciale.

## 12. Da `ANC_Calibration.mat` a profilo venue

Nel prodotto finale l'output della calibrazione dovrebbe contenere almeno:

- mappa emitter-sensori;
- stime dei `secondary path` rilevanti;
- versione del preset venue;
- KPI baseline `ANC off`;
- validazione di stabilita;
- storico e data della misura.

Questa differenza e cruciale: il file `.mat` attuale e una prova tecnica; il profilo venue futuro e un artefatto operativo.

## 13. Implicazione pratica

La calibrazione commerciale deve essere pensata come una funzione del `Edge DSP Controller` e del software installatore, non come uno script separato dal resto del sistema.

## Sintesi

`OfflineSystemID.m` resta una baseline corretta per il repository attuale. La roadmap, pero, richiede il passaggio da `single-path estimation` a **commissioning multi-canale di venue**.
