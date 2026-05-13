# 04. Geometria indoor, leakage path e limiti del simulatore spaziale

## Perche questo documento esiste

Il file conserva il nome storico, ma il suo ruolo canonico e diverso: chiarire quale **modello spaziale** serve per un prodotto indoor di `bass spill control`, e dove il simulatore attuale aiuta oppure resta incompleto.

## 1. La geometria che conta davvero

Per il prodotto non conta tanto la sorgente mobile astratta, quanto la relazione tra:

- sorgente musicale interna;
- modi della stanza;
- pareti e superfici radianti;
- aperture, porte, finestre e confini;
- microfoni interni ed esterni;
- posizionamento degli emitter ANC.

Il problema reale e quindi un problema di **propagazione indoor orientata al leakage**.

## 2. Diretto, riflesso e strutturale

In una venue reale il boundary esterno non riceve solo una propagazione diretta semplificata. Riceve una combinazione di:

- campo diretto irradiato dalle sorgenti interne;
- campo riflesso e modale interno;
- radiazione da pareti o superfici che vibrano;
- fuga localizzata da aperture e varchi.

Questo significa che il modello spaziale deve servire a rispondere a una domanda concreta: **quali percorsi dominano davvero lo spill?**

## 3. Punti di misura utili in una venue

| Zona | Perche e rilevante |
|---|---|
| dancefloor / listening points | serve contenere il degrado interno |
| pareti critiche | possono irradiare energia verso l'esterno |
| aperture e passaggi | concentrano leakage e diventano hot spot |
| boundary esterno | punto principale per KPI e compliance |

## 4. Cosa fa oggi il simulatore

Il repository attuale offre due cose utili:

- genera sorgenti difficili e non stazionarie;
- modella ritardo, attenuazione e assorbimento in spazio semplificato.

Questo e utile per stressare il controllore, ma non coincide ancora con un benchmark venue-oriented.

## 5. Room modes e punti critici

Una venue indoor presenta punti di pressione molto diversi a causa dei modi. In pratica:

- alcuni listening point possono essere quasi neutri;
- altri punti interni possono eccitare fortemente le strutture;
- alcuni boundary point esterni diventano il collo di bottiglia della vendibilita.

Ne segue che il simulatore utile non deve solo "generare un segnale", ma mappare una relazione spaziale tra:

- contenuto musicale;
- modi interni;
- posizioni emitter;
- punti interni vincolati;
- punti esterni obiettivo.

## 6. Come leggere `MovingJackhammer`

`MovingJackhammer` va trattato come **stress test legacy**, non come scenario commerciale di riferimento. E utile per:

- testare ritardo variabile;
- osservare sensibilita del controllore a plant tempo-variante;
- verificare robustezza del codice.

Non descrive invece il caso d'uso primario del prodotto, che e una venue indoor con contenuto musicale noto e riferimento acquisito da `mixer/DSP`.

## 7. Perche i test dinamici restano comunque utili

Anche se non sono il focus di go-to-market, gli scenari dinamici restano utili perche:

- mettono in crisi i ritardi del controller;
- rendono evidente il ruolo del `secondary path`;
- aiutano a testare il `tracking lag`;
- fanno emergere failure mode che in condizioni statiche potrebbero restare nascosti.

Quindi il loro ruolo corretto e di **stress test**, non di narrativa commerciale.

## 8. Elementi spaziali che la roadmap deve introdurre

| Modulo roadmap | Funzione |
|---|---|
| `VenueRoomModel.m` | geometria indoor e modi dominanti |
| `BoundaryLeakageModel.m` | perdita di energia verso confini e aperture |
| sensor mapping | array interni e microfoni di confine |
| emitter placement model | nodi ANC distribuiti su pareti o zone critiche |
| venue benchmark scripts | scenari standardizzati e confrontabili |

## 9. Formulazione minima di un modello venue-oriented

Un modello utile deve essere almeno capace di esprimere:

```math
\mathbf{p}_{ext}(n)=\mathbf{H}_{leak}(z)\mathbf{u}(n)
```

dove:

- `\mathbf{u}(n)` rappresenta le sorgenti interne e gli emitter ANC;
- `\mathbf{H}_{leak}(z)` aggrega i percorsi che portano energia ai boundary esterni.

In parallelo serve monitorare:

```math
\mathbf{p}_{int}(n)=\mathbf{H}_{int}(z)\mathbf{u}(n)
```

per non degradare i listening point interni.

## 10. Limiti espliciti del modello attuale

- il campo acustico non e ancora modellato come `MIMO` di venue;
- mancano riflessioni e leakage path espliciti su boundary reali;
- non esiste ancora una mappa prestazionale su piu punti interni/esterni;
- il riferimento principale e ancora generato dal simulatore, non da una pipeline di `reference ingest` venue-like.

## 11. Criterio corretto per evolvere il modello

Il simulatore deve smettere di chiedersi "riesco a cancellare una sorgente difficile?" e iniziare a chiedersi:

1. quali modi interni eccitano di piu lo spill;
2. dove si trovano i punti esterni piu critici;
3. quali nodi ANC offrono il miglior compromesso tra riduzione esterna e impatto interno;
4. quanto e stabile la soluzione con musica reale.

## 12. Output attesi da un benchmark indoor serio

- mappa dei punti interni di riferimento;
- mappa dei boundary point esterni;
- riduzione per banda e per punto;
- confronto `ANC on/off`;
- tempo di commissioning e tempo di retuning.

## Sintesi

Il valore del modello spaziale non sta nel "3D" come etichetta, ma nella sua capacita di prevedere e controllare **le vie di dispersione indoor in bassa frequenza**. Il simulatore attuale e una buona base, ma la roadmap deve portarlo verso un digital twin di venue.
