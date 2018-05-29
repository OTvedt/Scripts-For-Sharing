if($PSVersionTable.PSVersion.Major -ge 5)
{
    $regAccounts=Get-ChildItem -Path Registry::HKEY_CURRENT_USER\Software\Microsoft\OneDrive\Accounts\;
    if(-not($regAccounts)){'Unable to find OneDrive on this Computer'};
    $hasBusiness=$false;
    $junctions=foreach($acc in $regAccounts)
    {
        if($acc.GetValue('Business'))
        {
            $Path=$acc.GetValue('UserFolder');
            if($Path)
            {
                $foldername=Split-Path -Path $Path -Leaf;
                if(-not(Test-Path -Path "C:\$foldername" -PathType Container))
                {
                    New-Item -ItemType Junction -Path "C:\$foldername" -Value $Path;
                } else {
                    Get-Item -Path "C:\$foldername"
                };
                $hasBusiness=$true;
            };
        };
    };
    if(-not($hasBusiness)){'Unable to find OneDrive for Business on this Computer'};
    $junctions | Select-Object FullName,Target;
} else {'PowerShell v5 or higher required'};
