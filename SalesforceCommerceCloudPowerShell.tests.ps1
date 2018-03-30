Import-Module -Force SalesforceCommerceCloudPowerShell

Describe "SalesforceCommerceCloudPowerShell" {    
    It "ConvertTo-HttpBasicAuthorizationHeaderValue Credential" {
        $UserName = "test"
        $Password = "mypassword" | ConvertTo-SecureString -asPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($UserName,$Password)

        $Credential | 
        ConvertTo-HttpBasicAuthorizationHeaderValue -Type Basic |
        Should -BeExactly "Basic dGVzdDpteXBhc3N3b3Jk"
    }

    It "ConvertTo-HttpBasicAuthorizationHeaderValue OAuthAccessToken" {
        $AccessToken = [PSCustomObject][Ordered]@{
            access_token = "3206bd3c-a325-4863-9885-43991a2aadda"
            expires_in = 1799
            scope = "mail"
            token_type = "Bearer"
        }

        $AccessToken | 
        ConvertTo-HttpBasicAuthorizationHeaderValue | 
        Should -BeExactly "Bearer 3206bd3c-a325-4863-9885-43991a2aadda"
    }

    Context "New-SCCSearchRequest" {
        $SearchRequest = New-SCCSearchRequest -Query (
            New-SCCTermQuery -Fields email -Operator is -Values NotAn@Address.com
        )

        It "PSCustomObject" {
            $SearchRequest.query.term_query.fields | should -BeExactly "email"
        }

        It "JSON" {
            $SearchRequest | ConvertTo-Json -Depth 100 | Should -Be @"
{
    "query":  {
                  "term_query":  {
                                     "fields":  [
                                                    "email"
                                                ],
                                     "operator":  "is",
                                     "values":  [
                                                    "NotAn@Address.com"
                                                ]
                                 }
              }
}
"@
        }
    }
}