﻿# Connect to Azure Tenant
Connect-AzAccount -Tenant $TargetTenant

$subscriptionList = Get-AzSubscription -TenantId $TargetTenant
$subscriptionList | Format-Table | Out-Default

foreach ($subscription in $subscriptionList) {

    Try { $null = Set-AzContext -SubscriptionId $subscription }
    catch [Exception] { write-host ("Error occured: " + $($_.Exception.Message)) -ForegroundColor Red; Exit }
    Write-Host "Azure Login Session successful" -ForegroundColor Green -BackgroundColor Black

    # Initialise output array
$Output = [System.Collections.ArrayList]::new()
$ResourceGroups = Get-AzResourceGroup 
    foreach ($ResourceGroup in $ResourceGroups) {
        Write-Host "Resource Group =$($ResourceGroup.ResourceGroupName)"
        $resourceNames = Get-AzResource -ResourceGroupName $ResourceGroup.ResourceGroupName
        $tags = Get-AzTag -ResourceId $ResourceGroup.ResourceId
        foreach ($key in $tags.Properties.TagsProperty.Keys) {
            $csvObject = New-Object PSObject
            Add-Member -inputObject $csvObject -memberType NoteProperty -name "ResourceID" -value $ResourceGroup.ResourceID
            Add-Member -inputObject $csvObject -memberType NoteProperty -name "ResourceGroup" -value $ResourceGroup.ResourceGroupName
            Add-Member -inputObject $csvObject -memberType NoteProperty -name "ResourceName" -value ''
            Add-Member -inputObject $csvObject -memberType NoteProperty -name "TagKey" -value $key
            Add-Member -inputObject $csvObject -memberType NoteProperty -name "Value" -value $tags.Properties.TagsProperty.Item($($key))
            $Output.Add($csvObject)

            #$Output += "`t ResourceGroup = $($ResourceGroup.ResourceGroupName) `t TagKey= $($key) `t Value = $($tags.Properties.TagsProperty.Item($($key)))"
            Write-Host "`t ResourceGroup = $($ResourceGroup.ResourceGroupName) `t TagKey= $($key) `t Value = $($tags.Properties.TagsProperty.Item($($key)))"
        }
        foreach ($res in $resourceNames) {
            Write-Host "ResourceName = $($res.Name)"
            $tags = Get-AzTag -ResourceId $res.ResourceId
            foreach ($key in $tags.Properties.TagsProperty.Keys) {
                $csvObject = New-Object PSObject
                Add-Member -inputObject $csvObject -memberType NoteProperty -name "ResourceID" -value $ResourceGroup.ResourceID
                Add-Member -inputObject $csvObject -memberType NoteProperty -name "ResourceGroup" -value $ResourceGroup.ResourceGroupName
                Add-Member -inputObject $csvObject -memberType NoteProperty -name "ResourceName" -value $res.Name
                Add-Member -inputObject $csvObject -memberType NoteProperty -name "TagKey" -value $key
                Add-Member -inputObject $csvObject -memberType NoteProperty -name "Value" -value $tags.Properties.TagsProperty.Item($($key))               
                $Output.Add($csvObject)

                #$Output += "`t ResourceGroup = $($ResourceGroup.ResourceGroupName) `t TagKey= $($key) `t Value = $($tags.Properties.TagsProperty.Item($($key)))"
                Write-Host "`t `t ResourceID = $($ResourceGroup.ResourceId) `t ResourceGroup = $($ResourceGroup.ResourceGroupName) `t ResourceName = $($res.Name) `t TagKey= $($key) `t Value = $($tags.Properties.TagsProperty.Item($($key)))"
            }
        }
    }

$Output | Export-Csv -Path c:\PS\newtesttags.csv -NoClobber -NoTypeInformation -Append -Encoding UTF8 -Force
}
