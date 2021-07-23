$Domain = "POSHYT"
$WorkStations = (Get-ADComputer  -server $Domain | Select Name)

$processName = "Notepad"


# Import AD module
Import-Module ActiveDirectory

# Input output files names and paths
$Outfile = "c:\temp\posh_outputs\$($processName)__Workstation_ProcessCheck_$(get-date -f yyyy-MM-dd-HH-mm)_Log.csv"
$ErrorLog = "c:\temp\posh_outputs\$($processName)_Workstation_ProcessCheck_$(get-date -f yyyy-MM-dd-HH-mm)_Errorlog.log"

#initialise error counter 
$ErrorCount=0

#initialise Progress counter 
$i=0

#get number of machines to check
$ComputersCount = $WorkStations.count

$WorkStations | foreach-object {

#clear variables
$Computer = $hostname = $PathTest = $results = $result = $null

# copy input into variables
$hostname = $_.Name


$i++ # main loop progress counter
$percentageComplete = (($i / $ComputersCount) * 100)
$percentageComplete = [math]::Round($percentageComplete,1)

Write-Host -ForegroundColor Cyan "Querying Computer - $($hostname): $i of $($computerscount) - Percent complete $($percentageComplete) %"
Write-host -ForegroundColor yellow "Testing if $hostname is in AD and online"


    #Find machine in AD
    try{
    $Computer = Get-ADComputer $hostname -server $Domain
    Write-host -ForegroundColor Green "Found $($hostname) in AD"  
    }catch{
    #increase error counter if something not right
    $ErrorCount += 1
    #print error message
    $ErrorMessage = $_.Exception.Message
    "Can't find $($hostname) in AD because $($ErrorMessage)" | Out-File $ErrorLog -Force -Append
    Write-host -ForegroundColor RED "Can't find $($hostname) in AD because $($ErrorMessage)"
    }  

    #If machine in AD, Check if online
    If($null -ne $computer){
        try{
        $PathTest = Test-Connection -Computername $Computer.DNShostname -BufferSize 16 -Count 1 -Quiet
        }catch{
        #increase error counter if something not right
        $ErrorCount += 1
        #print error message
        $ErrorMessage = $_.Exception.Message
        "Wasn't able to test if $($Computer.DNShostname) was online because $($ErrorMessage)" | Out-File $ErrorLog -Force -Append
        Write-host -ForegroundColor RED "Wasn't able to test if $($Computer.DNShostname) was online because $($ErrorMessage)"
        } 

        #If Machine online, check for reg entry
        if($PathTest -eq $True){
           Write-host -ForegroundColor Green "Found $($hostname) online" 
            try{
                $results =  Invoke-Command -ComputerName $Computer.DNShostname -erroraction stop -ScriptBlock{
                    $Process = (Get-process -Name $using:Processname -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path)
                    if($null -ne $Process){
                        write-host -ForegroundColor Green  "Process found on $($using:Computer.name)"
                    }Else{
                        write-host -ForegroundColor Yellow  "Process not found $($using:Computer.name)"
                        $Process  = "Process not found"
                        }
                    Return $Process 
                } # end of Invokecommand
                Foreach($result in $Results){
                [pscustomobject][ordered] @{
                    Process = $result 
                    Computer = $COMPUTER.name
                    } | Export-csv -Path $outfile -NoTypeInformation  -Append -Force}
            }catch{
            #increase error counter if something not right
            $ErrorCount += 1
            #print error message
            $ErrorMessage = $_.Exception.Message
            "Wasn't able to run check on $($Computer.DNShostname) because $($ErrorMessage)" | Out-File $ErrorLog -Force -Append
            Write-host -ForegroundColor RED "Wasn't able to run check on $($Computer.DNShostname) because $($ErrorMessage)"
            [pscustomobject][ordered] @{
                Process = "Unable to check, see error log" 
                Computer = $COMPUTER.name
                } | Export-csv -Path $outfile -NoTypeInformation  -Append -Force
            } 
        }else{#end of if Machine Online
            Write-host -ForegroundColor Red "$($hostname) offline" 
            [pscustomobject][ordered] @{
                Process = "offline"  
                Computer = $COMPUTER.name
                } | Export-csv -Path $outfile -NoTypeInformation  -Append -Force
        }
    }else{ #End of if machine in AD
        [pscustomobject][ordered] @{
            Process = "Not in AD"  
            Computer = $hostname
            } | Export-csv -Path $outfile -NoTypeInformation  -Append -Force
    }  

} # End of main Foreach-object loop

If ($ErrorCount -ge1) {

    Write-host "-----------------"
    Write-Host -ForegroundColor Red "The script execution completed, but with errors. See $($ErrorLog)"
    Write-host "-----------------"
    Pause
}Else{
    Write-host "-----------------"
    Write-Host -ForegroundColor Green "Script execution completed without error."
    Write-host "-----------------"
    Pause
}
