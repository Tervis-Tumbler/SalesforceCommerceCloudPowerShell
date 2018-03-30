function Get-SCCAPIRootURL {
    $Script:SCCAPIRoot
}

function Set-SCCAPIRootURL {
    param (
        [Parameter(Mandatory)]$SCCAPIRoot
    )
    $Script:SCCAPIRoot = $SCCAPIRoot
}

function Get-SCCAPIClientCredential {
    $Script:SCCAPIClientCredential
}

function Set-SCCAPIClientCredential {
    param (
        [Parameter(Mandatory)]$Credential
    )
    $Script:SCCAPIClientCredential = $Credential
}

function Get-SCCAPIBusinessManagerUserCredential {
    $Script:SCCAPIBusinessManagerUserCredential
}

function Set-SCCAPIBusinessManagerUserCredential {
    param (
        [Parameter(Mandatory)]$Credential
    )
    $Script:SCCAPIBusinessManagerUserCredential = $Credential
}

function New-SCCSearchRequest {
    param (
        [ValidateRange(1,200)][Int]$count,
        [String]$expand,
        [Parameter(Mandatory)]$query,
        [String]$select,
        $sort,
        [ValidateScript({$_ -gt 1})][int]$start
    )
    $PSBoundParameters | ConvertFrom-PSBoundParameters
}

function New-SCCTermQuery {
    param (
        [Parameter(Mandatory)][String[]]$Fields,
        [ValidateSet("is","one_of","is_null","is_not_null","less","greater","not_in","neq")]
        [Parameter(Mandatory)][String]$Operator,
        [String[]]$Values
    )
    [PSCustomObject]@{
        term_query = [PSCustomObject]@{
            fields = $Fields
            operator = $Operator
        } | 
        Where-Object {$Values} |
        Add-Member -MemberType NoteProperty -Name values -Value $Values -PassThru
    }
}

function Get-SCCDataCustomerListCustomer {
    param (
        [Parameter(Mandatory)][String]$customer_id,
        [Parameter(Mandatory)][String]$list_id
    )
    $URL = "https://$Script:SCCAPIRoot/s/-/dw/data/v18_3/customer_lists/$list_id/customers/$customer_id"

    Invoke-SCCAPIFunction -URL $URL -Method Get
}

function Get-SCCShopCustomer {
    param (
        [Parameter(Mandatory)][String]$customer_id
    )
    $URL = "https://$Script:SCCAPIRoot/s/-/dw/shop/v18_3/customers/$customer_id"

    Invoke-SCCAPIFunction -URL $URL -Method Get
}

function Get-SCCDataCustomerSearchResult {
    param (
        [String]$customer_list_id,
        [String]$email
    )    
    $URL = "https://$Script:SCCAPIRoot/s/-/dw/data/v18_3/customer_lists/$customer_list_id/customer_search"
    $Body = New-SCCSearchRequest -query (
        New-SCCTermQuery -Fields email -Operator is -Values $email
    ) |
    ConvertTo-Json -Depth 100

    Invoke-SCCAPIFunction -URL $URL -Body $Body -Method Post
}

function Invoke-SCCAPIFunction {
    param (
        [Parameter(Mandatory)]$URL,
        [Parameter(Mandatory)]$Body,
        $Method,
        [ValidatesSet("data","shop")][Parameter(Mandatory)]$APIName
    )
    $AccessToken = Get-SCCOAuthAccessToken -GrantType

    Invoke-RestMethod -Uri $URL -Method $Method -Headers @{ 
        "x-dw-client-id" = $Script:SCCAPIClientCredential.UserName
        Accept = "application/json"
        Authorization = $AccessToken | ConvertTo-HttpBasicAuthorizationHeaderValue
        Origin = "http://www.tervis.com"
    }  -Body $Body -UseBasicParsing -ContentType "application/json; charset=utf-8"
}

function Get-SCCAPIURL {
    param (
        [ValidatesSet("data","shop")][Parameter(Mandatory)]$APIName,
        [ValidatesSet("16_9","18_3")][Parameter(Mandatory)]$Version,
        [Parameter(Mandatory)]$SiteName
    )

    "https://$Script:SCCAPIRoot/$(if($SiteName){"s/$SiteName/"})dw/$APIName/v$Version/"
}

