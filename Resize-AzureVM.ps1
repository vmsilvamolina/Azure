function Resize-AzureVM {
    <#
    .Synopsis
    Allows you to visually scale a virtual machine, without all the typing.
    .Parameter Force
    The -Force parameter suppresses the prompt asking if you are sure you want to 
    resize the virtual machine.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch] $Force
    )

    $AzureVM = Get-AzureVM -ErrorAction Stop | Select-Object -Property ServiceName, Name, InstanceStatus, InstanceSize | Out-GridView -Title 'Select an Azure Virtual Machine to resize' -OutputMode Single;
    if (!$AzureVM) {
        Write-Warning -Message 'No Azure VM selection made. Please re-run the function and select an Azure Virtual Machine.';
        return;
    }
    $AzureVM = Get-AzureVM -ServiceName $AzureVM.ServiceName -Name $AzureVM.Name -ErrorAction Stop;

    $TargetRoleSize = Get-AzureRoleSize -ErrorAction Stop | Select-Object -Property InstanceSize,RoleSizeLabel,Cores, @{ Name = 'MemoryInGB'; Expression = { $PSItem.MemoryInMB/1024; }; } | Out-GridView -Title ('Select your new role size (current: {0})' -f $AzureVM.InstanceSize) -OutputMode Single;
    if (!$TargetRoleSize) {
        Write-Warning -Message 'No role size selection made. Please re-run the function and select a role size.';
        return;
    }
  
    if ($AzureVM.InstanceSize -eq $TargetRoleSize.InstanceSize) {
        Write-Warning -Message 'Selected target role size is the same as the Virtual Machine''s current role size.';
        return;
    }

    if ($Force -or $PSCmdlet.ShouldProcess(('Azure VM {0}/{1}' -f $AzureVM.ServiceName, $AzureVM.Name), ('Resize virtual machine to {0}' -f $TargetRoleSize.InstanceSize))) {
        Write-Verbose -Message ('Updating Azure VM {0}/{1} from size {2} to {3}' -f $AzureVM.ServiceName, $AzureVM.Name, $AzureVM.InstanceSize, $TargetRoleSize.InstanceSize);
        $null = Set-AzureVMSize -InstanceSize $TargetRoleSize.InstanceSize -VM $AzureVM.VM -ErrorAction Stop;
        Update-AzureVM -ServiceName $AzureVM.ServiceName -Name $AzureVM.Name -VM $AzureVM.VM -ErrorAction Stop;
    }
}
