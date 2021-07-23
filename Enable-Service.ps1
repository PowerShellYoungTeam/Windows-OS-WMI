function Enable-Service {
    <#
    .SYNOPSIS
    Function to start and and set to auto service
    by Steven Wight
    .DESCRIPTION
    Enable-Service -Hostnames <Computername>, SVC <Service Name> -Domain <Domain> Default = POSHYT
    .EXAMPLE
    Enable-Service  Computer0454S Spooler, Get-content c:\temp\hostnames.csv (or.txt) | Enable-Service Spooler
    .NOTES
    run against one machine = Enable-Service  Computer0454S Spooler or a list = Get-content c:\temp\hostnames.csv (or.txt) | Enable-Service Spooler
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

            #Set to Auto and start service
            invoke-command -computerName $computer.dnshostname -scriptblock { 
                Set-Service -Name $using:SVC -StartupType Automatic
                Start-Service -Name $using:SVC
                Start-Sleep 5 
                Get-Service -Name $using:SVC
            }# end of scriptblock 

        } #end of foreach
    } #end of process    
} #end of function
