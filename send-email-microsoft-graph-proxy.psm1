Set-StrictMode -Version Latest

function Send-GraphMail {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FromEmailAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ToEmailAddress,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BodyContent,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Proxy
    )

    $tokenBody = @{
        client_id     = $ClientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    $tokenResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Body $tokenBody `
        -Proxy $Proxy `
        -ErrorAction Stop

    $accessToken = $tokenResponse.access_token
    if (-not $accessToken) {
        throw "Failed to obtain access token."
    }

    $emailBodyObj = @{
        message = @{
            subject = $Subject
            body    = @{
                contentType = "html"
                content     = $BodyContent
            }
            toRecipients = @(
                @{
                    emailAddress = @{
                        address = $ToEmailAddress
                    }
                }
            )
        }
        saveToSentItems = $true
    }

    $emailBodyJson = $emailBodyObj | ConvertTo-Json -Depth 10

    $uri = "https://graph.microsoft.com/v1.0/users/$FromEmailAddress/sendMail"

    if ($PSCmdlet.ShouldProcess("$ToEmailAddress", "Send Graph email from $FromEmailAddress via $uri")) {
        Invoke-RestMethod `
            -Method POST `
            -Uri $uri `
            -Headers @{ Authorization = "Bearer $accessToken" } `
            -ContentType "application/json" `
            -Body $emailBodyJson `
            -Proxy $Proxy `
            -ErrorAction Stop | Out-Null
    }
}

Export-ModuleMember -Function Send-GraphMail