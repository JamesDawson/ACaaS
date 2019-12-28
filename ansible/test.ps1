$here = (Split-Path -Parent $PSCommandPath).Replace("\","/")

$cmd = @(
 "docker run --rm -it"
 "-v $($here):/src"
 "-e ANSIBLE_STDOUT_CALLBACK=yaml"
 "-w /src"
 "ansible/ansible-runner"
 "ansible-playbook -v -i inventories/_common playbook.yml"
)
Write-Host $cmd
Invoke-Expression ($cmd -join " ")
