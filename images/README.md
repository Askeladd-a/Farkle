# Spritesheet dei Dadi

Per usare le animazioni dei dadi, crea un file chiamato `dice_spritesheet.png` in questa cartella.

## Formati Supportati:

### **Formato 1: Layout Orizzontale (Raccomandato)**
- **Dimensioni**: 384x64 pixel (6 frame da 64x64 pixel ciascuno)
- **Layout**: Una singola riga orizzontale con 6 frame
- **Ordine dei frame**: 
  1. Faccia 1 (1 pip)
  2. Faccia 2 (2 pip)
  3. Faccia 3 (3 pip)
  4. Faccia 4 (4 pip)
  5. Faccia 5 (5 pip)
  6. Faccia 6 (6 pip)

```
[Frame 1] [Frame 2] [Frame 3] [Frame 4] [Frame 5] [Frame 6]
  64px      64px      64px      64px      64px      64px
```

### **Formato 2: Layout Griglia 2x3**
- **Dimensioni**: 192x128 pixel (6 frame da 64x64 pixel in griglia 2x3)
- **Layout**: Due righe, tre colonne
- **Mappatura automatica**: Il sistema rileva automaticamente il formato

```
[Frame 1] [Frame 2]
[Frame 3] [Frame 4]
[Frame 5] [Frame 6]
```

## Note:

- Se non fornisci un spritesheet, il gioco creerà automaticamente uno di fallback
- Ogni frame dovrebbe essere 64x64 pixel
- I dadi verranno ridimensionati automaticamente a 48x48 pixel nel gioco
- Puoi usare qualsiasi stile di dado che preferisci (realistico, pixel art, stilizzato, etc.)

## Suggerimenti per la Creazione:

1. **Software consigliati**: GIMP, Photoshop, Aseprite, o qualsiasi editor di immagini
2. **Stile**: Mantieni uno stile coerente per tutti i frame
3. **Colori**: Assicurati che i pip siano ben visibili
4. **Trasparenza**: Non è necessaria, ma puoi usarla se vuoi
