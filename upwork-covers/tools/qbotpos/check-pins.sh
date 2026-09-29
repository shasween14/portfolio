#!/bin/bash
# usage: checkpins.sh <img> "x,y x,y ..."
img="$1"; shift
for pt in $@; do
  x=${pt%,*}; y=${pt#*,}
  ox=$((x-15)); oy=$((y-15))
  [ $ox -lt 0 ] && ox=0; [ $oy -lt 0 ] && oy=0
  read mn mx <<< $(magick "$img" -crop 30x30+$ox+$oy +repage -colorspace Gray -format "%[fx:minima*255] %[fx:maxima*255]" info:)
  mn=${mn%.*}; mx=${mx%.*}
  spread=$((mx-mn))
  if [ "$spread" -gt 60 ]; then echo "  BUSY  $pt  (min=$mn max=$mx spread=$spread)"; else echo "  ok    $pt  (min=$mn max=$mx)"; fi
done
