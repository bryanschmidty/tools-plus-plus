Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile($args[0])
$colors = @{}
for ($y = 0; $y -lt $img.Height; $y++) {
    for ($x = 0; $x -lt $img.Width; $x++) {
        $c = $img.GetPixel($x, $y)
        if ($c.A -le 16) { continue }
        $key = "{0,3},{1,3},{2,3}" -f $c.R, $c.G, $c.B
        if (-not $colors.ContainsKey($key)) { $colors[$key] = 0 }
        $colors[$key]++
    }
}
$img.Dispose()
$colors.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Output "$($_.Name) count=$($_.Value)" }
