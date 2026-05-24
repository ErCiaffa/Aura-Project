# Simulink Real-Time ANC Testbench

Wrapper Simulink dei filtri ANC esistenti (`FxLMSFilter`, `AdaptiveLMSFilter`,
`AdvancedSoundGenerator`) accoppiati a un solver FDTD 3D per la visualizzazione
real-time del campo di pressione in stanza.

## Architettura

```
[SourceGeneratorSystem]            ┌─→ [Scope]
   PinkNoise/Jackhammer/ClubNoise  │
   x(n) @48 kHz ───────┬──→ [FxLMSSystem] ──→ y(n) ──┬─→ [ErrorSum] → e(n) ──→ [Spectrum]
                       │           ▲                  │                       └─→ [To Workspace]
                       │           └──── e(n) ────────┘
                       │
                       └──→ [Decim 48k→4k]   y(n) →[Decim 48k→4k]
                                  │                 │
                                  └──→ [FDTD3DSystem] ──→ P[Nx,Ny,Nz] ──→ [Field3DSink]
```

## File

| File | Ruolo |
|---|---|
| `+anc/FxLMSSystem.m` | `matlab.System` che wrappa `FxLMSFilter` |
| `+anc/AdaptiveLMSSystem.m` | `matlab.System` che wrappa `AdaptiveLMSFilter` |
| `+anc/SourceGeneratorSystem.m` | Sorgente Variant (Pink/Jack/Club) |
| `+anc/FDTD3DSystem.m` | Solver FDTD 3D in pressione, Mur boundary |
| `+anc/Field3DSink.m` | Sink imagesc su slice XY/XZ/YZ con marker |
| `buildTestbench.m` | Costruisce `AncTestbench.slx` programmaticamente |
| `setupTestbench.m` | Carica calibrazione, apre il modello |
| `smokeFDTD3D.m` | Test offline del solver FDTD |

## Come si esegue

```matlab
>> cd /path/to/Aura-Project/simulink
>> setupTestbench
```

Il primo lancio costruisce `AncTestbench.slx` e lo apre. Premi **Run**.

Per il test offline del solver senza Simulink:

```matlab
>> smokeFDTD3D
```

## Vincoli numerici importanti

**FDTD 3D non gira a 48 kHz su griglia metrica realistica** (condizione di Courant
e numero di celle lo rendono proibitivo). Per questo lo strato audio (48 kHz)
e quello del campo sono **disaccoppiati con un decimatore 12:1**. Il campo gira
a 4 kHz (banda 0–2 kHz) — ampiamente sufficiente per il dominio bass spill
25–160 Hz documentato in `README.md`.

Condizione di Courant 3D:  `c * dt / dx ≤ 1/√3`. Default `dx=0.2 m`, `fs_field=4 kHz`
→ Courant ≈ 0.43 (stabile). Se aumenti la risoluzione (es. `dx=0.1`) devi anche
alzare `FieldSampleRate` ad almeno 6 kHz.

## Parametri della stanza (modificabili dalla mask dei blocchi)

| Parametro | Default | Note |
|---|---|---|
| `RoomSize` | `[6 6 3]` m | Stanza media |
| `Dx` | `0.2` m | 30×30×15 = 13500 celle |
| `FieldSampleRate` | `4000` Hz | Decimazione 12:1 da 48 kHz |
| `SourcePos` | `[1.0 3.0 1.5]` | sorgente di rumore primaria |
| `AncPos` | `[4.0 3.0 1.5]` | emettitore ANC |
| `ErrorMicPos` | `[5.0 3.0 1.5]` | mic di errore |
| `BoundaryType` | `Mur` | assorbente; alternativa `Rigid` (muri) |

## Sorgenti selezionabili

Apri il blocco `Source` e cambia `SourceType` (`PinkNoise` / `Jackhammer` / `ClubNoise`).
Per supportare una sorgente da file usare in alternativa un blocco
**From Multimedia File** o **Audio File Read** collegato all'ingresso 1 di `FxLMS`.

## Limitazioni note

- Modello SISO (1 sorgente, 1 emettitore, 1 mic) come l'implementazione attuale
  in `FxLMSFilter.m`.
- Il modello e' costruito programmaticamente (no `.slx` binario in repo) per
  ragioni di reviewabilita' git diff.
- `Field3DSink` aggiorna ogni `RefreshDecim` step (default 20) per evitare
  saturazione del rendering.
