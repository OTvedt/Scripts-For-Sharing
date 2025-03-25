.SYNOPSIS
    This script retrieves and displays a list of Azure classic subscription administrators for all eligible Azure subscriptions.
    Based on https://wmatthyssen.com/2024/03/21/list-azure-classic-subscription-administrators-via-the-azure-portal-or-via-an-azure-powershell-script/

.DESCRIPTION
    The script performs the following tasks:
    1. Suppresses Azure PowerShell breaking change warnings.
    2. Retrieves all Azure subscriptions, excluding specific subscription types (e.g., "Microsoft Azure Enterprise", "Visual Studio", "Gratis", and "Tilgang til Azure Active Directory").
    3. Iterates through each subscription to find classic administrators (Service Administrators and Co-Administrators).
    4. Displays the list of classic administrators, if any are found.

.PARAMETERS
    None.

.OUTPUTS
    Displays the list of classic administrators in the console, including:
    - Subscription Name
    - Subscription ID
    - Administrator Sign-In Name

.NOTES
    - Ensure you have the necessary permissions to access Azure subscriptions and retrieve role assignments.
    - The script uses the Azure PowerShell module. Ensure it is installed and updated.
    - The script excludes specific subscription types based on their names.

.EXAMPLE
    Run the script to retrieve and display classic administrators:
    ```powershell
    .\Find-ClassicAdmins.ps1
    ```

    Output:
    ```
    # List of Classic Administrators:
    Subscription: ExampleSubscription - 12345678-1234-1234-1234-123456789abc
    Classic Administrator: admin@example.com
    ```

    If no classic administrators are found:
    ```
    # No classic administrators found in any subscription
