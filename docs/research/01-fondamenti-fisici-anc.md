# 01. Fondamenti fisici del bass spill control indoor

## Tesi fisica

Il prodotto non nasce per "spegnere il locale", ma per **ridurre l'energia che esce dal locale** nelle bande che generano piu disturbo ai vicini. In prima generazione questo significa:

- lavorare soprattutto tra `25 Hz` e `160 Hz`;
- controllare i modi indoor e i leakage path dominanti;
- usare un riferimento `feed-forward` acquisito da `mixer`, `DSP` o uscita `sub`;
- ottimizzare il campo acustico su **piu punti**, non su un solo microfono.

## 1. Equazione delle onde e scala del problema

Nel regime lineare la pressione acustica soddisfa:

```math
\nabla^2 p - \frac{1}{c^2}\frac{\partial^2 p}{\partial t^2}=0
```

con `c \approx 343 m/s` a temperatura ambiente.

Questa formula impone due realta:

- la propagazione introduce ritardo, quindi la causalita e un vincolo reale;
- la fase dipende fortemente dalla frequenza e dalla posizione nello spazio.

## 2. Perche la bassa frequenza e il punto giusto

La lunghezza d'onda vale:

```math
\lambda = \frac{c}{f}
```

| Frequenza | Lunghezza d'onda | Implicazione pratica |
|---|---:|---|
| `31.5 Hz` | `10.9 m` | forte interazione con il volume della venue |
| `63 Hz` | `5.4 m` | banda tipica di sub e modi dominanti |
| `125 Hz` | `2.7 m` | ancora utile, ma con maggiore sensibilita spaziale |

La bassa frequenza e il dominio piu sensato per il controllo attivo perche:

- varia meno rapidamente nello spazio;
- e la componente che attraversa meglio pareti e aperture;
- e spesso il driver principale dei reclami da vicinato;
- e la regione dove un controllo distribuito puo ancora influire in modo credibile.

## 3. Ritardo di propagazione e causalita

Se una perturbazione percorre una distanza `r`, il tempo di volo e:

```math
\tau = \frac{r}{c}
```

A `48 kHz`, per `r = 1 m`:

```math
\tau \approx 2.92 ms
```

```math
D \approx 140 \text{ campioni}
```

Questo numero basta a capire perche un sistema solo microfonico e svantaggiato: quando il microfono sente il problema, una parte del danno acustico e gia avvenuta.

## 4. Vantaggio del riferimento da mixer/DSP

Un riferimento acquisito da `mixer`, `DSP` o uscita `sub` offre un anticipo informativo rispetto al campo irradiato nella stanza. Questo:

- aumenta il margine utile di causalita;
- rende il sistema davvero `feed-forward`;
- rende piu prevedibile il controllo sulle bande musicali target.

Da qui la scelta architetturale del piano:

- `reference ingest` a monte del sistema audio;
- microfoni interni per osservare il campo;
- microfoni di boundary o esterni per misurare lo spill;
- controllo ed elaborazione su `Edge DSP Controller`.

## 5. Spill control, non quiet zone puntuale

Un ANC classico da laboratorio spesso riduce il livello in un solo punto di errore. Il problema prodotto e diverso: la riduzione utile deve apparire su **piu punti esterni**, con impatto interno controllato.

In forma compatta:

```math
\mathbf{e}(n)=\mathbf{d}(n)-\mathbf{S}(z)\mathbf{y}(n)
```

dove il vettore `\mathbf{e}(n)` rappresenta piu sensori, non un singolo microfono.

## 6. Campo modale indoor

La venue indoor non e un campo libero. Nella banda bassa conta la struttura modale della stanza:

```math
f_{mnp} = \frac{c}{2}\sqrt{
\left(\frac{m}{L_x}\right)^2+
\left(\frac{n}{L_y}\right)^2+
\left(\frac{p}{L_z}\right)^2}
```

In pratica:

- alcuni punti vengono eccitati molto piu di altri;
- certe bande basse sono persistenti e difficili da gestire;
- il controllo deve essere pensato in relazione a modi, pareti e aperture.

## 7. Leakage e superfici radianti

Lo spill non e soltanto il suono che "passa". E spesso la combinazione di:

- trasmissione attraverso pareti leggere;
- emissione da superfici che vibrano;
- fuga localizzata da porte, finestre, corridoi e aperture;
- concentrazione di energia in pochi hot spot esterni.

Per questo il problema corretto non e "annullare una sorgente", ma **disinnescare le vie di leakage dominanti**.

## 8. Perche indoor prima di outdoor

L'indoor e il beachhead corretto per motivi fisici e commerciali:

- geometria piu stabile;
- sorgente musicale nota e disponibile a monte del sistema;
- modalita di calibrazione ripetibile;
- minore variabilita atmosferica e di layout rispetto all'outdoor.

Il sistema nasce quindi per **venue indoor permanenti**, con outdoor lasciato a una fase successiva.

## 9. MIMO come requisito, non estensione opzionale

Una venue reale non ha un solo percorso acustico. Ha:

- piu zone energetiche interne;
- piu superfici radianti;
- piu percorsi verso il boundary;
- piu punti di misura critici.

Questo rende il `MIMO` un requisito naturale. Il `SISO` resta utile come baseline, ma non descrive l'architettura vendibile.

## 10. Conservazione dell'esperienza interna

Il sistema non e vendibile se riduce lo spill ma distrugge il suono nel locale. Il vincolo fisico-operativo e doppio:

- riduzione esterna misurabile;
- deviazione interna contenuta.

Il riferimento iniziale del piano e:

- `4-8 dB` di riduzione media esterna in banda bassa critica;
- variazione interna circa entro `+-2 dB` nei punti di riferimento.

## 11. Lettura corretta dei limiti fisici

- L'ANC e credibile sulle basse frequenze, non su tutto lo spettro.
- Il controllo utile e distribuito, non universale.
- La causalita richiede un riferimento anticipato, non solo microfoni.
- Il valore commerciale si misura sui boundary esterni e sulla tenuta interna, non su un plot locale isolato.

## Sintesi

La fisica del progetto porta a una sola conclusione: la prima generazione deve essere un **sistema indoor MIMO di bass spill control**, con riferimento da mixer/DSP ed esecuzione su `Edge DSP Controller`.
