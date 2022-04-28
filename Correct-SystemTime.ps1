Function Correct-SystemTime{
    <#
    .SYNOPSIS
    Function to correct wrong time and date on remote machines
    by Steven Wight
    .DESCRIPTION
    Correct-SystemTime -ComputerName <Hostname> -Domain <domain> (default = POSHYT)
    .EXAMPLE
    Correct-SystemTime Computer01
    .Notes
    This assumes the correct time and date on the machine it's being run from 
    #>
    [CmdletBinding()]
    Param(
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $ComputerName,  
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $Domain = "POSHYT" 
    )

    #Clear Variables encase function has been used before in session (never know!)   
    $Computer = $AdCheck = $PathTest = $TimeAndDate = $RemoteTimeAndDate = $null
    
   # Get Computer info from AD
   try{
        $Computer = (Get-ADComputer $ComputerName -properties DNSHostname,description,OperatingSystem -server $Domain -ErrorAction stop)
        $AdCheck = $true
    }Catch{
        Write-Host -ForegroundColor Red "Machine $($ComputerName) not found in AD"
        $Computer = $_.Exception.Message
        $AdCheck = $false
    }

    # Check machine is online 
    if($True -eq $AdCheck){   
        $PathTest = Test-Connection -Computername $Computer.DNSHostname -BufferSize 16 -Count 1 -Quiet
    } #End of If ADcheck is True

    #if Machine is online
    if($True -eq $PathTest) {
    
        #Output machine is online to the console
        Write-host -ForegroundColor Green "$($ComputerName) is online"
         
        #Get remote machines Time and date
        $RemoteTimeAndDate = Invoke-Command -ComputerName $Computer.DNSHostname -ScriptBlock { return Get-Date -Format "dddd MM/dd/yyyy HH:mm" }
        
        #get local machines date and time
        $TimeAndDate = Get-date -Format "dddd MM/dd/yyyy HH:mm"
        
        #if time is out
        if($RemoteTimeAndDate -ne $TimeAndDate){
            
            Write-Host ""
            Write-Host -ForegroundColor RED "$($ComputerName) time is out"
            Write-Host -ForegroundColor RED "Remote Time - $($RemoteTimeAndDate)"
            Write-Host -ForegroundColor RED "Remote Time - $($TimeAndDate)"
            Write-Host ""

            $Continue = Read-Host -Prompt 'Do you wish to correct? -  Press Y to continue'

            if ("Y" -eq $Continue.ToUpper()) {
                
                Write-Host ""
                Write-Warning -Message "Correcting time on $($ComputerName)"
                Write-Host ""

                #get local machines date and time
                $TimeAndDate = Get-date 

                #Correct time on remote machine
                $RemoteTimeAndDate = Invoke-Command -ComputerName $Computer.DNSHostname -ScriptBlock {  Set-Date -Date $using:TimeAndDate
                                                                                                        return Get-Date -Format "dddd MM/dd/yyyy HH:mm" }

                #confirm time and date was set correctly
                if($RemoteTimeAndDate -eq $TimeAndDate){
            
                    #output if successful
                    Write-Host ""
                    Write-Host -ForegroundColor Green "$($ComputerName) time was successfully corrected"
                    Write-Host ""

                }else{

                    #output if unsuccessful and what the difference is
                    Write-Host ""
                    Write-Host -ForegroundColor RED "$($ComputerName) issue correcting time"
                    Write-Host -ForegroundColor RED "Remote Time - $($RemoteTimeAndDate)"
                    Write-Host -ForegroundColor RED "Remote Time - $($TimeAndDate)"
                    Write-Host ""

                }
            }
             
        }else{
            
            #output if time is okay
            Write-Host ""
            Write-Host -ForegroundColor Green "$($ComputerName) time is correct"
            Write-Host ""  
        
        }                                                                                               

    }else{#If machine wasn't online 
        
        #Output machine is online to the console
        Write-host -ForegroundColor Red "$($ComputerName) is offline"

    }# End of If
}# end of Function
