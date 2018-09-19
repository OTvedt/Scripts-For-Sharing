Param
(
    [string]$Source,
    [string]$LogFile
)
function Get-TextFromInputBox
{
    Param
    (
        [ValidateNotNullOrEmpty()]
        [string]$Message = 'Enter source path',
        [ValidateNotNullOrEmpty()]
        [string]$Title = 'Source',
        [string]$Default = ''
    )
    # Add Visual Basic Assembly
    Add-Type -AssemblyName Microsoft.VisualBasic;
    [Microsoft.VisualBasic.Interaction]::InputBox($Message, $Title, $Default);
};
function Get-AnswerFromMsgBox
{
    Param
    (
        [ValidateNotNullOrEmpty()]
        [string]$Message = 'Do you want to log to a file?',
        [ValidateNotNullOrEmpty()]
        [string]$Title = 'Migrate data',
        [int]$MsgBoxStyle = 36
    )
    # Add Visual Basic Assembly
    Add-Type -AssemblyName Microsoft.VisualBasic;
    # https://docs.microsoft.com/en-us/dotnet/api/microsoft.visualbasic.msgboxstyle
    [Microsoft.VisualBasic.Interaction]::MsgBox($Message, $MsgBoxStyle, $Title);
};
try
{
    # If source was not specified
    if(-not($Source))
    {
        # Get current location
        $location = Get-Location;
        # Ask user for a source path
        $Source = Get-TextFromInputBox -Default $location.Path;
        # Abort if user canceled
        if(-not($Source)){return;};
    };
    $pathExist = $false;
    # Do while source is not valid and we have value in Source
    do
    {
        if($Source)
        {
            # Check that path exist
            $pathExist = Test-Path -Path $Source -PathType Container;
            if(-not($pathExist))
            {
                # If path do not exist, ask for new path
                $Source = Get-TextFromInputBox -Message "Unable to find $Source, enter a valid path" -Default $Source;
            };
        };
    } while (-not($pathExist) -and $Source);
    # If no source specified, abort script
    if(-not($Source)){return;};
    # Get OneDrive Accounts from Windows Registry
    $accounts = Get-ChildItem -Path 'HKCU:Software\Microsoft\OneDrive\Accounts';
    # Find only OneDrive for Business folders
    $destination = foreach($account in $accounts){if($account.PSChildName -ne 'Personal'){$account.GetValue('UserFolder')}};
    # If we did find more than one folder
    if($destination -and $destination -is [array] -and $destination.Count -gt 1)
    {
        $msg = 'More than one OneDrive for Business folder was detected: ' + ($destination -join ', ') + "`n`nEnter destination path:";
        # Ask user for a destination path
        $destination = Get-TextFromInputBox -Message $msg -Title 'Destination' -Default $destination[0];
        # Abort if user canceled
        if(-not($destination)){return;};
    };
    $pathExist = $false;
    # Do while destination is not valid and we have value in destination
    do
    {
        if($destination)
        {
            # Check that path exist
            $pathExist = Test-Path -Path $destination -PathType Container;
            if(-not($pathExist))
            {
                # If path do not exist, ask for new path
                $destination = Get-TextFromInputBox -Message "Unable to find $destination, enter a valid path" -Title 'Destination' -Default $destination;
            };
        };
    } while (-not($pathExist) -and $destination);
    # If no destination specified, abort script
    if(-not($destination)){return;};
    # Get items in source (folders and files)
    $dirItems = Get-ChildItem -Path $Source;
    # If we have items in source
    if($dirItems.Count -ne 0)
    {
        # Ask user if migrate should start
        $answer = Get-AnswerFromMsgBox -Message "Do you want to migrate data from $($Source) to $($destination)?";
        if($answer -eq [Microsoft.VisualBasic.MsgBoxResult]::Yes)
        {
            # If a logfile was not specified
            if(-not($LogFile))
            {
                $answer = Get-AnswerFromMsgBox -Message 'Do you want to log to a file?';
                if($answer -eq [Microsoft.VisualBasic.MsgBoxResult]::Yes)
                {
                    $LogFile = Get-TextFromInputBox -Message 'Specify Log File, including file name' -Title 'Log File' -Default "$env:TEMP\o4b_migration.log";
                };
            };
            $answer = Get-AnswerFromMsgBox -Message 'Do you want to exclude WINDOWS folder(s)?';
            $excludeWindows = if($answer -eq [Microsoft.VisualBasic.MsgBoxResult]::Yes){$true} else {$false};
            # Using robocopy to move files and subfolders. Retain security.
            # Set retries to 0 and time to wait between retries to 0.
            # Do not log file names and directory name.
            # Exclude WINDOWS directory (Omitt /xd 'WINDOWS' in the case of failure).
            if($LogFile)
            {
                if($excludeWindows)
                {
                    robocopy $Source $destination /e /move /sec /r:0 /w:0 /unilog:$LogFile /xd 'WINDOWS';
                } else
                {
                    robocopy $Source $destination /e /move /sec /r:0 /w:0 /unilog:$LogFile;
                };
            } else
            {
                if($excludeWindows)
                {
                    robocopy $Source $destination /e /move /sec /r:0 /w:0 /xd 'WINDOWS';
                } else
                {
                    robocopy $Source $destination /e /move /sec /r:0 /w:0;
                };
            };
        };
    };
} catch
{
    "Failure: $($_.Exception.Message)";
};
