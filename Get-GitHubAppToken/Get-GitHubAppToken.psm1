<#
    .Synopsis
    Outputs an access token for a given GitHub App

    .Description
    Generates an access token for a specific GitHub app specified by App ID using a private key as authentication and then outputs it as a string.

    .Parameter AppId
    The six-digit App ID of the GitHub App.

    .Parameter PrivateKey
    A private key of the above-specified GitHub App as a multiline string including all start and end sequences. 

    .Example
    $privateKey = @'
    -----BEGIN RSA PRIVATE KEY-----
    MIICXQIBAAKBgQCPmFkCDewi29SCo/QRvT5tne1bIXrHeVix5Uc5dMNp2PTyCaz9
    cqOKo91uk/GtIKqPpIL6bpfx/9mtjPH1hNNSnGdM8uSDNME+SqRgpDL2mW+AxHbD
    bfDBuk4iVafDq/Idkly7Ag6rvabFIRHWk9kxW55VzkSlYRZ1vL0UX6DHPwIDAQAB
    AoGAcs6Nq5TSDXTRTbokM+KofR/dXBVCgyXEAkecUJXIf2JVRQbzZpg3pWsqaXSj
    r5YEiGAx0GSH25aBxb6A3ZnbEmZf3TDrrg7i+nkDdQ2L7sg0QUNfnBwgVKodb61/
    B8TMIxrhZ67NVUv4+0bin0W3ZFjlG/F8/OUAz7aKKf9bqWECQQDbL4wvVUOzww9l
    d+RY7ga/TiuFpxmrf303hLETvwEUfjohIYOndsgrBtiECkZ56hbUKDGVdfN9Uodg
    3Zvw66+3AkEAp7aWYbRxX8jkroXaprR0tnCrV7lRi4F0dPC77PkZ987/RCTMRzs1
    Ar1v/XQwvatlxGr8/ylci/EXQVWiCA+UuQJBAICstzWKbsZ3evBspAd5JUjl0TMT
    WESQAai4I2SeOzoWqHWOwUVsvDJWQIGzrpAf1usR9ZnyttEZxBQfxU54bp0CQAw4
    MnbF9ei7s2W/3PF+fm54gRNwLi/S69BFZfvbHng+vbySTcv21WLwuIMn/xEittR7
    0xkoQ1Ty6PXarmaV9AkCQQDX1c6SSYqyhQ3Kg/JeetWH5mlxP0vJ/L5mzhB5cdSt
    A37E6+ML9sHFJMbNnw8f93qSpyNp8Q5q2NtY5jvoAVi4
    -----END RSA PRIVATE KEY-----
    '
    Get-GitHubAppToken -AppId 123456 -PrivateKey $privateKey
#>

Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name 'jwtps' -AllowClobber -Force
Import-Module -Name 'jwtps'

function Get-GithubAppToken {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AppId,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$PrivateKey
    )
    #Generate encryption parameters needed for jwt creation
    $encryption = [jwtTypes+encryption]::SHA256
    $algorithm = [jwtTypes+algorithm]::RSA
    $alg = [jwtTypes+cryptographyType]::new($algorithm, $encryption)
    $payload = @{       
        iss = $AppId
        iat = ([System.DateTimeOffset]::Now.AddMinutes(-1)).ToUnixTimeSeconds() #go one minute back to accomodate for time drift
        exp = ([System.DateTimeOffset]::Now.AddMinutes(3)).ToUnixTimeSeconds() #token is not needed for long, since it is only used to get the GitHub token which is valid for much longer
    }
    #Generate jwt which is then used to get GH Token via API
    $jwt = New-JWT -Secret $PrivateKey -Algorithm $alg -Payload $payload

    #Create header for GitHub API
    $header = @{
        'Authorization'          = "Bearer $jwt"
        'Accept'       = 'application/vnd.github+json'
    }
    #Get GitHub access token
    $accessTokenUrl = ((Invoke-WebRequest -Headers $header -Method Get -Uri https://api.github.com/app/installations).Content | ConvertFrom-Json).access_tokens_url
    $accessToken  = ((Invoke-WebRequest -Headers $header -Method Post -Uri $accessTokenUrl).Content | ConvertFrom-Json).token
    
    return $accessToken
}

Export-ModuleMember -Function Get-GithubAppToken
