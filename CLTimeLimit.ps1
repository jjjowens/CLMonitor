# ------------------------------------------------------------------------------------------------------------------
# Script      : CLTimeLimit.ps1
# Author      : James Owens                                      
# Date        : 10-July-2020                                     
# Version     : V 0.1beta                                            
# Run         : Windows Task Scheduler, on Logon event using command 
#             : PowerShell -noprofile -executionpolicy bypass -file "CLTimeLimit.ps1" user_id
# ------------------------------------------------------------------------------------------------------------------
# Description: PowerShell script created to control how much time a given Windows user can keep
#   a session open. There are three parameters to control this:
#
#       dayMin: How early in the day user can login in format HH:MM
#       dayMax: How late in the day user can login in format HH:MM
#       maxActive: How long each user session can be as to force user to take regular breaks in minutes
#       minBreak: How long of a break user must take between sessions, in minutes
#
#   If user tries to login outside the range defined by dayMin and dayMax, user will see a 
#   message and be automatically logged off in 10 seconds. Similarly, a message will display
#   if user tries to login after running a session of maxAcive, but before time set by minBreak
#   has passed.
#
#   IMPORTANT: USER WILL BE LOGGED OUT AND ALL APPLICATIONS WILL CLOSED. USER WILL HAVE 60 SECONDS
#              TO SAVE AND CLOSE EVERYTHING SO TO NOT LOSE ANY WORK. A WARNING MESSAGE WILL 
#              DISPLAY AND PLAY AT 15 AND 5 MINUTE MARK BEFORE FORCED LOGOFF. IF USER LOGS OUT 
#              BEFORE maxActive AND LATER LOGIN AGAIN BUT BEFORE minBreak HAS PASSED, THE 
#              SESSION WILL CONTINUE AND THE PERIOD OF TIME USER REMAINED LOGGED OUT WILL NOT
#              COUNT TOWARDS BREAK.
#    
#   Some conditions that are not accounted for:
#  
#     * dayMin comes after dayMax
#     * If user initiates session just before maxDay, session will terminate with message of 
#       'outside allowed period' 
#     
# ------------------------------------------------------------------------------------------------------------------

#Define runtime environment
$Error.Clear()
#Set-StrictMode –Version Latest      

# ------------------------------------------------------------------------------------------------------------------
# USER DEFINED PARAMETERS
# ------------------------------------------------------------------------------------------------------------------

$maxActive                                = 120                  # Max time allowed in minutes, default 60 minutes
$minBreak                                 = 60                   # Minimum break in minutes, default 10 minutes
$dayMin                                   = Get-Date '09:00'     # Time of day computer can be used. Before this time it will not allow login, default 09:00
$dayMax                                   = Get-Date '22:11'     # Time of day computer will shutdown. Past this time it will not allow login, default 22:00

# ------------------------------------------------------------------------------------------------------------------
# INTERNAL SETTINGS
# ------------------------------------------------------------------------------------------------------------------

$debug                                    = "ON"                 # Turn "ON" / "OFF"  debug, default: "OFF" 
$loopDelay                                = 30                   #in seconds
$configFolder                             = "$ENV:TEMP\49XfjUZaRl1"
$configFile                               = "$($configFolder)\8EorCi7NH4JEuj0.CLTL"
$log                                      = "$($configFolder)\CLTimeLimit.log" 
$dateFormatLog                            = "yyyy-MM-dd HH:mm:ss.fff"
$dateFormatConfig                         = "yyyy-MM-dd HH:mm:ss"
$user                                     = $args[0]
#$user                                     = "jjowens"

# ------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------




