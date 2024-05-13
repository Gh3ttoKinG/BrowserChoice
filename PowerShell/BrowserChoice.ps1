<#
param(
	[Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$false)]
	[String]$URL
)
#>

#Add-Type -AssemblyName PresentationFramework
#region XAML

$XAML = @'

<Window x:Class="Browser_Choice.MainWindow"
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
		xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
		xmlns:local="clr-namespace:Browser_Choice"
		mc:Ignorable="d"
		Title="Browser Choice" Height="538" Width="800" MinHeight="525" MinWidth="675">
	<Grid>
		<Label Content="Website" Height="32" Margin="10,10,10,0" VerticalAlignment="Top" FontSize="16" VerticalContentAlignment="Bottom"/>
		<TextBox x:Name="Website" Height="96" Margin="10,42,10,0" TextWrapping="Wrap" VerticalAlignment="Top" FontSize="24"/>
		<Button x:Name="Copy" Content="Copy" Margin="426,158,0,0" FontSize="24" Height="48" VerticalAlignment="Top" HorizontalAlignment="Left" Width="96" Click="Copy_Click"/>
		<Label Content="Select Program" Height="32" Margin="10,138,10,0" VerticalAlignment="Top" FontSize="16" VerticalContentAlignment="Bottom"/>
		<ComboBox x:Name="ComboBox_Programs" Margin="10,170,0,0" VerticalAlignment="Top" FontSize="24" Height="36" SelectionChanged="ComboBox_Programs_SelectionChanged" HorizontalAlignment="Left" Width="390"/>
		<Label Content="Program" Height="32" Margin="10,206,10,0" VerticalAlignment="Top" FontSize="16" VerticalContentAlignment="Bottom"/>
		<TextBox x:Name="Program" Height="36" Margin="10,238,10,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" FontSize="24" IsReadOnly="True"/>
		<Label Content="Parameters" Height="32" Margin="10,274,10,0" VerticalAlignment="Top" FontSize="16" VerticalContentAlignment="Bottom"/>
		<TextBox x:Name="Parameters" Height="96" Margin="10,306,10,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" FontSize="24" IsReadOnly="True"/>
		<Button x:Name="Open" Content="Open" Margin="304,420,0,0" FontSize="24" Height="48" VerticalAlignment="Top" HorizontalAlignment="Left" Width="96" Click="Open_Click"/>
		<Button x:Name="Abort" Content="Abort" Margin="10,420,0,0" FontSize="24" Height="48" VerticalAlignment="Top" HorizontalAlignment="Left" Width="96" Click="Abort_Click"/>
		<Button x:Name="CopyAppend" Content="Append" Margin="540,158,0,0" FontSize="24" Height="48" VerticalAlignment="Top" HorizontalAlignment="Left" Width="96"/>
	</Grid>
</Window>

'@
#-replace("x:Name", 'Name') -replace('x:Class="\S+"', '') -replace('mc:Ignorable="d"', '') #-replace '^<Win.*', '<Window' 

$XAML = $XAML -replace("x:Name", 'Name') -replace('x:Class="\S+"', '') -replace('mc:Ignorable="d"', '') #-replace '^<Win.*', '<Window'
$XAML = $XAML -replace('Click="\S+"', '') -replace('SelectionChanged="\S+"', '') -replace('TextChanged="\S+"', '') 
$XAML = $XAML -replace('KeyUp="\S+"', '') -replace('KeyDown="\S+"', '')
[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
$XAML = [xml]$XAML

#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
try {
	$Form = [Windows.Markup.XamlReader]::Load( $reader )
} catch {
	Write-Warning ("Unable to parse XML with the following Error: " + [Environment]::NewLine + $Error[0] + [Environment]::NewLine + "Make sure it doesn't contain any Events (like KeyDown or SelectionChanged)")
	throw
}
#endregion


#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================

$WPF = @{};
$XAML.SelectNodes("//*[@Name]") | %{"Trying to set varoable for item $($_.Name)";
	try {
		#Set-Variable -Name "WPF.$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop
		$WPF.$($_.Name) = $Form.FindName($_.Name)
	} catch {
		Throw -ErrorAction Stop
	}
}
 
Function Get-FormVariables{
  if ($global:ReadmeDisplay -ne $true) {
	  Write-Host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;
	  $global:ReadmeDisplay=$true
  }
  Write-Host "Found the following interactable elements from our form" -ForegroundColor Cyan
  #Get-Variable WPF*
  $WPF | Out-Host
}
 
Get-FormVariables
 
#===========================================================================
# Use this space to add code to the various form elements in your GUI
#===========================================================================

$Programs = @();
$WPF.Website.Text = $args;
#$WPF.Website.Text = $URL;

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

$Browsers = Get-ChildItem 'Registry::HKLM\SOFTWARE\Clients\StartMenuInternet\';
foreach ($Browser in $Browsers) {
	$ProgramName = ($Browser | Get-ItemProperty).'(default)'
	$ProgramPath = "";
	$ProgramParameters = "";
	try {
		$BrowserCall = "";
		If (Test-Path ('Registry::' + $Browser + '\Capabilities\URLAssociations\')) {
			$Reference = (Get-ItemProperty('Registry::' + $Browser + '\Capabilities\URLAssociations\')).'https'
			If ($Reference) {
				If (Test-Path ('Registry::HKCR\' + $Reference + '\shell\open\command')) {
					$BrowserCall = (Get-ItemProperty('Registry::HKCR\' + $Reference + '\shell\open\command')).'(default)';
				}
			}
		} else {
			$BrowserCall = (Get-ItemProperty('Registry::' + $Browser + '\shell\open\command')).'(default)';
		}
		
		If ($BrowserCall.Contains('"')) {
			$BrowserCallSplit = [regex]::Split( $BrowserCall, ' (?=(?:[^"]|"[^"]*")*$)' )
			$ProgramPath = $BrowserCallSplit[0];
			for ($i = 1; $i -lt $BrowserCallSplit.Length; $i++) {
				$ProgramParameters += $BrowserCallSplit[$i] + ' ';
			}
			$ProgramParameters = $ProgramParameters.Trim();
		} else {
			$ProgramPath = $BrowserCall;
			$ProgramParameters = "";
		}
		$Programs += [PSCustomObject] @{
			Name = $ProgramName;
			Path = $ProgramPath;
			Parameters = $ProgramParameters;
		}
	} catch {
		Write-Host AH2
	}
}
foreach ($Program in $Programs) {
	[void]$WPF.ComboBox_Programs.Items.Add($Program.Name);
}
$WPF.ComboBox_Programs.Add_SelectionChanged({
	$WPF.Program.Text = $Programs[$WPF.ComboBox_Programs.SelectedIndex].Path
	$WPF.Parameters.Text = $Programs[$WPF.ComboBox_Programs.SelectedIndex].Parameters
})

$WPF.Open.Add_Click({
	Start-Process -FilePath $WPF.Program.Text -ArgumentList ($WPF.Parameters.Text.Replace('%1', $WPF.Website.Text))
})

$WPF.Abort.Add_Click({
	$Form.Close();
})

$WPF.Copy.Add_Click({
	Set-Clipboard ($WPF.Website.Text);
})
$WPF.CopyAppend.Add_Click({
	Set-Clipboard -Append ($WPF.Website.Text);
})

$Form.Icon = ($PSScriptRoot + '\BrowserChoice.ico');
$Form.ShowDialog() | Out-Null
