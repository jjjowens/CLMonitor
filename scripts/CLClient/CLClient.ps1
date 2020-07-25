# ------------------------------------------------------------------------------------------------------------------
# Script      : CLClientr.ps1
# Author      : James Owens                                      
# Date        : 23-July-2020                                     
# Version     : V 0.1beta                                            
# Run         : Windows Task Scheduler, on Logon event using command 
#             : PowerShell -noprofile -executionpolicy bypass -file "x:\path\to\script\CLClient.ps1"
# ------------------------------------------------------------------------------------------------------------------
# Description: PowerShell script created to display a message to user. Messages are received through a 
#   file shared with CLMonitor process and is used to inform user of conditions and events related to
#   allowed computer usage.
#
#   After message is read and displayed to user, the message will be removed from 
#   inter process file.
#
#   Variables:
#
#      $displayTime time in seconds message will apppear to user
#
#   Script will pool for messages every 30 seconds. This means there could be up to 60 seconds
#   delay between the time CLMonitor writes the message and the time it displays to user.
#   The only mean for CLClient to communicate with CLMonitor is by erasing message file's
#   content. This will indicate to CLMonitor the message was displayed to user.
#  
#   CLClient will run on the client space and can possibly be terminated by the user.
#   This will only prevent the user from seeing the messages. The managing functions 
#   in CLMonitor will continue to operate.
#     
# ------------------------------------------------------------------------------------------------------------------

#Define runtime environment
$Error.Clear()  


# Hiding Console Window

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
Function Hide-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
}
Hide-Console



# ------------------------------------------------------------------------------------------------------------------
# USER DEFINED PARAMETERS
# ------------------------------------------------------------------------------------------------------------------

$displayTime                                = 30                   # How long message will display, in seconds


# ------------------------------------------------------------------------------------------------------------------
# INTERNAL SETTINGS
# ------------------------------------------------------------------------------------------------------------------

$debug                                    = "ON"                 # Turn "ON" / "OFF"  debug, default: "OFF" 
$loopDelay                                = 10                   #in seconds
$dateFormatLog                            = "yyyy-MM-dd HH:mm:ss.fff"
$dateFormatConfig                         = "yyyy-MM-dd HH:mm:ss"
$user                                     = $ENV:USERNAME

$msgAppData                               = "AppData"
$msgLocal                                 = "Local"
$msgComLimites                            = "ComLimites"
$msgFolder                                = "$ENV:PUBLIC\$($msgAppData)\$($msgLocal)\$($msgComLimites)"
$msgFile                                  = "$($msgFolder)\CLClientMsg_$($user).msg"

$log                                      = "$($msgFolder)\CLClientMsg_$($user).log" 

$wshell                                   = New-Object -ComObject Wscript.Shell # VBScript object


# ------------------------------------------------------------------------------------------------------------------
# POWERSHELL FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------
# Clear message file for user/client process
# ---------------------------------------------------------
Function Clear-Message-File
{
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Clearing message file $($msgFile)" >> $log }
    New-Item -Path $msgFile -ItemType File -Value "" -Force
}


# ---------------------------------------------------------
# Create an empty message file for user/client process
# ---------------------------------------------------------
Function Display-Message ([string] $msg)
{
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog)  Displaying MESSAGE:`n$($msg)`n" >> $log }
    $wshell.Popup($msg, $displayTime, "ComLimites ALERT!", 0 + 48)
}


# ---------------------------------------------------------
# Plays an audio WAV file given as parameter. It will not
# play anything if file is not found.
# ---------------------------------------------------------
Function Play-Audio-Message ([string] $soundFile)
{
    if ( Test-Path -Path "$($PSScriptRoot)\$soundFile" )
    {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Playing audio file $($soundFile)" >> $log }
        $PlayWav=New-Object System.Media.SoundPlayer
        $PlayWav.SoundLocation = "$($PSScriptRoot)\$soundFile"
        $PlayWav.Play()
    }
    else {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Audio file `'$($soundFile)`' not found." >> $log }
    }
}

# ------------------------------------------------------------------------------------------------------------------
# START CODE
# ------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------
# Verify run environment has what's needed to run script
# ---------------------------------------------------------


while (1)
{
    if ( -not (Test-Path -Path "$($msgFolder)" -PathType Container) )
    {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog)  Message folder was not found." }
    }

    if ( -not (Test-Path -Path "$($msgFile)" ) )
    {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog)  Message file was not found." }
    }
    else 
    {
        $audioFile = Get-Content $msgFile | select-object -First 1
        $msg = Get-Content $msgFile | select-object -skip 1
        if ( -not ($msg -eq $null ) )
        {
            Clear-Message-File
            Play-Audio-Message $audioFile
            Display-Message $msg
        }
        else { 
            if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog)  Message file is empty." } 
        }
    }
    Start-Sleep -s $loopDelay
}