# ---------------------------------------------------------
# Updates the configuration file. It is composed of 3 lines:
# Line1: A time stamp representing when user session started
# Line2: A count of time used in current session, in seconds
# Line3: Flag indicating if user is on break or not, in secs
# ---------------------------------------------------------
Function Update-Config-File ([string] $thisTimeUsed, [string] $thisBreakFlag)
{
    $content = $(Get-Date -Format $dateFormatConfig)
    $content = "$($content)`n"
    $content = "$($content)$thisTimeUsed"
    $content = "$($content)`n"
    $content = "$($content)$($thisBreakFlag)"
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Updating config file $($configFile) with following parameters: [`n$($content)`n]" >> $log }
    New-Item -Path $configFile -ItemType File -Value "$($content)" -Force
}


# ---------------------------------------------------------
# Reset configuration file to its default initial values
# ---------------------------------------------------------
Function Reset-Config-File
{
    Update-Config-File "0" "false"
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
        $PlayWav.playsync()
    }
    else {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Audio file `'$($soundFile)`' not found." >> $log }
    }
}

# ---------------------------------------------------------
# Displays an asychronous message to user
# ---------------------------------------------------------
Function Display-Message ([string] $msg)
{
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) MESSAGE: [`n$($msg)`n]" >> $log }
    msg $user $msg
}


# ------------------------------------------------------------------------------------------------------------------
# START CODE
# ------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------
# Verify run environment has what's needed to run script
# ---------------------------------------------------------

if ( $debug -eq "ON" ) { echo "--------------" >> $log }

# If user is not defined, abort.
if ( -not($user) ) 
{
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog)  Username was NOT passed in the arguments. Exitig script." >> $log }
    exit
}

$now = Get-Date
$sessionId = ((quser | Where-Object { $_ -match $user }) -split ' +')[2]                #User SessionID is used to determined if user is logged in or not.

if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) User: `'$($user)`' Break: `'$($minBreak)`' minutes, max session duration is $($maxActive) minutes and allowed times between `'$($dayMin)`' and `'$($dayMax)`'" >> $log }

# Ensure path where configuration file will be saved is valid. Will create cryptic folder if one does not exist.
if ( -not (Test-Path -Path $configFolder -PathType Container) )
{
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog)  Folder $($configFolder) not found, creating it..." >> $log }
    mkdir $configFolder
    if ( -not (Test-Path -Path $configFolder -PathType Container) )
    {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Unable to create folder $($configFolder). Exiting script." >> $log }
        Exit
    }
}



# ---------------------------------------------------------
# MAIN CODE STARTS HERE
# ---------------------------------------------------------

