function Disable-Service {
    <#
    .SYNOPSIS
    Function to stop and disable service
    by Steven Wight
    .DESCRIPTION
    Disable-Service -Hostnames <Computername>, SVC <Service Name> -Domain <Domain> Default = POSHYT
    .EXAMPLE
    Disable-Service  Computer0057P Spooler, Get-content c:\temp\hostnames.csv (or.txt) | Disable-service Spooler
    .NOTES
    run against one machine = Disable-Service  Computer0057P Spooler or a list = Get-content c:\temp\hostnames.csv (or.txt) | Disable-Service Spooler
    #>
    [cmdletbinding()]
        param(
            [Parameter(mandatory=$true , ValueFromPipeline=$true)]
            [string[]] $Hostnames,
            [Parameter()] [String] [ValidateNotNullOrEmpty()] $SVC, 
            [Parameter()] [String] [ValidateNotNullOrEmpty()] $Domain = "POSHYT"
            )

    process{           

        #check hostname (or if list is piped) 
        foreach($hostname in $hostnames){
            $computer = Get-ADComputer -Identity $Hostname -server $Domain

            #stop and disable service
            invoke-command -computerName $computer.dnshostname -scriptblock { 
                Stop-Service -Name $using:SVC
                Start-Sleep 5 
                Set-Service -Name $using:SVC -StartupType Disabled
                Get-Service -Name $using:SVC
            }# End of Scriptblock 

        } #end of foreach
    } #end of process    
} #end of function
