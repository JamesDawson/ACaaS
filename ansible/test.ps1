param
(
    $environment,
    $filter,
    [switch] $noCleanUp
)
$ErrorActionPreference = 'Stop'
$here = (Split-Path -Parent $PSCommandPath).Replace("\","/")

$id = [Guid]::NewGuid().Guid
$outputFilename = "{0}.json" -f $id
$containerName = "acaas-$id"

$cmd = @(
 "docker run -it"
 "--name $containerName"
 "-v $($here):/src"
 "-e ANSIBLE_STDOUT_CALLBACK=yaml"
 "-w /src"
 "ansible/ansible-runner"
 "ansible-playbook -v -i inventories/_common -e out_file=$outputFilename playbook.yml"
)
Write-Host $cmd
Invoke-Expression ($cmd -join " ")
if ($LASTEXITCODE -ne 0)
{
    Write-Error "Error performing `docker run` operation: $LASTEXITCODE"
}

try
{
    $dockerCpCmd = "docker cp {0}:/tmp/{1} {1}" -f $containerName, $outputFilename
    Write-Verbose "dockerCpCmd: $dockerCpCmd"
    Invoke-Expression $dockerCpCmd
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "Error performing `docker cp` operation: $LASTEXITCODE"
    }

    # parse results
    $results = Get-Content -Raw -Path $outputFilename | ConvertFrom-Json
}
finally
{
    if (!$noCleanUp)
    {
        # Remove the exited container instance
        docker rm $containerName
        Remove-Item $outputFilename
    }
}

# output
$results.org_name
$results.app_a_var
$results.app_a_other_var
