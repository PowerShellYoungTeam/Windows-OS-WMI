#############################################################################
#
# Kill-UnstableAtomStartupScript
#
# by Steven Wight 30/12/2021
#
#############################################################################

####################################
# Functions
####################################

function ErrorCountCheck{ # Remind me if something went wrong encase I come back with cup of tea and error has moved off console...

    If ($ErrorCount -ge 1) { #Notify if there has been errors (will be apparent if there was tho)

        Write-host ""
        Write-host -ForegroundColor Red "####################################################"
        Write-Host -ForegroundColor Red "# The script execution completed, but with errors. #"
        Write-host -ForegroundColor Red "####################################################"
        Write-host ""

        Pause

    }Else{

        Write-host ""
        Write-host -ForegroundColor Green "#############################################"
        Write-Host -ForegroundColor Green "# Script execution completed without error. #"
        Write-host -ForegroundColor Green "#############################################"
        Write-host ""

        Pause

    } # End of If .. Else

} #End of Function - ErrorCountCheck

function IAonError{ # if a try/catch goes man down s**tpants

    Write-host -ForegroundColor Red "#########"
    Write-host -ForegroundColor Red "# ERROR #"
    Write-host -ForegroundColor Red "#########"
    Write-host ""
    Write-host -ForegroundColor Red "Computer: $($hostname)"
    Write-host ""

    #Increment the error counter
    $ErrorCount += 1

    #print error message and save error in variable (Encase we want to output to error log etc...)
    $ErrorMessage = $_.Exception.Message
    Write-host -ForegroundColor Red $ErrorMessage

    #Put entry in Error log
    $hostname + $ErrorMessage | Out-File $ErrorLog -Append

} #End of Function - IAonError

function IAonProcessFound{ # If we find the process on a machine

    #Display Infomation
    Write-Host ""
    Write-host -ForegroundColor Yellow "##################"
    Write-host -ForegroundColor Yellow "# PROCESS FOUND  #"
    Write-host -ForegroundColor Yellow "##################"
    Write-host ""
    Write-host -ForegroundColor Yellow "Computer: $($hostname)"
    Write-host ""
    Get-LoggedonUsersDetails
    Write-host ""
    $ProcessCheck
    Write-host ""


    #Prompt User if they want to kill process (or let user/support deal with it)
    $Continue = Read-Host -Prompt "Do you want to kill $($processName) on $($hostname) - Press Y/N"
    
    if ("Y" -EQ $Continue.ToUpper()) {

        #Confirm that the process is to be killed
        Write-Host ""
        Write-Warning -Message "######## IMPORTANT #########"
        Write-Host ""
        $Confirm = Read-Host -Prompt "Are you sure you want to kill the process? - Press Y/N"

        if ("Y" -EQ $Confirm.ToUpper()){
        
            #Kill Process
            Kill-Process
                        
            if($false -eq (Find-Process)){ #Check if Process is gone

                # Confirm Process is gone in console
                Write-Host ""
                Write-host -ForegroundColor Green "################################"
                Write-host -ForegroundColor Green "#  CONFIRMED: PROCESS KILLED   #"
                Write-host -ForegroundColor Green "################################"
                Write-Host ""

            }Else{

                # Confirm Process is gone in console
                Write-Host ""
                Write-host -ForegroundColor Green "################################"
                Write-host -ForegroundColor Green "# ERROR: PROCESS STILL RUNNING #"
                Write-host -ForegroundColor Green "################################"
                Write-Host ""

            }#End of If Else

        } # End of IF (user input)
        
    }  # End of IF (user input)

    #If killing the process didn't help, continue, else exit the script
    Write-host ""
    Write-Warning -Message "######## IMPORTANT #########"
    Write-Host ""
    $Continue = Read-Host -Prompt "If this didn't resolve the issue and you want to keep searching - Press Y"

    if ("Y" -NE $Continue.ToUpper()) {
        Write-Warning -Message "Exiting Script."
        Exit
    } # End of IF (user input)

} #End of Function - IAonProcessFound

