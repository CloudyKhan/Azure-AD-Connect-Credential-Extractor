# Azure AD Connect Credential Extractor (Pentesting Tool)

## Overview

This PowerShell script is designed for **authorized penetration testing** and **security labs** to extract and decrypt credentials from **Azure AD Connect Sync** configurations. The script connects to the ADSync SQL database, retrieves cryptographic keys, and decrypts the AD Connect credentials used for Active Directory synchronization.

This tool is intended to help penetration testers and red teamers in security labs or controlled environments identify weak security configurations in Azure AD Connect deployments. It must only be used in environments where you have **explicit permission** to test.

### Credit & Inspiration

This script is derived and adapted from the work of @_xpn_, who originally shared the concept and implementation in the blog post [Azure AD Connect for Red Teamers](https://blog.xpnsec.com/azuread-connect-for-redteam/). This script has been altered for smoother functionality, debugging, and error handling for labs and pentesting machines. 

Highly recommend checking out the original work to understand the initial concepts and techniques: [Azure AD Connect for Red Teamers](https://blog.xpnsec.com/azuread-connect-for-redteam/).

## Prerequisites

- **PowerShell** environment (Run with administrative privileges).
- Access to a machine running **Microsoft Azure AD Connect**.
- **mcrypt.dll** must be present on the system in one of the following paths:
  - `C:\Program Files\Microsoft Azure AD Sync\Bin\mcrypt.dll`
  - `C:\Program Files (x86)\Microsoft Azure AD Sync\Bin\mcrypt.dll`
  - `C:\Program Files\Microsoft Azure AD Connect\Bin\mcrypt.dll`

Ensure that you have administrative access to the machine and the necessary permissions to run the script.

## Usage

### Steps to Run the Script:

1. **Clone or download** the repository containing this script.
2. Open a PowerShell session **as an Administrator**.
3. Run the script using:
   ```powershell
   .\decrypt.ps1
   ```

4. The script will attempt to:
   - Connect to the ADSync SQL database.
   - Load the necessary cryptographic library (`mcrypt.dll`).
   - Retrieve and decrypt stored credentials (Domain, Username, and Password).

### Example Output:
```
Attempting connection: Data Source=(localdb)\.\ADSync;Initial Catalog=ADSync;Integrated Security=True
Error connecting to SQL database. Trying next...
Attempting connection: Data Source=localhost;Initial Catalog=ADSync;Integrated Security=True
Connection successful!
Loading mcrypt.dll from: C:\Program Files\Microsoft Azure AD Sync\Bin\mcrypt.dll
Domain: YOURDOMAIN.LOCAL
Username: administrator
Password: P@ssw0rd123!
```

The decrypted credentials will be printed to the console.

### Important Notes:

- **Ensure `mcrypt.dll` is present** in one of the default paths listed above. The script requires this file to perform decryption.
- The script will try multiple SQL connection strings to find the correct instance of the ADSync database.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Legal Use Statement

This script is intended for **authorized penetration testing**, **red team labs**, and **security auditing** only. You must have explicit permission from the system’s owner to run this script. Unauthorized use of this tool to access or decrypt credentials from systems is illegal.

The author of this script is **not liable** for any legal issues, damages, or misuse of this tool. Always ensure you have proper authorization before performing any security assessments.
## Disclaimer

**This script is provided for educational purposes, security lab environments, and authorized penetration testing only. Unauthorized use of this script to extract credentials or access systems without explicit permission is illegal and may violate local, state, national, or international laws.**

By using this tool, you agree that:
- **You are solely responsible for ensuring that you have explicit authorization** to test the target system.
- **You are in compliance with all applicable laws** and regulations before using this script.
- The author of this tool **is not liable** for any misuse, damage, or legal issues resulting from the use of this script.
