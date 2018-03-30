Import-Module -Force SalesforceCommerceCloudPowerShell

Describe "SalesforceCommerceCloudPowerShell" {    
    It "ConvertTo-HttpBasicAuthorizationHeaderValue Credential" {
        $UserName = "ClientID"
        $Password = "MyPassword" | ConvertTo-SecureString -asPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($UserName,$Password)

        $Credential | 
        ConvertTo-HttpBasicAuthorizationHeaderValue -Type Basic |
        Should -BeExactly "Basic Q2xpZW50SUQ6TXlQYXNzd29yZA=="
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

    It "New-SCCAuthAccessTokenBusinessManagerUserAuthorizationHeaderValue" {
        $UserName = "ClientID"
        $Password = "MyPassword" | ConvertTo-SecureString -asPlainText -Force
        $APIClientCredential = New-Object System.Management.Automation.PSCredential($UserName,$Password)

        $UserName = "BusinessManagerUserName"
        $Password = "OtherPassword" | ConvertTo-SecureString -asPlainText -Force
        $BusinessManagerUserCredential = New-Object System.Management.Automation.PSCredential($UserName,$Password)

        New-SCCAuthAccessTokenBusinessManagerUserAuthorizationHeaderValue -APIClientCredential $APIClientCredential -BusinessManagerUserCredential $BusinessManagerUserCredential | 
        Should -BeExactly "Basic QnVzaW5lc3NNYW5hZ2VyVXNlck5hbWU6T3RoZXJQYXNzd29yZDpNeVBhc3N3b3Jk"
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