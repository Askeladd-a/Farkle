#!/usr/bin/env python3
"""
Script per convertire spritesheet di dadi da formato 2x3 a formato 1x6
Usa: python convert_spritesheet.py input.png output.png
"""

import sys
from PIL import Image

def convert_spritesheet(input_path, output_path):
    """
    Converte uno spritesheet 2x3 in formato 1x6
    Mappa: (1,1)=6, (2,1)=3, (1,2)=5, (2,2)=1, (1,3)=1, (2,3)=4
    Output: 1, 2, 3, 4, 5, 6 (dove 2 usa 1 come fallback)
    """
    try:
        # Carica l'immagine
        img = Image.open(input_path)
        width, height = img.size
        
        # Verifica che sia 192x128 (2x3 di frame 64x64)
        if width != 192 or height != 128:
            print(f"Errore: L'immagine deve essere 192x128 pixel, ma è {width}x{height}")
            return False
        
        # Crea la nuova immagine 384x64 (1x6 di frame 64x64)
        new_img = Image.new('RGBA', (384, 64), (0, 0, 0, 0))
        
        # Mappa le posizioni
        # Input: (1,1)=6, (2,1)=3, (1,2)=5, (2,2)=1, (1,3)=1, (2,3)=4
        # Output: 1, 2, 3, 4, 5, 6
        mappings = [
            # (input_x, input_y, output_x)
            (1, 1, 5),  # 6 -> posizione 5
            (1, 0, 2),  # 3 -> posizione 2  
            (0, 1, 4),  # 5 -> posizione 4
            (1, 1, 0),  # 1 -> posizione 0
            (1, 2, 1),  # 1 (duplicato) -> posizione 1 (come fallback per 2)
            (1, 2, 3),  # 4 -> posizione 3
        ]
        
        for input_x, input_y, output_x in mappings:
            # Calcola le coordinate
            src_x = input_x * 64
            src_y = input_y * 64
            dst_x = output_x * 64
            dst_y = 0
            
            # Copia il frame
            frame = img.crop((src_x, src_y, src_x + 64, src_y + 64))
            new_img.paste(frame, (dst_x, dst_y))
        
        # Salva la nuova immagine
        new_img.save(output_path)
        print(f"Spritesheet convertito salvato come: {output_path}")
        return True
        
    except Exception as e:
        print(f"Errore durante la conversione: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python convert_spritesheet.py input.png output.png")
        print("Converte uno spritesheet 2x3 in formato 1x6")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if convert_spritesheet(input_file, output_file):
        print("Conversione completata con successo!")
    else:
        print("Conversione fallita!")
        sys.exit(1)
