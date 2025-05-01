############################################################################################################################
########## Install Modules
############################################################################################################################
$modules = @("AzureAD", "Microsoft.Graph.Groups", "Microsoft.Graph.Applications")

foreach ($module in $modules) {
    if (-not (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)) {
        Write-Host "$module is not installed. Installing..."
        try {

            Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host "$module installed successfully."

        } catch {

            Write-Host "Failed to install $module. Error: $_.Exception.Message"
        }
    } else {
        Write-Host "$module is already installed."
    }
}

############################################################################################################################
########## Connect to the Entra
############################################################################################################################
 
Connect-AzureAD
 
############################################################################################################################
########## Defining App Registration Details
############################################################################################################################
 
$appName = 'IT Glue Integration' # Update the name as per your naming convention
 
$redirectUri = Read-Host "Enter your redirect URI link (https://yoursudomain.itglue.com/microsofts)"
 
$signInAudience = 'AzureADandPersonalMicrosoftAccount'
 
############################################################################################################################
######### API Permissions
############################################################################################################################
 
$permissions = @(
 
    'AuditLog.Read.All',
    'DeviceManagementManagedDevices.Read.All',
    'Directory.Read.All',
    'Directory.ReadWrite.All',
    'Reports.Read.All',
    'User.Read.All'
)
 
############################################################################################################################
######### Creating App registration
############################################################################################################################
 
# create a new application
 
$app = New-AzureADMSApplication -DisplayName $appName -SignInAudience $signInAudience

Start-Sleep -Seconds 30 #Buffer time to create the app

$obj_id = (Get-AzureADApplication -Filter "AppId eq '$($app.AppId)'").ObjectId

try{
    Set-AzureADMSApplication -ObjectId $obj_id -Web @{RedirectUris=$redirectUri}
}
catch{
    Start-Sleep -Seconds 30 #Buffer time to create the app
    Set-AzureADMSApplication -ObjectId $obj_id -Web @{RedirectUris=$redirectUri}
}

$sp_app = New-AzureADServicePrincipal -AppId $($app.AppId)

############################################################################################################################
######### Microsoft Partner Center API permission
############################################################################################################################
try{
    
    Write-Host "Getting Microsoft Partner Center API permissions" -ForegroundColor Cyan
    $MPC = @{
       resourceAppId = "fa3d9a0c-3fb0-42cc-9193-47c7ecd2edbd"
       resourceAccess = @(
            @{
                id = "1cebfa2a-fb4d-419e-b5f9-839b4383e05a"
                type = "Scope"
            }
        )
    }
}
catch{

    Write-Host "Microsoft Partner Center permission not found" -ForegroundColor Red

}

############################################################################################################################
######### clearing array if need to re-run the script
############################################################################################################################

$RA = @()

############################################################################################################################
######### Delegated API permissions
############################################################################################################################
$graph = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'")


try{

    Write-Host "Getting the permission ID for Delegated API permissions" -ForegroundColor Cyan
    Foreach($permission in $permissions){
 
        $delper = $graph.Oauth2Permissions | Where-Object {$_.Value -eq "$permission"}

        $RA += @(  
    
            @{

                    id = $delper.Id
                    Type = "Scope"

                 }
            )

        }
}
catch{

    Write-Host "Issues fetching $pemissions" -ForegroundColor Red

}

############################################################################################################################
######### # Application API permissions
############################################################################################################################
try{

    Write-Host "Getting the permission ID for Application API permissions" -ForegroundColor Cyan

    Foreach($permission in $permissions){
 
        $appper = $graph.AppRoles | Where-Object {$_.Value -eq "$permission" -and $_.AllowedMemberTypes -contains "Application"}

        $RA += @(  
    
            @{

                    id = $appper.Id
                    Type = "Role"

                 }
        )

    }
}
catch{

    Write-Host "Issues fetching $pemissions" -ForegroundColor Red

}

############################################################################################################################
######### Declaring APi permissions
############################################################################################################################

$RequiredRA = @{
        
            ResourceAppId = "00000003-0000-0000-c000-000000000000"
            ResourceAccess = @($RA)
}

############################################################################################################################
######### Appending all API permissions to an Array
############################################################################################################################
 
$RequiredResourceAccess = @{ 
  params = @($RequiredRA,$MPC)
}

Write-Host "Propagating changes!" -ForegroundColor Yellow

Start-Sleep -Seconds 30 #Buffer time to create the app

try{
    Connect-Graph
    Update-MgApplication -ApplicationId $obj_id -RequiredResourceAccess $RequiredResourceAccess.params

}
catch{
    
    Write-Host "Unable to add the Microsoft Graph API permission: $_.Exception.Message"
}

############################################################################################################################
######### Grant Admin Consent to the API permissions
############################################################################################################################

$URL = "https://login.microsoftonline.com/$((Get-AzureADTenantDetail).ObjectId)/adminconsent?client_id=$($app.AppId)"

Write-Host "Please log in as your tenant admin to accept the permission to Grant Admin consent for the API permissions (Note: No need to login into IT Glue or ignore the error in IT Glue)" -ForegroundColor Cyan

Start-Sleep -Seconds 20 #Buffer time to add a permission

Start-Process $URL

################################### creating Secret key #############################################

$PCreds = Add-MgApplicationPassword -PasswordCredential @{ displayName = 'IT Glue'} -ApplicationId $obj_id

                       #################################################################
################################    Creating Security Groups      ###############################################
                       #################################################################

Write-Host "Create a security Group GDAP-ITG" -ForegroundColor Yellow

try{
    $GDAP_Grp = New-MgGroup -DisplayName 'GDAP-ITG' -MailEnabled:$False  -MailNickName 'GDAP-ITG' -SecurityEnabled
}
catch{
 Write-Host "Having issues creating a security group - Needs to be created manually"
}

                       #################################################################
################################    Assigning Security Group to the Service Principle     ###############################################
                       #################################################################
    
 try{

    $appRoleAssignment = @{
        "principalId"= "$($GDAP_Grp.Id)"
        "resourceId"= "$((Get-AzureADServicePrincipal -Filter "AppID eq '$($app.AppId)'").ObjectId)"
        "appRoleId"= "00000000-0000-0000-0000-000000000000"
    }

    New-MgGroupAppRoleAssignment -GroupId $($GDAP_Grp.Id) -BodyParameter $appRoleAssignment

}
catch{

    Write-Host "Unable to assign the GDAP security to the service principle" -ForegroundColor Red
}

##########################################################################################################################################

Write-Host "################################   Enter the Creds below in IT Glue   ###############################################"

Write-Host "Tenant ID: $((Get-AzureADTenantDetail).ObjectId)" -ForegroundColor Green
Write-Host "Application ID: $($app.AppId)" -ForegroundColor Green
Write-Host "Secret Key: $($PCreds.SecretText)" -ForegroundColor Green

Write-Host "You still need to create a Service Account User and add a relationship for all the Customer Tenants: https://help.itglue.kaseya.com/help/Content/1-admin/microsoft/microsoft-gdap.html?Highlight=Microsoft%20integration%20GDAP"
