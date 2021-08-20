Function Get-HardwareOSInfo{
    <#
    .SYNOPSIS
    Function to pull Hardware & OS info from a machine (prints to console and passes out object with data)
    by Steven Wight
    .DESCRIPTION
    Get-HardwareOSInfo -ComputerName <Hostname> -Domain <domain> (default = POSHYT)
    .EXAMPLE
    Get-HardwareOSInfo Computer01
    .Notes
    You may need to edit the Domain depending on your environment (find $Domain)
    #>
    [CmdletBinding()]
    Param(
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $ComputerName,  
        [Parameter()] [String] [ValidateNotNullOrEmpty()] $Domain = "POSHYT" 
    )

    #Clear Variables encase function has been used before in session (never know!)   
    $Computer = $AdCheck = $PathTest = $CPUInfo = $PhysicalMemory = $computersystem = $NICinfo = $Monitors = $OSinfo = $BIOSinfo = $OSReleaseID = $Hyperthreading = $disk = $MachineInfoObj = $null
    
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
        #Get Machine Info
        
        
        #Grab CPU info
        $CPUInfo = (Get-WmiObject Win32_Processor -ComputerName $Computer.DNSHostname)

        #Grab RAM info
        $PhysicalMemory = Get-WmiObject CIM_PhysicalMemory -ComputerName $Computer.DNSHostname | Measure-Object -Property capacity -Sum | ForEach-Object { [Math]::Round(($_.sum / 1GB), 2) }

        #Grab Computer syste info
        $computersystem = (Get-wmiobject -ComputerName $Computer.DNSHostname win32_computersystem -Property *)

        #Grab NIC Info
        $NICinfo = (Get-WmiObject win32_networkadapterconfiguration -ComputerName $Computer.DNSHostname | Where-Object {$null -ne $_.ipaddress})
                
        #Grab Monitor Info
        $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $Computer.DNSHostname -ErrorAction SilentlyContinue

        #Grab OS info
        $OSinfo = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer.DNSHostname | Select-Object * )

        #Grab BIOS info
        $BIOSinfo = (Get-WmiObject -Class Win32_BIOS -ComputerName $Computer.DNSHostname)

        #Grab OS Release ID
        $OSReleaseID = Invoke-Command -ComputerName $Computer.DNSHostname -scriptblock {(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId}

        #Work out if Hyperthreading is enabled
        $Hyperthreading = ($CPUInfo | measure-object -Property NumberOfLogicalProcessors -sum).Sum -gt $($CPUInfo | measure-object -Property NumberOfCores -sum).Sum

        #Grab info on c: drive (screw other drives...)
        $disk = (Get-WmiObject Win32_LogicalDisk -ComputerName $computer.DNSHostname -Filter "DeviceID='C:'" | Select-Object FreeSpace,Size)

        # build object to use to fill CSV with data and print to screen
        $MachineInfoObj = [pscustomobject][ordered] @{
            ComputerName =  $ComputerName
            Description = $Computer.description
            SerialNo = $BIOSinfo.SerialNumber
            IPaddress = [string]$NICinfo.ipaddress
            Mac = $NICinfo.Macaddress
            Model = $computersystem.Model
            Manufacturer = $computersystem.Manufacturer
            Screens = $Monitors.count
            Domain = $Domain
            OS = $Computer.OperatingSystem
            CPU =  [string]$CPUInfo.Name
            NoOfCPU = $computersystem.NumberOfProcessors
            Hyperthreading = $Hyperthreading
            RAM_GB = $PhysicalMemory
            C_Drive_Size_GB = $disk.Size/1GB
            C_Drive_Free_Space_GB = $disk.FreeSpace/1GB
            Build_day = ([WMI]'').ConvertToDateTime($OSinfo.installDate)
            Build_version = $OSinfo.version
            Build_number = $OSinfo.BuildNumber
            OS_Release = $OSReleaseID
            OS_Architecture = $OSinfo.OSArchitecture
        }
        
        #output info to console
        Write-host "$($MachineInfoObj)"

        #Return Info
        return $MachineInfoObj

    }else{#If machine wasn't online 
        
        #Output machine is online to the console
        Write-host -ForegroundColor Red "$($ComputerName) is offline"

        # build object to use to fill CSV with data and print to screen (Set Variables to "offline")
        $MachineInfoObj = [pscustomobject][ordered] @{
            ComputerName =  $ComputerName
            Description = $Computer.description
            SerialNo = "offline"
            IPaddress = "offline"
            Mac = "offline"
            Model = "offline"
            Manufacturer = "offline"
            Screens = "offline"
            Domain = $Domain
            OS = $Computer.OperatingSystem
            CPU =  "offline"
            NoOfCPU = "offline"
            Hyperthreading = "offline"
            RAM_GB = "offline"
            C_Drive_Size_GB = "offline" 
            C_Drive_Free_Space_GB = "offline" 
            Build_day = "offline"
            Build_version = "offline"
            Build_number = "offline"
            OS_Release = "offline"
            OS_Architecture = "offline"
        }

        #output info to console
        Write-host "$($MachineInfoObj)"

        #Return Info
        return $MachineInfoObj

    }# End of If
}# end of Function
