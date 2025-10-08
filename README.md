# Farkle Prototype

Questo repository contiene un prototipo giocabile di Farkle sviluppato con [LÖVE](https://love2d.org/), pensato come punto di
partenza per un progetto più ampio ispirato all'estetica di Balatro. L'ultima iterazione mantiene l'esperienza strictly singleplayer: affronti sempre "Neon Bot", un avversario controllato dall'IA che decide quando bloccare, rilanciare o incassare.

## Come provarlo
1. Installa LÖVE 11.5 (o versione compatibile) dal sito ufficiale.
   - **Windows**: scarica l'eseguibile `.exe` e installalo; aggiungi eventualmente il percorso di LÖVE alle variabili d'ambiente per richiamare `love` dal terminale.
   - **macOS**: trascina LÖVE nella cartella Applicazioni, quindi esegui `ln -s /Applications/love.app/Contents/MacOS/love /usr/local/bin/love` per avere il comando `love` disponibile dal terminale.
   - **Linux**: installa il pacchetto fornito dalla tua distribuzione (es. `sudo pacman -S love`, `sudo apt install love`).
2. Verifica l'installazione aprendo un terminale ed eseguendo `love --version`: dovresti vedere la versione installata e altre informazioni di build.
3. Scarica o clona questo repository.
4. Avvia il gioco con `love .` eseguito nella cartella del progetto.
5. Usa il pulsante **Roll Dice** nell'angolo in basso per lanciare i dadi e vederli disporsi in proiezione isometrica sulla plancia in legno allegata.
6. Clicca con il tasto sinistro su un dado per "bloccarlo": se è disponibile lo sprite con bordo, il dado userà automaticamente la versione incorniciata del foglio `sheet.png`; in caso contrario rimarrà illuminato dal glow giallo e non verrà rilanciato.
7. Quando hai accumulato abbastanza punti, clicca **Bank Points** per incassare il turno; il riquadro in alto a sinistra mostra il potenziale del roll corrente e quello accumulato dai dadi bloccati.

### Test rapido senza terminale
Se preferisci non usare la riga di comando, puoi trascinare la cartella del progetto (o un archivio `.zip` del repository) direttamente sull'eseguibile di LÖVE: l'applicazione si avvierà caricando il prototipo.

L'immagine della plancia (`assets/board.png`) e le facce dei dadi (`assets/die1.png` … `assets/die6.png`) corrispondono agli asset forniti dall'utente. Se aggiungi il foglio `assets/sheet.png` allegato con lo stesso nome, il gioco userà automaticamente le coordinate descritte in `assets/dice_atlas.lua` per leggere le animazioni dal texture atlas (inclusa la variante con bordo per i dadi bloccati). In assenza del foglio, il codice ricompone dinamicamente uno sprite sheet temporaneo partendo dalle sei facce individuali.

## Struttura del codice
- `main.lua`: gestisce caricamento risorse, animazioni dei dadi tramite [anim8](https://github.com/kikito/anim8), input, rendering, calcolo rapido del punteggio roll/hold e la logica dei turni (inclusa la decisione dell'IA Neon Bot su quando rilanciare o bancare).
- `conf.lua`: configura la finestra del progetto LÖVE (risoluzione, titolo, identità).
- `lib/anim8.lua`: versione vendorizzata della libreria anim8 (MIT) per semplificare la gestione di animazioni basate su spritesheet.
- `lib/menu.lua`: raccoglie tutta la logica del menù principale (navigazione, rendering, reset) così che `main.lua` rimanga più snello.
- `lib/ai.lua`: incapsula euristiche e tempistiche dell'IA "Neon Bot", alleggerendo ulteriormente `main.lua`.
- `lib/scoring.lua`: contiene le funzioni di calcolo del punteggio Farkle e viene riutilizzato sia durante il roll sia durante il banking.
- `assets/board.png`: plancia in legno fornita dall'utente.
- `assets/die1.png` … `assets/die6.png`: facce dei dadi stilizzate fornite dall'utente.
- `assets/sheet.png` (opzionale): texture atlas dei dadi fornito dall'utente.
- `assets/dice_atlas.lua`: mappa le coordinate dei frame normali e con bordo all'interno di `sheet.png`.


La logica dei dadi utilizza coordinate isometriche semplificate; i valori vengono ordinati per profondità in modo da disegnare i
cubi con corretta sovrapposizione. Un easing "ease-out" crea un movimento morbido durante il roll mentre anim8 cicla rapidamente le facce per simulare la rotazione dei dadi.

## Roadmap suggerita
1. **Studia le basi**
   - Completa un tutorial introduttivo su Lua.
   - Segui una guida per principianti su LÖVE (ad esempio "How to LÖVE" o la wiki ufficiale).
2. **Espandi il prototipo**
   - Implementa la selezione dei dadi cliccabili e i pulsanti UI (Roll, Bank, End Turn).
   - Aggiungi effetti particellari o glow sui dadi durante il roll.
3. **Implementa il gameplay**
   - Codifica le regole di punteggio di Farkle, compresi i dadi speciali se previsti.
   - Gestisci turni, banca del punteggio e feedback al giocatore (testi, audio, animazioni).
4. **Rifiniture**
   - Organizza il codice in moduli (`dice.lua`, `game_state.lua`, `ui.lua`).
   - Aggiungi effetti sonori, musica di sottofondo e tutorial in-game.

## Risorse utili
- [LÖVE Wiki](https://love2d.org/wiki/Main_Page)
- [Lua Tutorial su learnxinyminutes](https://learnxinyminutes.com/docs/lua/)
- Video tutorial "Making your first LÖVE game" su YouTube
- Regole Farkle (italiano/inglese) per riferimento rapido

Procedi per piccoli passi: sperimenta, testa, e consolida ogni feature prima di passare alla successiva. Buon divertimento con lo
sviluppo!