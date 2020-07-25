> **CLMonitor Install:**
>
>  

1.  Copy the CLMonitor.ps1 script to a folder accessible only by the
    > admin user on the computer.\
    > For example: C:\\Users\\Desktop\\ComLimites\\CLMonitor.ps1

>  
>
> ![Home Quick access Desktop Share Managed View Managed Name
> CLMonitor.ps1 Date modified 7/24/2020 10:02 AM Search CLMonitor Type
> Windows PowerShe\... Size 26 KB ](./media/image1.png){width="6.4375in"
> height="1.3645833333333333in"}
>
>  
>
>  

1.  Open CLMonitor.ps1 on a text editor and adjust these variables:

>  
>
> \$maxActive = 60
>
> \$minBreak = 10
>
> \$dayMin = Get-Date \'09:00\'
>
> \$dayMax = Get-Date \'22:00\'
>
>  
>
> ![40 41 42 44 \'10:00 46 Get -Date \'22:00 47 Get -Date 48 \# USER
> DEFINED SmaxAct i ve Smi n8reak SdayM i n S dayMax PARAMETERS = 161 4
> Max time al lowed in mi nutes, default 60 minutes Minimum break in mi
> nutes, default 10 minutes Time of day computer can be used. Before
> this time Time of day computer will shutdown. Past this time
> ](./media/image2.png){width="6.427083333333333in" height="0.875in"}
>
>  
>
> Save the file
>
>  

1.  Run Task Scheduler and add a task with the following properties:

>  
>
> General:
>
> Name: ComLimites Monitor
>
> Description: ComLimites Monitor
>
> Select: Run Weather user is logged or not
>
> Check: Run with highest privileges
>
>  
>
> ![ComLimites Monitor Properties (Local Computer) General Triggers
> Actions Conditions Settings History (disabled) Name: Location: Author:
> ComLimites Monitor WAMPVM\\jjowens Descri ption: Security options When
> running the task, use the following user account: WAMPVM\\jjowens O
> Run only when user is logged on @ Run whether user is logged on or not
> Change User or Group.„ D Do not store password. The task will only
> have access to local computer resources. Z\] Run with highest
> privileges Hidden Configure for: Windows Vista W, Windows Server W
> 2008 OK Cancel ](./media/image3.png){width="6.46875in"
> height="5.40625in"}
>
>  
>
> Triggers:
>
> Begin the Task: At log on
>
> Specific user: \[Windows user to monitor\]
>
>  
>
> ![Edit Trigger Begin the task Settings O Any user At log on @ Specific
> user: Advanced settings WAMPVM\\usuärio_pt D Delay task for: 15
> minutes D Repeat task every: 1 hour for a duration of: Change User.„ 1
> day Stop all running tasks at end of repetition duration D Stop task
> if it runs longer than: D Activate: D Expire: Z\] Enabled 7/24/2020
> 7/24/2021 3 days AM AM C) Synchronize across time zones C) Synchronize
> across time zones OK Cancel ](./media/image4.png){width="6.4375in"
> height="5.958333333333333in"}
>
>  
>
> Actions
>
> Action: Start a program
>
> Program/Script: PowerShell.exe
>
> Add arguments: -noprofile -executionpolicy bypass -file
> \"x:\\path\\to\\script\\CLMonitor.ps1\" \"user name\"
>
>  
>
> ![Edit Action You must specify what action this task will perform.
> Action: Start a program Settings Program/script: PowerShell.exe Add
> arguments (optional): Start in (optional): OK itor.psl Browse.„
> \'usuärio_pt\' Cancel ](./media/image5.png){width="5.65625in"
> height="6.229166666666667in"}
>
>  
>
> Conditions:
>
> Uncheck: Start the task only if the computer is on AC power
>
>  
>
> ![ComLimites Monitor Properties (Local Computer) General Triggers
> Actions Conditions Settings History (disabled) Specify the conditions
> that, along with the trigger, determine whether the task should run.
> The task will not run if any condition specified here is not true.
> Idle D Start the task only if the computer is idle for: Wait for idle
> for: Stop if the computer ceases to be idle Restart if the idle state
> resumes Power D Start the task only if the computer is on AC power
> Stop if the computer switches to battery power D Wake the computer to
> run this task Network 10 minutes 1 hour D Start only if the following
> network connection is available: ny connection OK Cancel
> ](./media/image6.png){width="6.46875in" height="5.40625in"}
>
>  
>
> Settings:
>
> Uncheck: Stop the task if it runs longer than:
>
>  
>
> ![ComLimites Monitor Properties (Local Computer) General Triggers
> Actions Conditions Settings History (disabled) Specify additional
> settings that affect the behavior of the task Z\] Allow task to be run
> on demand D Run task as soon as possible after a scheduled start is
> missed D If the task fails, restart every: Attempt to restart up to: D
> Stop the task if it runs longer than: 1 minute v times 3 days v Z\] If
> the running task does not end when requested, force it to stop D If
> the task is not scheduled to run again, delete it after: If the task
> is already running, then the following rule applies: Do not start a
> new instance 30 days OK Cancel ](./media/image7.png){width="6.46875in"
> height="5.40625in"}
>
>  
>
> Click OK to save, enter your admin user password
>
> ![Task Scheduler Enter user account information for running this task.
> User name: Passvuord: WAMPV Cancel
> ](./media/image8.png){width="3.90625in" height="3.3229166666666665in"}
>
>  
>
>  
>
> **CLClient Install:**