function Get-LoggedonUsersDetails{ #Grab the logged on users AD details and pass data back in custom object

    #Get logged in user and extract their AD Object to identify them
    Try{

        #Get logged on user (and some other deets)
        $MachineInfo = (Get-CimInstance –ComputerName $Computer.DNShostname –ClassName Win32_ComputerSystem -ErrorAction stop)

        #Extract Domain from Username field
        $UserDomain = ($MachineInfo.UserName -split "\\" )[0]
        $DomainLength = $UserDomain.Length
        #$UserDomain = $UserDomain.substring($domainlength -5) 

        #Extract Username from Username field
        $username = ($MachineInfo.UserName -split "\\" )[1]
        $username = $username.substring(0,8)

        #Extract Users AD Object and deets
        $UserInfo = get-aduser $Username -properties * -server $UserDomain  -ErrorAction stop

        #Create Object with Information
        $LoggedOnUser = [pscustomobject][ordered] @{
            Computer = $MachineInfo.Name
            Model = $MachineInfo.Model
            LoggedonUsername = $UserInfo.Name
            DisplayName = $UserInfo.Displayname
            Email = $UserInfo.Emailaddress
            Company = $UserInfo.Company
            Division = $UserInfo.Division
            Department = $UserInfo.Department
            Title = $UserInfo.Title
        }

        #Output to the Console
        $LoggedOnUser | Format-List

        #Add to Log file (Easier doing here than elsewhere)

        $LoggedOnUser | Export-csv $OutputFile -NoTypeInformation -Append

    }Catch{#If something goes wrong

        IAonError

    }

} #End of Function - Get-LoggedonUsersDetails

function Reset-Variables { # Reset variables on re-run of main loop

$Computer = $ProcessCheck = $LoggedOnUser = $Process = $UserInfo = $MachineOnline = $MachineInfo = $DomainLength = $username = $UserDomain = $ProcessCheck = $null

} #End of Function

function Find-Process { #Find Process on machine

    Try{ # Try find process on machine

        # search for Process via invoked command and store returned result in $ProcessCheck
        $ProcessCheck =  Invoke-Command -ComputerName $Computer.DNShostname -erroraction stop -ScriptBlock{

            #Search for process and get details in $Process to send back
            $Process = (Get-process -Name $using:Processname -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path)

            if($null -ne $Process){ # If a Process was found...

                #Output to console Process has been found (process details already in $Process)
                Write-Host ""
                write-host -ForegroundColor Green  "Process found on $($using:Computer.name)"
                Write-Host ""

            }Else{# if it's all clear...

                #Output to console Process has not been found
                Write-Host ""
                write-host -ForegroundColor Yellow  "Process not found on $($using:Computer.name)"
                Write-Host ""

                #Set Variable to a flag
                $Process  = $false 

            }#end of if .. else

            #Pass back $Process
            Return $Process

        } # end of Invokecommand

        #Pass back $ProcessCheck
        Return $ProcessCheck


    }catch{

        #usual error handling
        IAonError

    }# end of try..catch

} #End of Function - Find-Process

function Kill-Process {

    #Output to console saying Process is being killed
    Write-Host ""
    Write-Warning -Message "######## Killing Process #########"
    Write-Host ""

    Try{ # Try Kill process on machine

        # search for Process via invoked command and store returned result in $ProcessCheck
        Invoke-Command -ComputerName $Computer.DNShostname -erroraction stop -ScriptBlock{

            #Search for process and get details in $Process to send back
            Get-process -Name $using:Processname -ErrorAction SilentlyContinue | Stop-process -force 

        } # end of Invokecommand

    }catch{

        #usual error handling
        IAonError

    }# end of try..catch

} #End of Function - Kill-Process

function Test-MachineOnline{ #Check machine is in AD, Online and WinRM ports are open

Try{

    # Get AD Computer Object
    $global:Computer = (Get-ADComputer $hostname -server $Domain -ErrorAction Stop)

    #Update Console
    Write-Host ""
    Write-host -ForegroundColor Green "Found $($hostname) in AD"
    Write-Host ""

    #Check if machine is online
    $MachineOnline = (Test-NetConnection $Computer.DNSHostName -CommonTCPPort WinRM).TcpTestSucceeded

    #Return Online test result
    Return $MachineOnline

}catch{

    IAonError

}

} #End of Function - Test-MachineOnline

######################################################
# Main Function & Initialising Variables etc..
######################################################

