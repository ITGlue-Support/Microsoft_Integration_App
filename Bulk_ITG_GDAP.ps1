############# Complete the pre-requisite ##################
 
$ModuleName = "Microsoft.Graph.Identity.Partner"

if (Get-Module -ListAvailable -Name $ModuleName) {

    Write-Host "Module '$ModuleName' is already installed"

} else {

    Write-Host "Installing module '$ModuleName'..."

    Install-Module -Name $ModuleName -Repository PSGallery -Scope CurrentUser -Force

    Write-Host "Module '$ModuleName' installed successfully"

}

Connect-MgGraph -Scopes "DelegatedAdminRelationship.ReadWrite.All" #Get the Access token
 
############# Assign security group to the approved realtionship ##################
function access_assign {



    Write-Host "Please make sure that the relationship is approved for all the relationship listed in the CSV"

    $path = Read-Host "Enter the file path of the CSV file containing relationships ID"

    $group_id = Read-Host "Enter Object ID of the security group to bulk assign group"
 
    $ril_csv = Import-Csv -Path $path

    $params = @{
	    accessContainer = @{
		    accessContainerId = "$group_id"
		    accessContainerType = "securityGroup"
	        }
            accessDetails = @{
            unifiedRoles = @(
                @{ roleDefinitionId = "e8611ab8-c189-46e8-94e1-60213ab1f814" }
                @{ roleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7" }
                @{ roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451" }
                @{ roleDefinitionId = "3a2c62db-5318-420d-8d74-23affee5d9d5" }
                @{ roleDefinitionId = "31e939ad-9672-4796-9c2e-873181342d2d" }
                @{ roleDefinitionId = "4a5d8f65-41da-4de4-8968-e035b65339cf" }
            )
        }
    }

    foreach ($data in $ril_csv){

        if ($($data.Id) -ne $null) {


        try{

            New-MgTenantRelationshipDelegatedAdminRelationshipAccessAssignment -DelegatedAdminRelationshipId $($data.Id) -BodyParameter $params -ErrorAction Stop

        }
        catch{
        
            Write-Error "Error occured when adding the security group. Error: $($_.exception.message)"
        
            }

        }
    }
}

############# list of the relationship Pending ###########

function relationship_id_list {
  
  $ril = Get-MgTenantRelationshipDelegatedAdminRelationship | Where-Object {$_.Status -eq 'approvalPending'}

  if ($ril -ne $null) {

    $newcsv = {} | Select-Object 'Id', 'DisplayName','Status','Invitation_URL' | Export-Csv -NoTypeInformation Customer_relationship.csv

          foreach ($id in $ril){

            $id | select @{N="Id";E={$id.Id}},@{N="DisplayName";E={$($id.DisplayName)}},@{N="Status";E={$($id.Status)}},@{N="Invitation_URL";E={"https://admin.microsoft.com/AdminPortal/Home#/partners/invitation/granularAdminRelationships/$($id.Id)"}} | export-CSV Customer_relationship.csv -Append -NoTypeInformation
        }

    }

}
 
############# Add the GDAP relationship ##################
function req_gdap {
 
    $path = Read-Host "Enter the file path of the Customer list CSV file"
 
    $CSVData = Import-Csv -Path $path
 
    foreach ($data in $CSVData){
 
$params = @{
    displayName = "ITG-" + "$($data.DisplayName)"
    duration    = "P730D"
    customer    = @{
        tenantId = "$($data.TenantId)"   # <-- customer tenant ID here
    }
    accessDetails = @{
        unifiedRoles = @(
            @{ roleDefinitionId = "e8611ab8-c189-46e8-94e1-60213ab1f814" }
            @{ roleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7" }
            @{ roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451" }
            @{ roleDefinitionId = "3a2c62db-5318-420d-8d74-23affee5d9d5" }
            @{ roleDefinitionId = "31e939ad-9672-4796-9c2e-873181342d2d" }
            @{ roleDefinitionId = "4a5d8f65-41da-4de4-8968-e035b65339cf" }
        )
    }
    autoExtendDuration = "P180D"
}
 if (-not [string]::IsNullOrEmpty($data.TenantId)){
    try{

        Write-Host "$params"
 
        New-MgTenantRelationshipDelegatedAdminRelationship -BodyParameter $params -ErrorAction Stop
 
        Write-Host "Relationship was successfully created! You still need to manually approve each relationship, by logging as a Admin user of the respective tenant"

        
    }
    catch {
 
        Write-Host "Error Occured when creating relationship for the Tenant: $($CSVData.DisplayName). Error: $($_.exception.message)" -ForegroundColor Red
 
    }

    relationship_id_list
}


 
}


 
}
 
############# Get the list of the customer ##################
 
function get_cust {
 
 
    Write-Host "Getting the list of the Partner Center Customers"
    try{
 
        $list_cust = Get-MgTenantRelationshipDelegatedAdminCustomer
    }catch{
        Write-Host "Error Occured when pulling the customer's list. Error: $($_.exception.message)" -ForegroundColor Red
    }
 
    If ($list_cust -ne $null){
 
        $newcsv = {} | Select-Object 'TenantId', 'DisplayName' | Export-Csv -NoTypeInformation GDAP_Customer.csv
 
        Write-Host "Creating a CSV file"
 
        foreach ($cust in $list_cust){
            $cust | select @{N="TenantID";E={$cust.TenantId}},@{N="DisplayName";E={$($cust.DisplayName)}} | export-CSV GDAP_Customer.csv -Append -NoTypeInformatio
        }
    }

    Write-Host "Done creating the list of all the customer list. You can alter the list to keep the customer you want to sync."
}
 
#################--Main---##############################
 
$options = Read-Host "Please select from the options below:
		1. Get the list of the Partner Center Customer.
		2. Bulk Request relationship for the Customer in the list.
		3. Assign Security group to the approved Partner.
"
 
Switch ($options){
 
    1 {get_cust}
 
    2 {req_gdap}
 
    3 {access_assign}
 
}