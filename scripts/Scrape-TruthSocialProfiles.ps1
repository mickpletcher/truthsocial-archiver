[CmdletBinding()]
param(
    [string]$ProfilesPath,
    [string]$OutputRoot,
    [int]$MaxPages = 0,
    [int]$Limit = 0,
    [int]$RequestDelaySeconds = 1,
    [switch]$IncludeReplies
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not $ProfilesPath) {
    $ProfilesPath = Join-Path $RepoRoot 'config/profiles.txt'
}

if (-not $OutputRoot) {
    $OutputRoot = Join-Path $RepoRoot 'docs/data'
}

$ProfilesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilesPath)
$OutputRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputRoot)

$Headers = @{
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36'
    'Accept'     = 'application/json'
}

$HtmlHeaders = @{
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36'
    'Accept'     = 'text/html'
}

function Invoke-TruthSocialApi {
    param(
        [Parameter(Mandatory)]
        [string]$Uri
    )

    try {
        Invoke-RestMethod -Uri $Uri -Headers $Headers -TimeoutSec 60
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode) {
            throw "Truth Social request failed with HTTP $statusCode`: $Uri"
        }

        throw "Truth Social request failed: $($_.Exception.Message) [$Uri]"
    }
}

function Get-ProfileEntries {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Profile file not found: $Path"
    }

    Get-Content -LiteralPath $Path |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        Select-Object -Unique
}

function ConvertTo-ProfileKey {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    ($Value.ToLowerInvariant() -replace '[^a-z0-9_-]+', '-').Trim('-')
}

function ConvertFrom-HtmlText {
    param(
        [AllowNull()]
        [string]$Html
    )

    if (-not $Html) {
        return ''
    }

    $withoutTags = $Html -replace '<br\s*/?>', ' ' -replace '</p>', ' ' -replace '<[^>]+>', ' '
    $decoded = [System.Net.WebUtility]::HtmlDecode($withoutTags)
    ($decoded -replace '\s+', ' ').Trim()
}

function Get-ProfileToken {
    param(
        [Parameter(Mandatory)]
        [string]$Entry
    )

    if ($Entry -match '^\d+$') {
        return @{
            Type  = 'Id'
            Value = $Entry
        }
    }

    if ($Entry -match '^https?://') {
        $uri = [Uri]$Entry
        $path = $uri.AbsolutePath.Trim('/')

        if ($path -match '^@([^/]+)$') {
            return @{
                Type  = 'Handle'
                Value = $Matches[1]
            }
        }

        if ($path -match 'accounts/(\d+)') {
            return @{
                Type  = 'Id'
                Value = $Matches[1]
            }
        }

        throw "Unsupported profile URL format: $Entry"
    }

    return @{
        Type  = 'Handle'
        Value = $Entry.TrimStart('@')
    }
}

function Resolve-TruthSocialProfile {
    param(
        [Parameter(Mandatory)]
        [string]$Entry
    )

    $token = Get-ProfileToken -Entry $Entry

    if ($token.Type -eq 'Id') {
        try {
            $account = Invoke-TruthSocialApi -Uri "https://truthsocial.com/api/v1/accounts/$($token.Value)"
        }
        catch {
            return [pscustomobject]@{
                Input       = $Entry
                AccountId   = $token.Value
                Username    = $token.Value
                Acct        = $token.Value
                DisplayName = $token.Value
                Url         = "https://truthsocial.com/api/v1/accounts/$($token.Value)"
                Key         = ConvertTo-ProfileKey -Value $token.Value
            }
        }
    }
    else {
        $escapedHandle = [Uri]::EscapeDataString($token.Value)

        try {
            $account = Invoke-TruthSocialApi -Uri "https://truthsocial.com/api/v1/accounts/lookup?acct=$escapedHandle"
        }
        catch {
            try {
                $matches = Invoke-TruthSocialApi -Uri "https://truthsocial.com/api/v1/accounts/search?q=$escapedHandle&limit=10"
                $account = @($matches) | Where-Object {
                    $_.username -eq $token.Value -or $_.acct -eq $token.Value -or $_.acct -eq "@$($token.Value)"
                } | Select-Object -First 1
            }
            catch {
                return Resolve-TruthSocialProfileFromPage -Entry $Entry -Handle $token.Value
            }

            if (-not $account) {
                return Resolve-TruthSocialProfileFromPage -Entry $Entry -Handle $token.Value
            }
        }
    }

    if (-not $account.id) {
        throw "Resolved profile '$Entry' did not include an account ID."
    }

    [pscustomobject]@{
        Input       = $Entry
        AccountId   = [string]$account.id
        Username    = [string]$account.username
        Acct        = [string]$account.acct
        DisplayName = ConvertFrom-HtmlText -Html ([string]$account.display_name)
        Url         = [string]$account.url
        Key         = ConvertTo-ProfileKey -Value $(if ($account.username) { $account.username } else { $account.id })
    }
}

