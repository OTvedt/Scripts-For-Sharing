param(
    [int]$Days = 30,
    [string]$OutputDir = $PSScriptRoot
)

# GitHub Copilot

Import-Module Microsoft.Graph.Applications -ErrorAction SilentlyContinue

# Interactive delegated login as user
try {
    Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All" -ErrorAction Stop
} catch {
    Write-Error "Failed to connect to Microsoft Graph. Ensure you have admin consent for the requested scopes."
    throw
}

# Define lists to hold results
$expiredSecrets = New-Object System.Collections.ArrayList
$expiringSecrets = New-Object System.Collections.ArrayList
$allSecrets = New-Object System.Collections.ArrayList

$expiredCertificates = New-Object System.Collections.ArrayList
$expiringCertificates = New-Object System.Collections.ArrayList
$allCertificates = New-Object System.Collections.ArrayList

$expiringSAMLCerts  = New-Object System.Collections.ArrayList
$expiredSAMLCerts = New-Object System.Collections.ArrayList
$allSAMLCerts = New-Object System.Collections.ArrayList  

# Combined list for all info
$allInfo = New-Object System.Collections.ArrayList

# Get all applications (exclude those with the specified owner)
$applications = Get-MgApplication -All | Where-Object {
    -not (Get-MgApplicationOwner -ApplicationId $_.Id | Where-Object Id -eq $excludeOwnerId)
} | Sort-Object DisplayName

# Get all Enterprise Apps (Service Principals)
$SAMLapps = Get-MgServicePrincipal -All | Sort-Object DisplayName # To exclude some apps use this as example | Where-Object { $_.DisplayName -ne "p2p Server" } 

# Dates
$currentDate = Get-Date
$futureDate = $currentDate.AddDays($Days)

