   Function Add-UserToLocalGroups {
   <#
    .SYNOPSIS
    Function to add an account to the local Admin and remote access groups
    by Steven Wight
    .DESCRIPTION
    Add-UserToLocalGroups -Hostname <Computername, -User <Domain/username> Default = can be set -Domain <Domain> Default = can be set
    .EXAMPLE
    Add-UserToLocalGroups Computer0454S
    .NOTES
    Defaults can be added in the parameters part, I made this as sometimes I have to use RDP instead of citrix or my Test account needs local Admins for some testing/ etc..
    Our GP will nuke them when it refreshes so is just for temp work and I don't need to worry about removing them (usually bounce box when finished)
    #>
    [CmdletBinding()]
    Param( [Parameter(Mandatory=$true)] [string] $Hostname, 
    [Parameter()] [String] $user = "POSHYT\Steven.Wight", 
    [Parameter()] [String] $Domain = "POSHYT" )

    #Clear variables
    $DNSHostName = $null

    #Check machine is in AD and pull out the FQDN or DNShostname for it
    $DNSHostName = (Get-ADComputer $Hostname -Server $Domain) 

    #invoke command to add the account into the local group
    Invoke-Command -ComputerName $DNSHostName.DNSHostName -ScriptBlock {

        # Add Account to local Administrators local Group
        Add-LocalGroupMember -Group "Administrators" -Member $Using:user

        # Add Account to Direct Access Users local Group
        Add-LocalGroupMember -Group "Direct Access Users" -Member $Using:user

        # Add Account to Remote Desktop Users local Group
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $Using:user
    }#End of Scriptblock
    
    }#end of Function