function Resolve-TruthSocialProfileFromPage {
    param(
        [Parameter(Mandatory)]
        [string]$Entry,

        [Parameter(Mandatory)]
        [string]$Handle
    )

    $profileUrl = "https://truthsocial.com/@$([Uri]::EscapeDataString($Handle))"

    try {
        $response = Invoke-WebRequest -Uri $profileUrl -Headers $HtmlHeaders -TimeoutSec 60
    }
    catch {
        throw "Could not resolve profile '$Entry' through API or public profile page. $($_.Exception.Message)"
    }

    $html = $response.Content
    $accountId = $null
    $displayName = $Handle
    $username = $Handle

    if ($html -match '<title>(.*?)\s+\(@([^)]+)\)</title>') {
        $displayName = ConvertFrom-HtmlText -Html $Matches[1]
        $username = $Matches[2]
    }

    if ($html -match 'accounts/avatars/([0-9/]+)/original') {
        $accountId = ($Matches[1] -split '/') -join ''
    }

    if (-not $accountId) {
        throw "Could not find account ID on public profile page for '$Entry'."
    }

    if ($html -match '<meta property="og:url" content="([^"]+)"') {
        $profileUrl = [System.Net.WebUtility]::HtmlDecode($Matches[1])
    }

    [pscustomobject]@{
        Input       = $Entry
        AccountId   = $accountId
        Username    = $username
        Acct        = $username
        DisplayName = $displayName
        Url         = $profileUrl
        Key         = ConvertTo-ProfileKey -Value $username
    }
}

function Read-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $raw = Get-Content -Raw -LiteralPath $Path
    if (-not $raw.Trim()) {
        return @()
    }

    @($raw | ConvertFrom-Json)
}

function Read-JsonLines {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    Get-Content -LiteralPath $Path |
        Where-Object { $_.Trim() } |
        ForEach-Object { $_ | ConvertFrom-Json }
}

function Read-ArchivePosts {
    param(
        [Parameter(Mandatory)]
        [string]$JsonLinesPath,

        [Parameter(Mandatory)]
        [string]$JsonPath
    )

    if (Test-Path -LiteralPath $JsonLinesPath) {
        return @(Read-JsonLines -Path $JsonLinesPath)
    }

    Read-JsonArray -Path $JsonPath
}