function Kill-UnstableAtomStartupScript {

    <#
    .SYNOPSIS
    Function to Search and kill UnstableAtomStartupScript.bat
    by Steven Wight
    .DESCRIPTION
    Kill-UnstableAtomStartupScript -ProcessName <ProcessName> Default = "UnstableAtomStartupScript"
    -inputfile <PathandFileName.csv> Default = "E:\PowerShell\UnstableAtom_Tools\Input\UnstableAtomMachines.csv"
    -OutputFile <PathandFileName.csv> Default = "E:\PowerShell\UnstableAtom_Tools\Output\$($processName)__Workstation_ProcessCheck_$(get-date -f yyyy-MM-dd-HH-mm)_Log.csv"
    -ErrorLog <PathandFileName.csv> Default = "E:\PowerShell\UnstableAtom_Tools\Output\$($processName)_Workstation_ProcessCheck_$(get-date -f yyyy-MM-dd-HH-mm)_Errorlog.log"
    -Domain <Domain> Default = "POSHYT"
    .EXAMPLE
    Kill-IONStartupScript
    .NOTES
    Will Search through machines in Inputfile, best put Rates and other likely suspects at the top of the file, It will do them first
    #>

    [cmdletbinding()]
    param ( 
        [Parameter()] [String] [ValidateNotNullOrEmpty()] [string]$ProcessName = "UnstableAtomStartupScript",
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $InputFile = "E:\PowerShell\UnstableAtom_Tools\Input\UnstableAtomMachines.csv",
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $OutputFile = "E:\PowerShell\UnstableAtom_Tools\Output\$($processName)__Workstation_ProcessCheck_$(get-date -f yyyy-MM-dd-HH-mm)_Log.csv",
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $ErrorLog = "E:\PowerShell\UnstableAtom_Tools\Output\$($processName)_Workstation_ProcessCheck_$(get-date -f yyyy-MM-dd-HH-mm)_Errorlog.log",
        [Parameter()] [String] [ValidateNotNullOrEmpty()] [string]$Domain = "POSHYT"
    )

    ####################################
    # Set Variables
    ####################################

    #initialise error counter 
    $ErrorCount=0

    #initialise Progress counter 
    $i=0

    #initialise Percentage counter 
    $PercentComplete =0

    #get number of machines to check
    $ComputersCount = (Import-Csv -Path $InputFile -Header Computer).count

    ####################################
    # Display Splash Screen
    ####################################

    Write-Host ""
    Write-host -ForegroundColor Yellow "################################"
    Write-host -ForegroundColor Yellow "#                              #"
    Write-host -ForegroundColor Yellow "#Kill-UnstableAtomStartupScript#"
    Write-host -ForegroundColor Yellow "#                              #"
    Write-host -ForegroundColor Yellow "# by Steven Wight 30/12/2021   #"
    Write-host -ForegroundColor Yellow "#                              #"
    Write-host -ForegroundColor Yellow "################################"
    Write-Host ""

    Write-Host ""
    Write-host -ForegroundColor Yellow "################################"
    Write-host -ForegroundColor Yellow "#        STARTING SEARCH       #"
    Write-host -ForegroundColor Yellow "################################"
    Write-Host ""


    ####################################
    # Main Loop
    ####################################

    Import-Csv -Path $InputFile -Header Computer | foreach-object { # Loop through the machines and check for the process
        
        #Reset Variables on new pass
        Reset-Variables

        #Put hostname into variable
        $hostname = $_.Computer

        #Update Progress Counter, calculate percentage and round to 2 decimal places
        $i++
        $PercentComplete = (($i / $ComputersCount) * 100)
        $PercentComplete = [math]::Round($PercentComplete,2)

        # display in bar and console (encase proress set not to show)
        Write-Progress -Activity 'Searching for Process' -Status 'Progress->' -CurrentOperation $hostname -PercentComplete $PercentComplete
        Write-Host ""
        Write-Host -ForegroundColor Yellow "COMPUTER: $($Hostname) - No: $($i) of $($ComputersCount) - $($PercentComplete) %" 
        Write-Host ""

        #Test if machines is online
        If($true -eq (Test-MachineOnline)){

             Write-Host ""
             Write-host -ForegroundColor Green "WINRM TCP test was Successful"
             Write-Host ""

            #if Process is found on machine
            if($false -ne (Find-Process)){

                #Immediate Actions on Process Discovery
                IAonProcessFound

            }#End of IF

        }#End of If..

    }
    
    ####################################
    # End Of Main Loop
    ####################################

#Check and highlight any errors at end of run

ErrorCountCheck

}# End of Function
