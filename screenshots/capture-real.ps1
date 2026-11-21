param(
    [Parameter(Mandatory=$true)][string]$Command,
    [Parameter(Mandatory=$true)][string]$Out
)
$proc = Start-Process powershell -ArgumentList '-NoExit','-Command',$Command -PassThru
Start-Sleep -Seconds 10

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W2 {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
# wait for MainWindowHandle
$h = $proc.MainWindowHandle
$tries = 0
while ($h -eq [IntPtr]::Zero -and $tries -lt 20) {
    Start-Sleep -Milliseconds 500
    $proc.Refresh()
    $h = $proc.MainWindowHandle
    $tries++
}
if ($h -ne [IntPtr]::Zero) {
    [W2]::ShowWindow($h, 3) | Out-Null
    [W2]::SetForegroundWindow($h) | Out-Null
}
Start-Sleep -Seconds 2

Add-Type -AssemblyName System.Drawing, System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"OK -> $Out ($([math]::Round((Get-Item $Out).Length/1KB,1)) KB)"