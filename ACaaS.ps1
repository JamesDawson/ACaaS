[CmdletBinding()]
param
(
  [string] $ansibleRoot,
  [array] $inventories
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3
$here = (Split-Path -Parent $PSCommandPath).Replace("\","/")

$inVerboseMode = $VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue
$outputSink = if ($inVerboseMode) {'Out-Default'} else {'Out-Null'}

function Get-AnsibleCmd($outFile, $inventories)
{
  $cmd = @(
    "ansible-playbook"
    "-e out_file=$outFile"
    "playbook.yml"
  )

  foreach ($i in $inventories)
  {
    $cmd += "-i $i"
  }

  if ($inVerboseMode)
  {
    $cmd += "-vvvv"
  }

  return $cmd
}

function Get-DockerRunCmd($name, $path, $ansibleCmd)
{
  $cmd = @(
    "docker run -it"
    "--name $name"
    "-v $($path):/src"
    "-e ANSIBLE_STDOUT_CALLBACK=yaml"
    "-w /src"
    "ansible/ansible-runner"
    $ansibleCmd -join " "
   )

   return $cmd
}

$id = [Guid]::NewGuid().Guid
$outputFilename = "{0}.json" -f $id
$containerName = "acaas-$id"

$ansibleCmd = Get-AnsibleCmd $outputFilename $inventories
$dockerRunCmd = Get-DockerRunCmd $containerName $ansibleRoot $ansibleCmd
Write-Verbose "$dockerRunCmd"

Invoke-Expression ($dockerRunCmd -join " ") | & $outputSink
if ($LASTEXITCODE -ne 0)
{
    Write-Error "Error performing `docker run` operation: $LASTEXITCODE"
}

$results = $null
try
{
    $dockerCpCmd = "docker cp {0}:/tmp/{1} {1}" -f $containerName, $outputFilename
    Write-Verbose "$dockerCpCmd"
    # Suppress error output when the file being copies doesn't exist
    $ErrorActionPreference = 'SilentlyContinue'
    Invoke-Expression $dockerCpCmd 2>&1 | & $outputSink
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -eq 0)
    {
      # parse results
      $results = Get-Content -Raw -Path $outputFilename | ConvertFrom-Json
    }
}
finally
{
    if (!$inVerboseMode)
    {
        # Remove the exited container instance
        docker rm $containerName | & $outputSink
        Remove-Item $outputFilename -ErrorAction SilentlyContinue
    }
}

# output
$results
