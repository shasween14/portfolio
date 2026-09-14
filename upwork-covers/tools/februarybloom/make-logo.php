<?php
// Stand-in wordmark for the sidebar slot: the theme's own display face, plain text.
$font = 'C:/laragon/www/februarybloom/public/assets/themes/florist/magnolia_script/Magnolia_Script.ttf';
$out  = 'C:/laragon/www/februarybloom/public/assets/uploads/1.logo.png';
$text = 'February Bloom';
$size = 44;

$im = imagecreatetruecolor(420, 96);
imagesavealpha($im, true);
imagefill($im, 0, 0, imagecolorallocatealpha($im, 0, 0, 0, 127));
$ink = imagecolorallocate($im, 43, 47, 56);

$box = imagettfbbox($size, 0, $font, $text);
$w = $box[2] - $box[0];
$h = $box[1] - $box[7];
imagettftext($im, $size, 0, (int)((420 - $w) / 2), (int)(96 - (96 - $h) / 2) - 8, $ink, $font, $text);

imagepng($im, $out);
echo "wrote $out (" . filesize($out) . " bytes)\n";
