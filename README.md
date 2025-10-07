# Farkle Project Overview

Questo repository raccoglie idee e suggerimenti per creare un piccolo videogioco ispirato a Balatro ma basato sul gioco di dadi Farkle, utilizzando il framework [LÖVE](https://love2d.org/).

## È un progetto difficile?
Creare il tuo primo videogioco da zero senza esperienza di programmazione è una sfida, ma non è impossibile. Le difficoltà principali includono:

- **Imparare Lua e LÖVE**: dovrai acquisire dimestichezza con la sintassi del linguaggio Lua e con l'API di LÖVE per gestire grafica, input e audio.
- **Gestione della fisica dei dadi**: ottenere un effetto "roll" credibile richiede animazioni o simulazioni semplificate. In isometria servirà calcolare posizioni, livelli di profondità e possibili sovrapposizioni.
- **Logica del punteggio Farkle**: il gioco richiede il riconoscimento delle combinazioni di dadi e l'assegnazione dei punteggi (inclusi elementi speciali come il "Devil's Head").
- **Interfaccia e feedback**: bisogna curare layout, pulsanti (lancio, banca, mantieni dadi), e fornire feedback visivo/auditivo chiaro al giocatore.

## Approccio consigliato
1. **Studia le basi**
   - Completa un tutorial introduttivo su Lua.
   - Segui una guida per principianti su LÖVE (ad esempio "How to LÖVE" o la wiki ufficiale).
2. **Prototipo minimo**
   - Carica l'immagine della plancia come sfondo.
   - Disegna sei dadi statici in posizioni predefinite per comprendere il sistema di coordinate isometriche.
3. **Animare il lancio**
   - Implementa una semplice animazione: cambia rapidamente il valore mostrato sul dado prima di fermarlo su un numero casuale.
   - Aggiungi un effetto di movimento (per esempio con tweening) per simulare il rotolamento.
4. **Gestire l'input**
   - Permetti al giocatore di cliccare sui dadi per selezionarli e tenerli da parte.
   - Implementa i pulsanti "Roll", "Bank" e "End Turn".
5. **Calcolare i punteggi**
   - Codifica le regole di Farkle: combina valori dei dadi per determinare i punti, compresa la gestione dei dadi jolly.
   - Mostra il punteggio corrente e quello accumulato.
6. **Rifiniture**
   - Aggiungi effetti sonori e una breve guida in-game.
   - Mantieni il codice organizzato in moduli (per esempio `dice.lua`, `game_state.lua`).

## Suggerimenti pratici
- Inizia con vista top-down normale e passa all'isometria solo dopo aver stabilito la logica di gioco.
- Usa librerie di supporto (ad esempio [anim8](https://github.com/kikito/anim8) per le animazioni di sprite) per accelerare lo sviluppo.
- Versiona spesso il tuo codice con Git e testa ogni cambiamento.
- Considera di costruire piccoli prototipi mirati (solo lancio dei dadi, solo calcolo punteggio) prima di unirli.

## Risorse utili
- [LÖVE Wiki](https://love2d.org/wiki/Main_Page)
- [Lua Tutorial su learnxinyminutes](https://learnxinyminutes.com/docs/lua/)
- Video tutorial "Making your first LÖVE game" su YouTube
- Regole Farkle in italiano/inglese per riferimento rapido

## Prossimi passi
1. Configura LÖVE sul tuo computer e prova a far girare un semplice `main.lua` con una finestra vuota.
2. Aggiungi la plancia come immagine di sfondo.
3. Disegna dadi come semplici quadrati o sprite e implementa la funzione di lancio.
4. Itera gradualmente, aggiungendo punteggi e feedback.

Ricorda: procedere per piccoli passi e imparare facendo è la chiave per trasformare l'idea in un progetto giocabile.
