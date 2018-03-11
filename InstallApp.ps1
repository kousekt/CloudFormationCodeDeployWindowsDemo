& C:\Windows\SysNative\WindowsPowerShell\v1.0\powershell.exe -Command {Import-Module WebAdministration; Set-ItemProperty 'IIS:\sites\Default Web Site' -Name physicalPath -Value c:\NetCoreApp\publish}

# this is the same as "No Managed Code"
& C:\Windows\SysNative\WindowsPowerShell\v1.0\powershell.exe -Command {Import-Module WebAdministration; Set-ItemProperty 'IIS:\AppPools\TestAppPool' -Name managedRuntimeVersion -Value ''} 

& C:\Windows\SysNative\WindowsPowerShell\v1.0\powershell.exe -Command {Import-Module WebAdministration; Set-ItemProperty 'IIS:\AppPools\TestAppPool' -Name managedPipelineMode -Value 'Integrated'} 

# should be test app pool.
& C:\Windows\SysNative\WindowsPowerShell\v1.0\powershell.exe -Command {Import-Module WebAdministration; Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name ApplicationPool -Value TestAppPool} 