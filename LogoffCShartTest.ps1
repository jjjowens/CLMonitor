$id = get-random
$code = @"
    using System;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;

    namespace ConsoleApplication
    {

        public class Program$id
        {
            [DllImport("wtsapi32.dll", SetLastError = true)]
            static extern bool WTSLogoffSession(IntPtr hServer, int SessionId, bool bWait);
 
            [DllImport("wtsapi32.dll", SetLastError = true)]
            static extern IntPtr WTSOpenServer([MarshalAs(UnmanagedType.LPStr)] String pServerName);

            [DllImport("wtsapi32.dll")]
            static extern void WTSCloseServer(IntPtr hServer);

            
            [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)] 
            static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
            
            [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
            static extern IntPtr SendMessage(IntPtr hWnd, UInt32 Msg, IntPtr wParam, IntPtr lParam);


            internal static bool LogOffUser(IntPtr server, int userSessionID)
            {
                return WTSLogoffSession(server, userSessionID, true);
            }


            public static void Main(string[] args)
            {
            
                int userSessionID = int.Parse (args[0]);
                IntPtr server = WTSOpenServer(Environment.MachineName);
                try
                {
                    LogOffUser(server, userSessionID);
                }
                finally
                {
                    WTSCloseServer(server);
                }
            }
        }
    }
"@
<#

$user = "usuario"
$fullUser = "$($ENV:COMPUTERNAME)\$($user)" 

Function User-Logoff ([int] $sessionID)
{
    Invoke-Expression "[ConsoleApplication.Program$id]::Main(`"$($sessionID)`")"
}

Add-Type -TypeDefinition $code -Language CSharp

# Get PID associated to Explorer process for the user. The presence of this process is an indicator that user is logged in or not
$explorerPID = Get-Process -Name explorer -IncludeUserName | Where-Object {$_.UserName -eq $fullUser } | Select -ExpandProperty 'Id'
if ( $explorerPID ) { $userSessionID = (Get-Process -PID $explorerPID).SessionID }


if ( $userSessionID ) 
{
    echo "Ending session for user `'$($user)`', with session ID `'$($userSessionID)`'"
    User-Logoff $userSessionID
}
else
{
    echo "User `'$($user)`' is NOT logged in!"
}

#>


#Add-Type -AssemblyName PresentationCore,PresentationFramework

<#
for ($i=0; $i -lt 10; $i++)
{
    [System.Windows.MessageBox]::Show("Hello $($i)")

}


$wshell = New-Object -ComObject Wscript.Shell 
$Output = $wshell.Popup("The task has finished", 5)

#>

Add-Type -AssemblyName System.Windows.Forms 
$global:balloon = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id 13984).Path
if ( -not($path) ) { echo "Path is null" }
else { echo $path}
$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning 
$balloon.BalloonTipText = 'What do you think of this balloon tip?'
$balloon.BalloonTipTitle = "Attention $Env:USERNAME" 
$balloon.Visible = $true 
$balloon.ShowBalloonTip(5000)

echo "Waiting 5 seconds..."

Start-Sleep -s 5









