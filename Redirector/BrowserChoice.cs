using System.Diagnostics;

// Gets all commandline parameters that were used to start this program (the URL)
string CommandLines = "";
for (int i = 1; i < Environment.GetCommandLineArgs().Length; i++)
{
    CommandLines += Environment.GetCommandLineArgs()[i];
}

// Creates object for the command to run
ProcessStartInfo objProgram = new ProcessStartInfo();
objProgram.CreateNoWindow = true;
objProgram.UseShellExecute = false;

// Checks through the environment variable "path" if new PowerShell Core is installed and chooses that instead of Windows PowerShell
Console.WriteLine(Environment.GetEnvironmentVariable("path").Contains("\\PowerShell\\"));
objProgram.FileName = "powershell";
foreach (string path in Environment.GetEnvironmentVariable("path").Split(';'))
{
    if (path.ToLower().Contains("powershell") && !path.ToLower().Contains("windowspowersshell")) {
        objProgram.FileName = "pwsh";
    }
}

// Sets parameters for the powershell command
// Uses its own AssemblyName ("BrowserChoice") for the script name
// Rename the powershell script if you change the AssemblyName
//objProgram.WindowStyle = ProcessWindowStyle.Hidden;
objProgram.Arguments = "-WindowStyle Hidden -File \"" + (AppContext.BaseDirectory + System.Reflection.Assembly.GetExecutingAssembly().GetName().Name + ".ps1\"") + " " + CommandLines;

// Starts the powershell script with the given commandline parameters
try
{
    Process.Start(objProgram);
}
catch (Exception ex)
{
        Console.WriteLine(ex.Message);
}