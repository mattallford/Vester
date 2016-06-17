#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core

# Variables
Invoke-Expression -Command (Get-Item -Path ($PSScriptRoot + '\Config.ps1'))
[string]$drsmode = $global:config.cluster.drsmode
[int]$drslevel = $global:config.cluster.drslevel
[bool]$fix = $global:config.pester.remediate

# Tests
Describe -Name 'Cluster Configuration: DRS Settings' -Fixture {
    foreach ($cluster in (Get-Cluster)) 
    {
        It -name "$($cluster.name) Cluster DRS Mode" -test {
            $value = (Get-Cluster $cluster).DrsAutomationLevel
            try 
            {
                $value | Should Be $drsmode
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $cluster"
                    Set-Cluster -Cluster $cluster -DrsAutomationLevel:$drsmode -Confirm:$false -ErrorAction Stop
                }
                else 
                {
                    throw $_
                }
            }
        }
        It -name "$($cluster.name) Cluster DRS Automation Level" -test {
            $value = (Get-Cluster $cluster | Get-View).Configuration.DrsConfig.VmotionRate
            try 
            {
                $value | Should Be $drslevel
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $cluster"
                    $clusterview = Get-Cluster -Name $cluster | Get-View
                    $clusterspec = New-Object -TypeName VMware.Vim.ClusterConfigSpecEx
                    $clusterspec.drsConfig = New-Object -TypeName VMware.Vim.ClusterDrsConfigInfo
                    $clusterspec.drsConfig.vmotionRate = $drslevel
                    $clusterview.ReconfigureComputeResource_Task($clusterspec, $true)
                }
                else 
                {
                    throw $_
                }
            }
        }
    }
}