function Get-SCCOAuthAccessToken {
    param (
        [ValidateSet("APIClient","BusinessManagerUser")][Parameter(Mandatory)]$GrantType
    )

    if ($GrantType -eq "APIClient") {
        $URI = "https://account.demandware.com/dw/oauth2/access_token"
        $GrantTypeValue = "client_credentials"
        $Authorization = $Script:SCCAPIClientCredential | 
            ConvertTo-HttpBasicAuthorizationHeaderValue -Type Basic
    } elseif ($GrantType -eq "BusinessManagerUser") {
        $URI = "https://$($Script:SCCAPIRoot)/dw/oauth2/access_token?client_id=$($Script:SCCAPIClientCredential.UserName)"
        $GrantTypeValue = "urn:demandware:params:oauth:grant-type:client-id:dwsid:dwsecuretoken"
        $Authorization = 
            New-SCCAuthAccessTokenBusinessManagerUserAuthorizationHeaderValue -APIClientCredential $Script:SCCAPIClientCredential -BusinessManagerUserCredential $Script:SCCAPIBusinessManagerUserCredential
    }

    Invoke-RestMethod -Uri $URI -Method Post -Headers @{
        "x-dw-client-id" = $Script:SCCAPIClientCredential.UserName
        "Accept" = "application/json"
        "Authorization" = $Authorization
    }  -Body "grant_type=$GrantTypeValue" -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
}

function ConvertTo-HttpBasicAuthorizationHeaderValue {
    [CmdletBinding(DefaultParameterSetName="OAuthAccessToken")]  
    param (
        [Parameter(Mandatory,ValueFromPipeline,ParameterSetName="Credential")]
        [PSCredential]
        $Credential,
        
        [Parameter(ParameterSetName="Credential")]
        $Type,
        
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName="OAuthAccessToken")]
        $Access_Token,
        
        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName="OAuthAccessToken")]
        $Token_Type
    )
    process {
        $Value = if ($Credential) {
            [System.Convert]::ToBase64String(
                [System.Text.Encoding]::UTF8.GetBytes(
                    $Credential.UserName + ":" + $Credential.GetNetworkCredential().password
                )
            )
        } elseif ($Access_Token) {
            $Access_Token
        }

        if ($Token_Type) { $Type = $Token_Type }

        "$(if($Type){"$Type "})$Value"
    }
}

function New-SCCAuthAccessTokenBusinessManagerUserAuthorizationHeaderValue {
    param (
        [Parameter(Mandatory)][PSCredential]$APIClientCredential,
        [Parameter(Mandatory)][PSCredential]$BusinessManagerUserCredential
    )
    process {
        $Base64String = [System.Convert]::ToBase64String(
                [System.Text.Encoding]::UTF8.GetBytes(
                    $BusinessManagerUserCredential.UserName + 
                    ":" + 
                    $BusinessManagerUserCredential.GetNetworkCredential().password +
                    ":" + 
                    $APIClientCredential.GetNetworkCredential().password
                )
            )
        "Basic $Base64String"
    }
}

function New-SalesForceCommerceCloudFromSwaggerModule {

    $params = @{
      # Download the Open API v2 Specification from this location
      SpecificationUri = 'https://raw.githubusercontent.com/mobify/commercecloud-ocapi-client/develop/swagger.json'
      # Output the generated module to this path
      Path           = 'C:\GeneratedModules\'
      # Name of the generated module
      Name           = 'SalesForceCommerceCloudFromSwagger'
    }
}

function Invoke-SCCOpenCommerceAPISettingsAnalysis {
    param (
        [ValidateSet(
            "Production-Data*","Development-Data*","Development-Shop*"
        )]
        $Filter,
        $Path
    )
    $Files = gci $Path -Filter $Filter
    $GlobalSettings = $files | % {$_ | Get-Content | ConvertFrom-Json}
    $GlobalSettings.clients.resources.resource_id | select -Unique
    $AllUniqueResources = $GlobalSettings.clients.resources.resource_id | select -Unique
    Compare-Object $AllUniqueResources $GlobalSettings[0].clients.resources.resource_id
}