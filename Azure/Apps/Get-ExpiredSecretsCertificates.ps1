<#
.SYNOPSIS
    Monitors and reports Entra ID (Azure AD) application secrets and certificates that are expired or approaching expiration.
    Have been setup to run with GITHUB Actions
    Version 2.0 (including SAML certificates)
.DESCRIPTION
    This script connects to Microsoft Graph and retrieves all applications to check their credentials status.
    It identifies:
    - Secrets that will expire in the next 30 days
    - Secrets that have already expired
    - Certificates that will expire in the next 30 days
    - Certificates that have already expired
    The results are formatted into an HTML report and sent via email using Azure Communication Services.

.REQUIREMENTS
    - Microsoft.Graph.Applications module
    - Azure CLI installed and logged in
    - Application permissions: Application.Read.All and Directory.Read.All
    - Azure Communication Services SMTP credentials

.PARAMETER None
    This script does not accept parameters.

.ENVIRONMENT
    Required environment variables (In my case from Github secrets):
    - AZURE_SMTP_USERNAME: Username for Azure Communication Services SMTP
    - AZURE_SMTP_PASSWORD: Password for Azure Communication Services SMTP

.OUTPUTS
    - Console output indicating email sending status
    - HTML formatted email with four tables showing:
        1. Soon-to-expire secrets (next 30 days)
        2. Already expired secrets
        3. Soon-to-expire certificates (next 30 days)
        4. Already expired certificates

.NOTES
    Version:        2.0
    Author:         Olav Tvedt
    Creation Date:  17.09.2025
    Purpose/Change: Initial script development

.EXAMPLE
    .\Get-ExpiredSecretsCertificates.ps1

#>
# App registration krav for å kunne kjøre dette scriptet: Application.Read.All og Directory.Read.All

Import-Module Microsoft.Graph.Applications

