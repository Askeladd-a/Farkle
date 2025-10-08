# Crash Reporter - Farkle

## Panoramica

Il gioco Farkle ora include un sistema di crash reporting automatico che cattura e salva informazioni dettagliate quando si verifica un errore.

## Come Funziona

### Cattura Automatica
- Il sistema cattura automaticamente tutti gli errori non gestiti
- Salva un report dettagliato in `crash_report.txt`
- Mostra una schermata di errore informativa all'utente

### Informazioni Salvate

Il crash report include:

1. **Informazioni Sistema**
   - Versione Love2D
   - Sistema operativo
   - Numero di processori
   - Risoluzione schermo
   - Uso memoria (se disponibile)
   - Timestamp del crash

2. **Informazioni Gioco**
   - Stato attuale del gioco
   - Giocatore attivo
   - Dadi rimanenti
   - Punteggio del round
   - Punteggi di tutti i giocatori

3. **Stack Trace**
   - Messaggio di errore completo
   - Stack trace dettagliato
   - Posizione esatta dell'errore nel codice

## File di Log

### Struttura
- `crash_report.txt` - Report più recente
- `crash_report.txt.1` - Report precedente
- `crash_report.txt.2` - Report ancora più vecchio
- ... (fino a 5 file)

### Gestione Automatica
- I file vengono ruotati automaticamente quando diventano troppo grandi (>1MB)
- Vengono mantenuti solo gli ultimi 5 report
- I file più vecchi vengono eliminati automaticamente

## Tasti di Debug (Solo per Sviluppatori)

- **F1** - Testa il crash reporter (genera un crash intenzionale)
- **F2** - Pulisce tutti i file di log
- **ESC** - Esce dal gioco (anche dalla schermata di crash)

## Esempio di Crash Report

```
=== CRASH REPORT FARKLE ===
Data: 2024-01-15 14:30:25

=== INFORMAZIONI SISTEMA ===
Love2D Version: 11.5.0
OS: Windows
Processori: 8
Risoluzione: 1920x1080
Memoria: 256 MB
Timestamp: 2024-01-15 14:30:25

=== INFORMAZIONI GIOCO ===
Stato gioco: playing
Giocatore attivo: 1
Dadi rimanenti: 3
Punteggio round: 500
Giocatore 1: You - Punti: 2500
Giocatore 2: Baron von Farkle - Punti: 1800

=== STACK TRACE ===
Errore: attempt to call a nil value

Stack Trace:
stack traceback:
    [C]: in function 'error'
    main.lua:1234: in function 'someFunction'
    main.lua:567: in function 'love.update'
    [C]: in function 'xpcall'

=== FINE REPORT ===
```

## Vantaggi

1. **Debug Facilitato** - Informazioni dettagliate per identificare problemi
2. **Supporto Utenti** - Gli utenti possono inviare i report per assistenza
3. **Monitoraggio** - Traccia la stabilità del gioco
4. **Sviluppo** - Aiuta a identificare e correggere bug

## Note Tecniche

- Il crash reporter viene inizializzato all'avvio del gioco
- Intercetta l'handler di errore di Love2D
- Funziona anche se il gioco è in uno stato inconsistente
- Non interferisce con il gameplay normale
