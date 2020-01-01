$here = Split-Path -Parent $PSCommandPath

if ( (Get-Module -ListAvailable Pester) -eq $null )
{
    Install-Module Pester -Force
}

Import-Module Pester
Invoke-Pester $here/ACaaS-Tests.ps1