$secret = ConvertTo-SecureString -String (az account get-access-token --resource https://graph.microsoft.com|Convertfrom-Json).accesstoken -AsPlainText -Force
Connect-Graph -AccessToken $secret

# Connect to Microsoft Graph using service principal
 
# Define a list to hold expired secrets
$expiredSecrets = New-Object System.Collections.ArrayList
$expiringSecrets = New-Object System.Collections.ArrayList
$expiredCertificates = New-Object System.Collections.ArrayList
$expiringCertificates = New-Object System.Collections.ArrayList
$expiringSAMLCerts  = New-Object System.Collections.ArrayList
$expiredSAMLCerts= New-Object System.Collections.ArrayList 
 
# Get all applications
$applications = Get-MgApplication -All | sort "DisplayName"

# Get current date and calculate the date 30 days from now
$currentDate = Get-Date
$futureDate = $currentDate.AddDays(30)
 
foreach ($app in $applications) {
    # Get the password credentials (secrets) for the application
    $passwordCredentials = $app.PasswordCredentials
    
    foreach ($credential in $passwordCredentials) {
        if ($credential.EndDateTime -le $futureDate -and $credential.EndDateTime -gt $currentDate) {
            $properties1 = @{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                SecretId  = $credential.KeyId
                EndDate   = ($credential.EndDateTime).ToString("dd.MM.yyyy")
            }
            $expiringSecrets.add((New-Object psobject -Property $properties1))
        } elseif ($credential.EndDateTime -lt $currentDate) {
            $properties2 = @{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                SecretId  = $credential.KeyId
                EndDate   = ($credential.EndDateTime).ToString("dd.MM.yyyy")
            }
            $expiredSecrets.add((New-Object psobject -Property $properties2))
        }
    }
    
    # Get the certificate credentials for the application
    $certificateCredentials = $app.KeyCredentials
    
    foreach ($cert in $certificateCredentials) {
        if ($cert.EndDateTime -le $futureDate -and $cert.EndDateTime -gt $currentDate) {
            $properties3 = @{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                CertId    = $cert.KeyId
                EndDate   = ($cert.EndDateTime).ToString("dd.MM.yyyy")
            }
            $expiringCertificates.add((New-Object psobject -Property $properties3))
        } elseif ($cert.EndDateTime -lt $currentDate) {
            $properties4 = @{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                CertId    = $cert.KeyId
                EndDate   = ($cert.EndDateTime).ToString("dd.MM.yyyy")
            }
            $expiredCertificates.add((New-Object psobject -Property $properties4))
        }
    }
}
# SAML Certificates
foreach ($app in $SAMLapps ) {
    if ($app.PasswordCredentials -and $app.PasswordCredentials.Count -gt 0) {
        foreach ($cred in $app.PasswordCredentials) {
            if ($cred.EndDateTime -lt (Get-Date)) {
                $expiredSAMLCerts+= [PSCustomObject]@{
                    AppName     = $app.DisplayName
                    AppId       = $app.AppId
                    ObjectId    = $app.Id
                    CertId      = $cred.KeyId 
                    Expires     = $cred.EndDateTime
                }
            } elseif ($cred.EndDateTime -lt $futureDate) {
                $expiringSAMLCerts  += [PSCustomObject]@{
                    AppName     = $app.DisplayName
                    AppId       = $app.AppId
                    ObjectId    = $app.Id
                    CertID      = $cred.KeyId 
                    EndDate     = $cred.EndDateTime
                }
            }
        }
    }
}
# Generate HTML body for the email
$htmlBody = @"
<html>
<head>
<style>
    table { font-family: Arial, sans-serif; border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
    th { background-color: #f2f2f2; }
</style>
</head>
<body>
<h2>Entra ID Application Secrets and certificates</h2>
<h3>Secrets expiring in the Next 30 Days</h3>
<table>
    <tr>
        <th>App Name</th>
        <th>App ID</th>
        <th>Secret ID</th>
        <th>End Date</th>
    </tr>
"@
foreach ($secret in $expiringSecrets) {
    $htmlBody += "<tr>"
    $htmlBody += "<td><b>$($secret.AppName)</b></td>"
    $htmlBody += "<td><b>$($secret.AppId)</b></td>"
    $htmlBody += "<td><b>$($secret.SecretId)</b></td>"
    $htmlBody += "<td><b>$($secret.EndDate)</b></td>"
    $htmlBody += "</tr>"
}
$htmlBody += @"
</table>
<h3>Secret Already Expired</h3>
<table>
    <tr>
        <th>App Name</th>
        <th>App ID</th>
        <th>Secret ID</th>
        <th>End Date</th>
    </tr>
"@
foreach ($secret in $expiredSecrets) {
    $htmlBody += "<tr>"
    $htmlBody += "<td>$($secret.AppName)</td>"
    $htmlBody += "<td>$($secret.AppId)</td>"
    $htmlBody += "<td>$($secret.SecretId)</td>"
    $htmlBody += "<td>$($secret.EndDate)</td>"
    $htmlBody += "</tr>"
}
$htmlBody += @"
</table>
<h3>Cert expiring in the Next 30 Days</h3>
<table>
    <tr>
        <th>App Name</th>
        <th>App ID</th>
        <th>Cert ID</th>
        <th>End Date</th>
    </tr>
"@
foreach ($secret in $expiringCertificates) {
    $htmlBody += "<tr>"
    $htmlBody += "<td><b>$($secret.AppName)</b></td>"
    $htmlBody += "<td><b>$($secret.AppId)</b></td>"
    $htmlBody += "<td><b>$($secret.CertId)</b></td>"
    $htmlBody += "<td><b>$($secret.EndDate)</b></td>"
    $htmlBody += "</tr>"
}
$htmlBody += @"
</table>
<h3>Cert already Expired</h3>
<table>
    <tr>
        <th>App Name</th>
        <th>App ID</th>
        <th>Cert ID</th>
        <th>End Date</th>
    </tr>
"@
foreach ($secret in $expiredCertificates) {
    $htmlBody += "<tr>"
    $htmlBody += "<td>$($secret.AppName)</td>"
    $htmlBody += "<td>$($secret.AppId)</td>"
    $htmlBody += "<td>$($secret.CertId )</td>"
    $htmlBody += "<td>$($secret.EndDate)</td>"
    $htmlBody += "</tr>"
}
$htmlBody += @"
</table>
<br>
<h3>SAML Cert expiring in the Next 30 Days</h3>
<table>
    <tr>
        <th>App Name</th>
        <th>App ID</th>
        <th>Object ID</th>
        <th>Secret ID</th>
        <th>End Date</th>
    </tr>
"@
foreach ($secret in $expiringSAMLCerts) {
    $htmlBody += "<tr>"
    $htmlBody += "<td><b>$($secret.AppName)</b></td>"
    $htmlBody += "<td><b>$($secret.AppId)</b></td>"
    $htmlBody += "<td><b>$($secret.CertID)</b></td>"
    $htmlBody += "<td><b>$($secret.ObjectId)</b></td>"
    $htmlBody += "<td><b>$($secret.EndDate)</b></td>"
    $htmlBody += "</tr>"
}
$htmlBody += @"
</table>
</body>
</html>
"@
$htmlBody += @"
</table>
<br>
<h3>SAML Cert already Expired</h3>
<table>
    <tr>
        <th>App Name</th>
        <th>App ID</th>
        <th>Secret ID</th>
        <th>Object ID</th>
        <th>End Date</th>
    </tr>
"@
foreach ($secret in $expiredSAMLCerts) {
    $htmlBody += "<tr>"
    $htmlBody += "<td>$($secret.AppName)</td>"
    $htmlBody += "<td>$($secret.AppId)</td>"
    $htmlBody += "<td>$($secret.ObjectId)</td>"
    $htmlBody += "<td>$($secret.CertID)</td>"
    $htmlBody += "<td>$($secret.Expires)</td>"
    $htmlBody += "</tr>"
}
$htmlBody += @"
</table>
</body>
</html>
"@

$messageSubject = "Expired Entra ID Application Credentials"
$Password = ConvertTo-SecureString -AsPlainText -Force -String $env:AZURE_SMTP_PASSWORD
$Cred = New-Object -TypeName PSCredential -ArgumentList $env:AZURE_SMTP_USERNAME, $Password

try {
    $smtpTo = @("YOURMAIL@ADDRESS.COM", "TEAMSCHANNEL-ADDRESS.onmicrosoft.com@no.teams.ms") # Add more recipients as needed
    foreach ($recipient in $smtpTo) {
        Send-MailMessage -From 'DoNotReplay <YOURSENDER-ADDRESS>' -To $recipient -Subject $messageSubject -Body $htmlBody -SmtpServer 'smtp.azurecomm.net' -Port 587 -Credential $Cred -UseSsl -BodyAsHtml # I did Use Azure communication services 
    }
    Write-Output "Email sent successfully to: $smtpTo"
} catch {
    Write-Output "Failed to send email. $_"
    Exit 1
}