foreach ($app in $applications) {
    $passwordCredentials = $app.PasswordCredentials
    foreach ($credential in $passwordCredentials) {
        # Add to the "all" list
        $allSecrets.Add([PSCustomObject]@{
            AppName   = $app.DisplayName
            AppId     = $app.AppId
            ObjectId  = $app.Id
            SecretId  = $credential.KeyId
            StartDate = ($credential.StartDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
            EndDate   = ($credential.EndDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
        }) | Out-Null

        # Determine status
        if ($credential.EndDateTime -lt $currentDate) {
            $status = "Expired"
        } elseif ($credential.EndDateTime -le $futureDate) {
            $status = "Expiring"
        } else {
            $status = "Valid"
        }

        # Add to combined allInfo
        $allInfo.Add([PSCustomObject]@{
            Type      = "Secret"
            Status    = $status
            AppName   = $app.DisplayName
            AppId     = $app.AppId
            ObjectId  = $app.Id
            ItemId    = $credential.KeyId
            StartDate = ($credential.StartDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
            EndDate   = ($credential.EndDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
        }) | Out-Null

        if ($credential.EndDateTime -le $futureDate -and $credential.EndDateTime -gt $currentDate) {
            $expiringSecrets.Add([PSCustomObject]@{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                SecretId  = $credential.KeyId
                EndDate   = ($credential.EndDateTime).ToString("dd.MM.yyyy")
            }) | Out-Null
        } elseif ($credential.EndDateTime -lt $currentDate) {
            $expiredSecrets.Add([PSCustomObject]@{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                SecretId  = $credential.KeyId
                EndDate   = ($credential.EndDateTime).ToString("dd.MM.yyyy")
            }) | Out-Null
        }
    }

    $certificateCredentials = $app.KeyCredentials
    foreach ($cert in $certificateCredentials) {
        # Add to the "all" list
        $allCertificates.Add([PSCustomObject]@{
            AppName   = $app.DisplayName
            AppId     = $app.AppId
            ObjectId  = $app.Id
            CertId    = $cert.KeyId
            StartDate = ($cert.StartDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
            EndDate   = ($cert.EndDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
        }) | Out-Null

        # Determine status
        if ($cert.EndDateTime -lt $currentDate) {
            $status = "Expired"
        } elseif ($cert.EndDateTime -le $futureDate) {
            $status = "Expiring"
        } else {
            $status = "Valid"
        }

        # Add to combined allInfo
        $allInfo.Add([PSCustomObject]@{
            Type      = "ApplicationCertificate"
            Status    = $status
            AppName   = $app.DisplayName
            AppId     = $app.AppId
            ObjectId  = $app.Id
            ItemId    = $cert.KeyId
            StartDate = ($cert.StartDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
            EndDate   = ($cert.EndDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
        }) | Out-Null

        if ($cert.EndDateTime -le $futureDate -and $cert.EndDateTime -gt $currentDate) {
            $expiringCertificates.Add([PSCustomObject]@{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                CertId    = $cert.KeyId
                EndDate   = ($cert.EndDateTime).ToString("dd.MM.yyyy")
            }) | Out-Null
        } elseif ($cert.EndDateTime -lt $currentDate) {
            $expiredCertificates.Add([PSCustomObject]@{
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                CertId    = $cert.KeyId
                EndDate   = ($cert.EndDateTime).ToString("dd.MM.yyyy")
            }) | Out-Null
        }
    }
}

foreach ($app in $SAMLapps ) {
    if ($app.PasswordCredentials -and $app.PasswordCredentials.Count -gt 0) {
        foreach ($cred in $app.PasswordCredentials) {
            # Add to the "all" SAML list
            $allSAMLCerts.Add([PSCustomObject]@{
                AppName     = $app.DisplayName
                AppId       = $app.AppId
                ObjectId    = $app.Id
                CertId      = $cred.KeyId 
                StartDate   = ($cred.StartDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
                EndDate     = ($cred.EndDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
            }) | Out-Null

            # Determine status
            if ($cred.EndDateTime -lt $currentDate) {
                $status = "Expired"
            } elseif ($cred.EndDateTime -le $futureDate) {
                $status = "Expiring"
            } else {
                $status = "Valid"
            }

            # Add to combined allInfo
            $allInfo.Add([PSCustomObject]@{
                Type      = "ServicePrincipalSecret"
                Status    = $status
                AppName   = $app.DisplayName
                AppId     = $app.AppId
                ObjectId  = $app.Id
                ItemId    = $cred.KeyId
                StartDate = ($cred.StartDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
                EndDate   = ($cred.EndDateTime).ToString("yyyy-MM-ddTHH:mm:ss")
            }) | Out-Null

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

# Ensure output directory exists
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

$expiringSecrets | Export-Csv -Path (Join-Path $OutputDir "ExpiringSecrets.csv") -NoTypeInformation -Encoding UTF8
$expiredSecrets | Export-Csv -Path (Join-Path $OutputDir "ExpiredSecrets.csv") -NoTypeInformation -Encoding UTF8
$allSecrets | Export-Csv -Path (Join-Path $OutputDir "AllSecrets.csv") -NoTypeInformation -Encoding UTF8

$expiringCertificates | Export-Csv -Path (Join-Path $OutputDir "ExpiringCertificates.csv") -NoTypeInformation -Encoding UTF8
$expiredCertificates | Export-Csv -Path (Join-Path $OutputDir "ExpiredCertificates.csv") -NoTypeInformation -Encoding UTF8
$allCertificates | Export-Csv -Path (Join-Path $OutputDir "AllCertificates.csv") -NoTypeInformation -Encoding UTF8

$expiringSAMLCerts | Export-Csv -Path (Join-Path $OutputDir "ExpiringSAMLCerts.csv") -NoTypeInformation -Encoding UTF8
$expiredSAMLCerts | Export-Csv -Path (Join-Path $OutputDir "ExpiredSAMLCerts.csv") -NoTypeInformation -Encoding UTF8
$allSAMLCerts | Export-Csv -Path (Join-Path $OutputDir "AllSAMLCerts.csv") -NoTypeInformation -Encoding UTF8

# Export combined all info
$allInfo | Export-Csv -Path (Join-Path $OutputDir "AllInfo.csv") -NoTypeInformation -Encoding UTF8

Write-Output "CSV files created in: $OutputDir"
