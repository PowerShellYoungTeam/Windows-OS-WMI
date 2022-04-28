# Windows-OS-WMI
Scripts for generally working with windows boxes, usually WinPoSh 5.1


## Add-UserToLocalGroups

### SYNOPSIS
    Function to add an account to the local Admin and remote access groups
    by Steven Wight
### DESCRIPTION
    Add-UserToLocalGroups -Hostname <Computername, -User <Domain/username> Default = can be set -Domain <Domain> Default = can be set
### EXAMPLE
    Add-UserToLocalGroups Computer0454S
### NOTES
    Defaults can be added in the parameters part, I made this as sometimes I have to use RDP instead of citrix or my Test account needs local Admins for some testing/ etc..
    Our GP will nuke them when it refreshes so is just for temp work and I don't need to worry about removing them (usually bounce box when finished)

## Enable-Service 

### SYNOPSIS
    Function to start and and set to auto service
    by Steven Wight
### DESCRIPTION
    Enable-Service -Hostnames <Computername>, SVC <Service Name> -Domain <Domain> Default = POSHYT
### EXAMPLE
    Enable-Service  Computer0454S Spooler, Get-content c:\temp\hostnames.csv (or.txt) | Enable-Service Spooler
### NOTES
    run against one machine = Enable-Service  Computer0454S Spooler or a list = Get-content c:\temp\hostnames.csv (or.txt) | Enable-Service Spooler

# Disable-Service

### SYNOPSIS
    Function to stop and disable service
    by Steven Wight
### DESCRIPTION
    Disable-Service -Hostnames <Computername>, SVC <Service Name> -Domain <Domain> Default = POSHYT
### EXAMPLE
    Disable-Service  Computer0057P Spooler, Get-content c:\temp\hostnames.csv (or.txt) | Disable-service Spooler
### NOTES
    run against one machine = Disable-Service  Computer0057P Spooler or a list = Get-content c:\temp\hostnames.csv (or.txt) | Disable-Service Spooler
    
# Get-HardwareOSInfo

### SYNOPSIS
    Function to pull Hardware & OS info from a machine (prints to console and passes out object with data)
    by Steven Wight
### DESCRIPTION
    Get-HardwareOSInfo -ComputerName <Hostname> -Domain <domain> (default = POSHYT)
### EXAMPLE
    Get-HardwareOSInfo Computer01
### NOTES
    You may need to edit the Domain depending on your environment (find $Domain)

# Correct-SystemTime

### SYNOPSIS
    Function to correct wrong time and date on remote machines
    by Steven Wight
### DESCRIPTION
    Correct-SystemTime -ComputerName <Hostname> -Domain <domain> (default = POSHYT)
### EXAMPLE
    Correct-SystemTime Computer01
### NOTES
    This assumes the correct time and date on the machine it's being run from

## Find-ProcessOnMachines

  Still to turn this into a function, at the moment, make sure the first line is pointing at the required domain you want to fire it against, put the name of the process you want to find in $processName, make sure $Outfile and $ErrorLog are pointing at a valid location and run, It will extract all the machines on the domain and run through them, wrote this as we had a bespoke app that "mostly" lives on a filesshare, it has a start up script the users fire and it read a config file and then starts going. sometimes this start script hangs and locks out the config file and this is the way to find the offending machine without having to pester the Server team.
  
## Kill-UnstableAtomStartupScript

Okay this is the above as a function, However is been aimed at one app called UnstableAtom. It will search a list of hostnames , if it finds the process on the machine it pulls details of machine and logged in user, it will also prompt you to kill the process, it will kill and check, if the issue still persists (the application can't be launched becuase a stalled process is locking out the startup script on the file/app share) for usage, you needs RSAT installed on machine as it uses AD module. To edit, look for parameters around line 307, also get logged in user details ( 207: Get-LoggedonUsersDetails) extracts a username and domain via spliting a string, you may need to play with that (also check fiedls from AD I pull out), for help file, get-help Kill-UnStableAtomStartupScript -full