# Once again, check if cryptic folder is present
if ( Test-Path -Path $configFolder -PathType Container )
{

    if ( -not (Test-Path -Path $configFile ) )  
    { 
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Config file $($configFile) does not exist, it will be created." >> $log }
        Reset-Config-File 
    }


    # Check if timestamp in file is from a different day, it will reset if it is. 
    if ( (($now) - (ls $configFile).LastWriteTime).days -ge 1)
    {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Temp file $($configFile) is from an earlier day. Reinitializing parameters." >> $log }
        Reset-Config-File
    }


    # Read configuration file contents
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Reading contents of temp file $($configFile)." >> $log }
    $i = 0
    foreach($line in Get-Content $configFile) 
    {
        if ( $i -eq 0 ) { $dateInFile = Get-Date $line }
        if ( $i -eq 1 ) { $timeUsedFile = $line -as[int] }
        if ( $i -eq 2 ) { $breakFlag = $line }
        $i++
    }
            
    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Date in File: `'$($dateInFile)`', Used Time: `'$($timeUsedFile)`' and Break Flag: `'$($breakFlag)`'" >> $log }
    
    # Action if user is on break
    if ( $breakFlag -eq "true" )
    {
        $now = Get-Date

        #Check if break has ended
        if ( (($now) - $dateInFile.AddMinutes($minBreak)) -gt 0 )
        {
            if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Break complete, resetting settings in $($configFile)." >> $log }
            Reset-Config-File

            #Update config parameters in memory
            $dateInFile = Get-Date
            $timeUsedFile = 0
            $breakFlag = "false"
        }
        else {
            Display-Message "Back already? Go play some more. You are on break for another $(($dateInFile.AddMinutes($minBreak + 1) - $now).Minutes) minute(s)."
            Play-Audio-Message "stillinbreak.wav"
            Start-Sleep -s 10
            if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Logging off user $($user)." >> $log }
            logoff $sessionId
            if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Ending script." >> $log }
            exit
        }
    }



    # Check if user has been away for longer than minBreak
    if ( ($now) - $dateInFile.AddMinutes($minBreak) -gt 0 )
    {
        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) User has been away for longer than required minimum break. Resetting file." >> $log }
        # This is needed to update file's timestamp. Content is unaltered
        Reset-Config-File

        #Update config parameters in memory
        $dateInFile = Get-Date
        $timeUsedFile = 0
        $breakFlag = "false"
    }

    # -------------
    # Set pre-conditions before entering the main loop
    # -------------

    if ( $breakFlag -eq "false" )
    {
        $warning15                     = "false"
        $warning5                      = "false"

        # $scriptStart    : Timestamp of when this script entered the main processing session
        # $now            : Current timestamp
        # $timeSpan       : How much time spent between now and when script started       
        # $timeScriptRun  : How long this script has been running, in seconds
        # $totalTimeUsed  : How long user session has been active
        # $timeLeftSeconds: How much time user has left on current session
        # NOTE: IF MAKING ANY CHANGES HERE, MAKE SURE TO CHANGE SAME LOGIC AT START OF WHILE


        $scriptStart                   = Get-Date
        $now                           = Get-Date
        $timeSpan                      = ($now - $dateInFile)
        $timeScriptRun                 = ($now - $scriptStart)
        $totalTimeUsed                 = $timeUsedFile + $timeScriptRun.Days*24*60*60 + $timeScriptRun.Hours*60*60 + $timeScriptRun.Minutes*60 + $timeScriptRun.Seconds
        $timeLeftSeconds               = ($maxActive * 60) - $timeUsedFile

        if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Time between now and last record on file: $(($timeSpan.Hours * 60) + $timeSpan.Minutes) minutes, Total Time Used: $($totalTimeUsed) seconds, Time Left to use: $($timeLeftSeconds) seconds" >> $log }
        
        # Check if user has any time left on session
        if ( ($timeLeftSeconds -gt 0) -and ($timeUsedFile -gt 0) )
        {
            $timeSecondsRound = $timeLeftSeconds / 60
            $timeSecondsRound = [math]::Round($timeSecondsRound, 1)
            Display-Message "Welcome back! This is a continuation of your previous session`nYou have $($timeSecondsRound) minutes left."
            Play-Audio-Message "continuesession.wav"
            if ($timeSecondsRound -lt 15 ) { $warning15 = "true" }
            if ($timeSecondsRound -lt 5  ) { $warning5  = "true" } 
        }

        while (1)
        {
            if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Entering monitor loop." >> $log }

            # Check if current time fall between $dayMin and $dayMax
            if ($dayMin.TimeOfDay -le $now.TimeOfDay -and $dayMax.TimeOfDay -ge $now.TimeOfDay)
            {
                if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Determined script is running during allowed time." >> $log }

                # ENHANCEMENT SUGGESTION: Check if $dayMax will occur before $maxActive and present warning to user

                # $now            : Current timestamp
                # $timeSpan       : How much time spent between now and when script started       
                # $timeScriptRun  : How long this script has been running, in seconds
                # $totalTimeUsed  : How long user session has been active
                # $timeLeftSeconds: How much time user has left on current session
                # NOTE: IF MAKING ANY CHANGES HERE, MAKE SURE TO CHANGE SAME LOGIC BEFORE THE MONITOR LOOP

                $now = Get-Date
                $timeSpan = ($now - $dateInFile)
                $timeScriptRun = ($now - $scriptStart)
                $totalTimeUsed = $timeUsedFile + $timeScriptRun.Days*24*60*60 + $timeScriptRun.Hours*60*60 + $timeScriptRun.Minutes*60 + $timeScriptRun.Seconds
                $timeLeftSeconds = (($maxActive * 60) - $totalTimeUsed)

                if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Determined user has $($timeLeftSeconds) seconds to use." >> $log }

                $now = Get-Date

                # Does user have any time left in the session? Yes if true
                if ( $timeLeftSeconds -gt 0 )
                {   
                    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Determined user is within its active time. Updating configuration file." >> $log }

                    Update-Config-File $totalTimeUsed "false"
                    
                    # Will session end in 15 minutes ore less? True if yes. Will display only once, hence the one time use flags
                    if ( (($timeLeftSeconds/60) -lt 15 ) -and ($warning15 -eq "false") -and ($warning5 -eq "false") )
                    {
                        $warning15 = "true"
                        Display-Message "Just a reminder that your break will start in 15 minutes."
                        Play-Audio-Message "15minwarning.wav"
                    }

                    # Do it again, but this time at the 5 minute mark
                    if ( (($timeLeftSeconds/60) -lt 5) -and ($warning15 -eq "true") -and ($warning5 -eq "false") )
                    {
                        $warning5 = "true"
                        Display-Message "Just a reminder that your break will start in 5 minutes."
                        Play-Audio-Message "5minwarning.wav"
                    }

                }
                # User does reached the end of session time
                else {
                    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) User $($user) has been active for $($maxActive) minutes and reached its end after `'$($maxActive)`' minutes" >> $log }

                    #Update config file setting break flag to true
                    Update-Config-File "0" "true"
                    Display-Message "You have used the computer for $($maxActive) minutes. It's time to take a $($minBreak) minute break. `n`nSave your work!!`n`nYour session will close in 60 seconds."
                    Play-Audio-Message "timesup.wav"
                    Start-Sleep -s 60
                    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Logging off user $($user)." >> $log }
                    $sessionId = ((quser | Where-Object { $_ -match $user }) -split ' +')[2]
                    logoff $sessionId
                    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Exiting script." >> $log }
                    Update-Config-File "0" "true" # Repeat update here in case user decides to wait the entre 60 seconds. 
                    exit
                }

                #Check if user logged out and if so, set to 'On Break' and kill script
                $sessionId = ((quser | Where-Object { $_ -match $user }) -split ' +')[2]

                if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Checked user status and got `'$($sessionId)`'" >> $log }

                # True if user is no longer in
                if ( -not($sessionId) ) 
                {
                    if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) It appears user $($user) is no longer active. Terminating script." >> $log }

                    # Update total time used in config file and exit script.
                    Update-Config-File $totalTimeUsed "false"
                    exit
                }

            } 

            # This is what happens when user tries to login outside allowed times
            else {

                $msg = "It is now $($now.TimeOfDay.Hours):$($now.TimeOfDay.Minutes):$($now.TimeOfDay.Seconds). "
                $msg = "$($msg)This account is set to be enabled between `n`n$($dayMin.TimeOfDay) and `n" 
                $msg = "$($msg)$($dayMax.TimeOfDay)`n`nYou will be logged out in 10 seconds!"
                Display-Message $msg
                Play-Audio-Message "outsidehours.wav"
                Start-Sleep -s 10
                if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Logging off user $($user)." >> $log }
                $sessionId = ((quser | Where-Object { $_ -match $user }) -split ' +')[2]
                logoff $sessionId
                if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Exiting script." >> $log }
                exit
            }

            if ( $debug -eq "ON" ) { echo "$(Get-Date -Format $dateFormatLog) Sleep for $($loopDelay) seconds." >> $log }

            #Sleep for some time
            Start-Sleep -s $loopDelay

        } #### THIS IS THE END OF THE INFINITE WHILE LOOP
    }
}