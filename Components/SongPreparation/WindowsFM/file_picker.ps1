param([string]$initialDir)

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class DPIHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@
[DPIHelper]::SetProcessDPIAware()

Add-Type -AssemblyName System.Windows.Forms
$ofd = New-Object System.Windows.Forms.OpenFileDialog
$ofd.InitialDirectory = $initialDir
$ofd.Multiselect = $true
$ofd.Filter = "All files (*.*)|*.*"

if ($ofd.ShowDialog() -eq "OK") {
    $ofd.FileNames -join "`n"
}