1.  Navigate and create the following folder:

>  
>
> C:\\Users\\usuário_pt\\AppData\\Local\\ComLimites
>
>  

1.  Copy CLClient.ps1 and the associated audio files to that folder

> ![Play Music Tools Home Desktop Downloads Documents Pictures CLMonitor
> ComLimites P rojects Share View Name Sminwarning.wav 1 Sminwarning.wav
> CLClient.ps1 @ continuesession.wav @ outsidehours.wav @
> stillinbreak.wav @ timesup.wav Title Contributing
> ](./media/image9.png){width="6.5in" height="2.9479166666666665in"}
>
>  

1.  In the user folder, right click and select New \> Shortcut. In the
    > location field enter this:

> ![View Sort by Group by Refresh Customize this Paste Paste shortcut
> Undo Delete Git GUI Here Git Bash Here Give access to New Properties
> Ctrl+Z s Folder Shortcut Bitmap image Rich Text Document Text Document
> Compressed (zipped) Folder
> ](./media/image10.png){width="5.979166666666667in" height="4.1875in"}
>
>  
>
> PowerShell.exe -noprofile -executionpolicy bypass -file
> \"x:\\path\\to\\script\\CLClient.ps1\"
>
>  
>
> ![Create Shortcut What item would you like to create a shortcut for?
> This wizard helps you to create shortcuts to local or network
> programs, files, folders, computers, or Internet addresses. Type the
> location of the item: )ypass -file \" Click Next to continue.
> Browse\... Next Cancel
> ](./media/image11.png){width="6.489583333333333in"
> height="5.166666666666667in"}
>
>  
>
>  
>
> Name the shortcut CLClient
>
> ![Create Shortcut What would you like to name the shortcut? Type a
> name for this shortcut: CLClient Click Finish to create the shortcut.
> Finish Cancel ](./media/image12.png){width="6.458333333333333in"
> height="5.15625in"}
>
>  

1.  Move the shortcut to the following folder:

>  
>
> C:\\Users\\\[user name\]\\AppData\\Roaming\\Microsoft\\Windows\\Start
> Menu\\Programs\\Startup
>
> ![Home Desktop Downloads Documents Share View Name CLClient Date
> modified 7/24/2020 8:49 AM Search Startup Type Shortcut Size
> ](./media/image13.png){width="6.489583333333333in"
> height="1.3229166666666667in"}
