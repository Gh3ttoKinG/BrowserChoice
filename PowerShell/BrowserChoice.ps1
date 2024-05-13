If (Test-Path ($PSScriptRoot + '\BrowserChoice.ini')) {
    try {
      $ProgramList = Get-Content ($PSScriptRoot + '\BrowserChoice.ini');
      $ProgramList = $ProgramList.Split([Environment]::NewLine);
      foreach ($Program in $ProgramList) {
        $ProgramSplit = $Program.Split(';');
        $Programs += [PSCustomObject] @{
          Name = $ProgramSplit[0];
          Path = $ProgramSplit[1];
          Parameters = $ProgramSplit[2];
        }
      }
    } catch {
        Write-Host "The file could not be read:";
        Write-Host $Error[0];
    }
} Else {
    Write-Host "No *.ini file found, not adding custom programs.";
}
