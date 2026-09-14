<?php
// Sample the source pixels under each proposed pin: a pin may only sit on flat
// background, so min/max luminance across the disc has to stay close together.
// usage: php check-pins.php <png> <x,y> <x,y> ...

$file = $argv[1];
$img = imagecreatefrompng($file);
$W = imagesx($img); $H = imagesy($img);
$r = 17; // pin radius + 2px halo

for ($i = 2; $i < $argc; $i++) {
    [$cx, $cy] = array_map('intval', explode(',', $argv[$i]));
    $min = 255; $max = 0; $out = false;
    for ($y = $cy - $r; $y <= $cy + $r; $y++) {
        for ($x = $cx - $r; $x <= $cx + $r; $x++) {
            if (($x - $cx) ** 2 + ($y - $cy) ** 2 > $r * $r) continue;
            if ($x < 0 || $y < 0 || $x >= $W || $y >= $H) { $out = true; continue; }
            $c = imagecolorat($img, $x, $y);
            $lum = (int)(0.299 * (($c >> 16) & 0xFF) + 0.587 * (($c >> 8) & 0xFF) + 0.114 * ($c & 0xFF));
            $min = min($min, $lum); $max = max($max, $lum);
        }
    }
    $spread = $max - $min;
    printf("%-12s min=%3d max=%3d spread=%3d  %s%s\n", "$cx,$cy", $min, $max, $spread,
        ($spread <= 20) ? 'CLEAR' : 'BUSY', $out ? ' (off-canvas)' : '');
}
