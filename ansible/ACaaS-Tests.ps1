$here = Split-Path -Parent $PSCommandPath
$sut = "$here/ACaaS.ps1"

Describe 'ACaaS Tests' {

    Context 'No inventories' {
        $res = & $sut

        It 'Returns nothing due to skipped play (no matching hosts)' {
            $res | Should -Be $null
        }
    }

    Context 'Single inventory: _common' {
        $res = & $sut -inventories @('inventories/_common')

        It 'Returns the correct default values' {
            $res.org_name | Should -Be 'acmecorp'
            $res.org_name_short | Should -Be 'ac'
            $res.app_a_var | Should -Be 'foo'
            $res.app_a_other_var | Should -Be 'bar'
            $res.environment_name | Should -Be $null
        }
    }

    Context 'Multiple inventories: _common, local' {
        $inventories = @(
            "inventories/_common"
            "inventories/local"
        )
        $res = & $sut -inventories $inventories

        It 'Returns the correct environment-specific values' {
            # values from '_common'
            $res.org_name | Should -Be 'acmecorp'
            $res.org_name_short | Should -Be 'ac'
            $res.app_a_var | Should -Be 'foo'
            $res.app_a_other_var | Should -Be 'bar'
            # values from 'local'
            $res.environment_name | Should -Be 'local'
        }
    }
}
