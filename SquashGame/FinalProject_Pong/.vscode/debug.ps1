<# Debug Script
Reference used in development: https://social.msdn.microsoft.com/Forums/vstudio/en-US/3d854f8d-3597-423c-853a-ba030e721d6e/visual-studio-debugger-command-line?forum=vcgeneral
#>
param (
	[string]$workspaceFolder = "."
)
echo off
set exefile=%1%
echo "Starting visual studio debugger for %exefile%"
echo "------------------------------------------------------------------------------------------------"
echo on
$assemblerfiles="" + (get-item $workspaceFolder/source/*.asm)
if ( -not $assemblerfiles) {
	echo "No files to compile!"
	exit
}
$exefile="$workspaceFolder/bin/main.exe"
# Set the 64 bit development environment by calling vcvars64.bat 
# Compile and link in one step using ml64.exe 
$ranstring = -join ((48..57) + (97..122) | Get-Random -Count 32 | % {[char]$_})
$batfile = "$workspaceFolder/.vscode/" + $ranstring + ".bat"
$command = 'set VSWHERE="%ProgramFiles(x86)%/Microsoft Visual Studio/Installer/vswhere.exe"'
write-output $command | out-file -encoding ascii $batfile 
$command = 'for /f "usebackq tokens=*" %i in (`%VSWHERE% -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do ('
write-output $command | out-file -encoding ascii -append $batfile 
$command = "    set InstallDir=%i"
write-output $command | out-file -encoding ascii -append $batfile 
$command = ") " 
write-output $command | out-file -encoding ascii -append $batfile 
$command = '"%InstallDir%/VC/Auxiliary/Build/vcvars64".bat' 
write-output $command | out-file -encoding ascii -append $batfile 
$command = '"devenv.exe" ' + $assemblerfiles + ' /debugexe ' + $exefile 
write-output $command | out-file -encoding ascii -append $batfile 
type $batfile | CMD
rm $batfile
