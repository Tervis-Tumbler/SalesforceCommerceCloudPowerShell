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
        [Parameter(Mandatory)][String]$customer_no,
        [Parameter(Mandatory)][String]$list_id
    )
    $URL = "https://$Script:SCCAPIRoot/s/-/dw/data/v18_3/customer_lists/$list_id/customers/$customer_no"

    Invoke-SCCAPIFunction -URL $URL -Method Get -APIName data
}

function Get-SCCShopCustomer {
    param (
        [Parameter(Mandatory)][String]$customer_id,
        [Parameter(Mandatory)][String]$SiteName,
        [String]$expand
    )
    $QueryString = @{expand = $expand} | ConvertTo-URLEncodedQueryStringParameterString
    $URL = "https://$Script:SCCAPIRoot/s/$SiteName/dw/shop/v18_3/customers/$($customer_id)?$QueryString"

    Invoke-SCCAPIFunction -URL $URL -Method Get -APIName shop
}

function Get-SCCDataCustomerSearchResult {
    param (
        [Parameter(Mandatory)][String]$customer_list_id,
        [Parameter(Mandatory)][String]$email
    )    
    $URL = "https://$Script:SCCAPIRoot/s/-/dw/data/v18_3/customer_lists/$customer_list_id/customer_search"
    $Body = New-SCCSearchRequest -query (
        New-SCCTermQuery -Fields email -Operator is -Values $email
    ) |
    ConvertTo-Json -Depth 100

    Invoke-SCCAPIFunction -URL $URL -Body $Body -Method Post -APIName data
}

function Invoke-SCCAPIFunction {
    param (
        [Parameter(Mandatory)]$URL,
        $Body,
        [Parameter(Mandatory)]$Method,
        [Validateset("data","shop")][Parameter(Mandatory)]$APIName
    )
    $GrantType = if($APIName -eq "data") {
        "APIClient"
    } elseif ($APIName -eq "shop") {
        "BusinessManagerUser"
    }
    $AccessToken = Get-SCCOAuthAccessToken -GrantType $GrantType

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
        [Parameter(Mandatory,ParameterSetName="SiteName")]$SiteName,
        [Parameter(ParameterSetName="NoSiteName")][Switch]$NoSiteName,
        $Resource
    )
    $SiteURLPart = if($SiteName){"s/$SiteName/"} elseif (-not $NoSiteName) {"s/-/"}

    "https://$Script:SCCAPIRoot/$($SiteURLPart)dw/$APIName/v$Version/$Resource"
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