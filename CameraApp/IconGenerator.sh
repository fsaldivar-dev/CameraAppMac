
#!/bin/bash

# Nombre del archivo de imagen de origen (asegúrate de que este archivo exista en el mismo directorio que este script)
SOURCE_IMAGE="/Users/saldivar/Desktop/icon.png"


# Nombre del directorio donde se guardarán las imágenes redimensionadas
OUTPUT_DIR="./macOS_Icon_Asset"

# Crea el directorio de salida si no existe
mkdir -p $OUTPUT_DIR

# Lista de tamaños para los iconos de macOS
SIZES=("16" "32" "64" "128" "256" "512")

# Genera los iconos en varios tamaños
for SIZE in "${SIZES[@]}"; do
  sips -z $SIZE $SIZE $SOURCE_IMAGE --out "$OUTPUT_DIR/icon_${SIZE}x${SIZE}.png"
  sips -z $(($SIZE * 2)) $(($SIZE * 2)) $SOURCE_IMAGE --out "$OUTPUT_DIR/icon_${SIZE}x${SIZE}@2x.png"
done

echo "Iconos generados en el directorio $OUTPUT_DIR"
