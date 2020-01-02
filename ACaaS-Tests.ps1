$here = Split-Path -Parent $PSCommandPath
$sut = "$here/ACaaS.ps1"

$ansiblePath = "$here/ansible"

Describe 'ACaaS Tests' {

    Context 'No inventories' {
        $res = & $sut -ansibleRoot $ansiblePath

        It 'Returns nothing due to skipped play (no matching hosts)' {
            $res | Should -Be $null
        }
    }

    Context 'Single inventory: _common' {
        $res = & $sut -ansibleRoot $ansiblePath -inventories @('inventories/_common')

        It 'Returns the correct default values' {
            $res.org_name | Should -Be 'acmecorp'
            $res.org_name_short | Should -Be 'ac'
            $res.app_a_var | Should -Be 'foo'
            $res.app_a_other_var | Should -Be 'bar'
            $res.environment_name | Should -Be $null
            $res.cloud_name | Should -Be $null
        }
    }

    Context 'Multiple inventories: _common, local' {
        $inventories = @(
            "inventories/_common"
            "inventories/local"
        )
        $res = & $sut -ansibleRoot $ansiblePath -inventories $inventories

        It 'Returns the correct environment-specific values' {
            # values from '_common'
            $res.org_name | Should -Be 'acmecorp'
            $res.org_name_short | Should -Be 'ac'
            $res.app_a_var | Should -Be 'foo'
            $res.app_a_other_var | Should -Be 'bar'
            # values from 'local'
            $res.environment_name | Should -Be 'local'
            
            $res.cloud_name | Should -Be $null
        }
    }

    Context 'Multiple inventories with Limits' {
        $inventories = @(
            "inventories/_common"
            "inventories/_clouds"
            "inventories/dev"
        )
        $res = & $sut -ansibleRoot $ansiblePath -inventories $inventories -limit azure

        It 'Returns the correct environment & cloud specific values' {
            # values from '_common'
            $res.org_name | Should -Be 'acmecorp'
            $res.org_name_short | Should -Be 'ac'
            $res.app_a_var | Should -Be 'foo'
            $res.app_a_other_var | Should -Be 'bar-dev'
            # values from 'local'
            $res.environment_name | Should -Be 'dev'
            # values from '_clouds'
            $res.cloud_name | Should -Be 'azure'
        }
    }
}
