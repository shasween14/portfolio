# usage: bash to-4x3.sh <dir of 16:9 jpgs> <out dir> <temp dir>   (needs ImageMagick 7)
# 16:9 gig image -> 1600x1200 (4:3) for Upwork: the image stays whole and sharp,
# the extra 150px above and below is its own edge stretched, blurred and faded.
set -e
SRC="$1"; OUT="$2"; TMP="$3"
W=1600; H=1200; IH=899; TOP=150; F=18
magick -size ${W}x${IH} xc:white \
  \( -size ${W}x${F} gradient:black-white \) -geometry +0+0 -composite \
  \( -size ${W}x${F} gradient:white-black \) -geometry +0+$((IH-F)) -composite \
  "$TMP/mask.png"
for f in "$SRC"/*.jpg; do
  n=$(basename "$f" .jpg)
  magick "$f" -resize ${W}x${IH}! "$TMP/$n-img.png"
  # colour the far edges fade into: that side's own average
  ct=$(magick "$TMP/$n-img.png" -crop ${W}x4+0+0 +repage -scale 1x1! -format "%[pixel:p{0,0}]" info:)
  cb=$(magick "$TMP/$n-img.png" -crop ${W}x4+0+$((IH-4)) +repage -scale 1x1! -format "%[pixel:p{0,0}]" info:)
  magick "$TMP/$n-img.png" \
    -set option:distort:viewport ${W}x${H}+0-${TOP} -virtual-pixel Edge -distort SRT 0 +repage \
    -blur 0x28 \
    \( -size ${W}x${TOP} gradient:"$ct"-none \) -geometry +0+0 -compose Over -composite \
    \( -size ${W}x$((H-TOP-IH)) gradient:none-"$cb" \) -geometry +0+$((TOP+IH)) -compose Over -composite \
    \( "$TMP/$n-img.png" "$TMP/mask.png" -alpha off -compose CopyOpacity -composite \) \
    -geometry +0+${TOP} -compose Over -composite \
    -quality 92 -sampling-factor 4:2:0 -strip "$OUT/$n.jpg"
  echo "$n  top=$ct  bottom=$cb"
done