function Save-JsonArray {
    param(
        [AllowEmptyCollection()]
        [array]$Items,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    ConvertTo-Json -InputObject $Items -Depth 20 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Save-JsonObject {
    param(
        [Parameter(Mandatory)]
        $Item,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    ConvertTo-Json -InputObject $Item -Depth 20 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Save-JsonLines {
    param(
        [AllowEmptyCollection()]
        [array]$Items,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if ($Items.Count -eq 0) {
        Set-Content -LiteralPath $Path -Value '' -Encoding utf8
        return
    }

    $Items |
        ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 20 -Compress } |
        Set-Content -LiteralPath $Path -Encoding utf8
}

function Save-CsvPosts {
    param(
        [AllowEmptyCollection()]
        [array]$Items,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $columns = @(
        'profile_username'
        'profile_display_name'
        'profile_account_id'
        'id'
        'created_at'
        'url'
        'text'
        'replies_count'
        'reblogs_count'
        'favourites_count'
        'media_count'
        'quote_id'
        'in_reply_to_id'
        'scraped_at'
    )

    if ($Items.Count -eq 0) {
        ('"' + ($columns -join '","') + '"') | Set-Content -LiteralPath $Path -Encoding utf8
        return
    }

    $Items | Select-Object $columns | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding utf8
}

function ConvertTo-ArchivePost {
    param(
        [Parameter(Mandatory)]
        $Post,

        [Parameter(Mandatory)]
        $Profile
    )

    $mediaAttachments = @($Post.media_attachments)

    [pscustomobject]@{
        profile_account_id   = $Profile.AccountId
        profile_username     = $Profile.Username
        profile_display_name = $Profile.DisplayName
        id                   = [string]$Post.id
        created_at           = [string]$Post.created_at
        url                  = [string]$Post.url
        text                 = ConvertFrom-HtmlText -Html ([string]$Post.content)
        raw_content          = [string]$Post.content
        replies_count        = [int]$Post.replies_count
        reblogs_count        = [int]$Post.reblogs_count
        favourites_count     = [int]$Post.favourites_count
        media_count          = $mediaAttachments.Count
        media_attachments    = $mediaAttachments
        quote_id             = if ($Post.quote_id) { [string]$Post.quote_id } else { $null }
        in_reply_to_id       = if ($Post.in_reply_to_id) { [string]$Post.in_reply_to_id } else { $null }
        scraped_at           = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Merge-Posts {
    param(
        [array]$Existing,
        [array]$New
    )

    @($New + $Existing) |
        Where-Object { $_.id } |
        Group-Object -Property id |
        ForEach-Object { $_.Group | Select-Object -First 1 } |
        Sort-Object -Property @{ Expression = { [datetime]$_.created_at }; Descending = $true }
}

function Get-TruthSocialPosts {
    param(
        [Parameter(Mandatory)]
        $Profile
    )

    $posts = New-Object System.Collections.Generic.List[object]
    $maxId = $null
    $page = 0

    do {
        $page++

        $queryParts = @(
            "exclude_replies=$(if ($IncludeReplies) { 'false' } else { 'true' })"
        )

        if ($Limit -gt 0) {
            $queryParts += "limit=$Limit"
        }

        if ($maxId) {
            $queryParts += "max_id=$([Uri]::EscapeDataString($maxId))"
        }

        $uri = "https://truthsocial.com/api/v1/accounts/$($Profile.AccountId)/statuses?$($queryParts -join '&')"
        Write-Host "Fetching @$($Profile.Username) page $page"

        $response = @(Invoke-TruthSocialApi -Uri $uri)

        if ($response.Count -eq 0) {
            break
        }

        foreach ($post in $response) {
            $posts.Add((ConvertTo-ArchivePost -Post $post -Profile $Profile))
        }

        $oldest = $response | Select-Object -Last 1
        if (-not $oldest.id -or $oldest.id -eq $maxId) {
            break
        }

        $maxId = [string]$oldest.id

        if ($RequestDelaySeconds -gt 0) {
            Start-Sleep -Seconds $RequestDelaySeconds
        }
    } while ($MaxPages -le 0 -or $page -lt $MaxPages)

    $posts.ToArray()
}

if (-not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}

$entries = @(Get-ProfileEntries -Path $ProfilesPath)
if ($entries.Count -eq 0) {
    throw "No profiles found in $ProfilesPath"
}

$allPosts = New-Object System.Collections.Generic.List[object]
$runAt = (Get-Date).ToUniversalTime().ToString('o')
$runProfiles = New-Object System.Collections.Generic.List[object]

foreach ($entry in $entries) {
    Write-Host "Resolving profile: $entry"
    $profile = $null
    $existingProfilePosts = @()
    $newProfilePosts = @()
    $mergedProfilePosts = @()
    $status = 'ok'
    $message = $null

    try {
        $profile = Resolve-TruthSocialProfile -Entry $entry

        $profileRoot = Join-Path $OutputRoot "profiles/$($profile.Key)"
        $profileJsonLinesPath = Join-Path $profileRoot 'posts.jsonl'
        $profileJsonPath = Join-Path $profileRoot 'posts.json'
        $profileCsvPath = Join-Path $profileRoot 'posts.csv'

        $existingProfilePosts = Read-ArchivePosts -JsonLinesPath $profileJsonLinesPath -JsonPath $profileJsonPath
        $newProfilePosts = Get-TruthSocialPosts -Profile $profile
        $mergedProfilePosts = @(Merge-Posts -Existing $existingProfilePosts -New $newProfilePosts)

        Save-JsonLines -Items $mergedProfilePosts -Path $profileJsonLinesPath
        Save-JsonArray -Items $mergedProfilePosts -Path $profileJsonPath
        Save-CsvPosts -Items $mergedProfilePosts -Path $profileCsvPath

        foreach ($post in $mergedProfilePosts) {
            $allPosts.Add($post)
        }

        Write-Host "Archived $($mergedProfilePosts.Count) posts for @$($profile.Username)"
    }
    catch {
        $status = 'error'
        $message = $_.Exception.Message
        Write-Warning "Profile '$entry' failed: $message"
    }

    $runProfiles.Add([pscustomobject]@{
        input                = $entry
        account_id           = if ($profile) { $profile.AccountId } else { $null }
        username             = if ($profile) { $profile.Username } else { $null }
        display_name         = if ($profile) { $profile.DisplayName } else { $null }
        status               = $status
        total_posts          = $mergedProfilePosts.Count
        existing_posts       = $existingProfilePosts.Count
        fetched_posts        = $newProfilePosts.Count
        new_posts            = @($newProfilePosts | Where-Object { $existingProfilePosts.id -notcontains $_.id }).Count
        message              = $message
    })
}

$combinedJsonLinesPath = Join-Path $OutputRoot 'posts.jsonl'
$combinedJsonPath = Join-Path $OutputRoot 'posts.json'
$combinedCsvPath = Join-Path $OutputRoot 'posts.csv'
$existingCombinedPosts = Read-ArchivePosts -JsonLinesPath $combinedJsonLinesPath -JsonPath $combinedJsonPath
$mergedCombinedPosts = @(Merge-Posts -Existing $existingCombinedPosts -New $allPosts.ToArray())

Save-JsonLines -Items $mergedCombinedPosts -Path $combinedJsonLinesPath
Save-JsonArray -Items $mergedCombinedPosts -Path $combinedJsonPath
Save-CsvPosts -Items $mergedCombinedPosts -Path $combinedCsvPath

$archiveSummaryPath = Join-Path $OutputRoot 'archive-summary.json'
$archiveSummary = [pscustomobject]@{
    run_at          = $runAt
    status          = if (@($runProfiles | Where-Object { $_.status -eq 'error' }).Count -gt 0) { 'error' } else { 'ok' }
    profile_count   = $runProfiles.Count
    total_posts     = $mergedCombinedPosts.Count
    new_posts       = [int](@($runProfiles | Measure-Object -Property new_posts -Sum).Sum)
    profiles        = $runProfiles.ToArray()
}

Save-JsonObject -Item $archiveSummary -Path $archiveSummaryPath

Write-Host "Archived $($mergedCombinedPosts.Count) total posts across $($entries.Count) profile entries."

if ($archiveSummary.status -eq 'error') {
    Write-Warning "One or more profile archive runs failed. See $archiveSummaryPath for details."
}
