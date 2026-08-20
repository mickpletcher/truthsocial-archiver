[CmdletBinding()]
param(
    [string]$ProfilesPath,
    [string]$OutputRoot,
    [string]$SourceUrl = 'https://ix.cnn.io/data/truth-social/truth_archive.json'
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

$Profile = [pscustomobject]@{
    AccountId   = '107780257626128497'
    Username    = 'realDonaldTrump'
    DisplayName = 'Donald J. Trump'
    Url         = 'https://truthsocial.com/@realDonaldTrump'
    Key         = 'realdonaldtrump'
}

function Get-ConfiguredProfile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Profile file not found: $Path"
    }

    $entries = @(
        Get-Content -LiteralPath $Path |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith('#') } |
            Select-Object -Unique
    )

    if ($entries.Count -ne 1) {
        throw "Exactly one profile must be configured in $Path."
    }

    $entry = $entries[0]
    $supportedEntries = @(
        '107780257626128497'
        '@realDonaldTrump'
        'realDonaldTrump'
        'https://truthsocial.com/@realDonaldTrump'
    )

    if ($supportedEntries -notcontains $entry) {
        throw "This archive supports only https://truthsocial.com/@realDonaldTrump."
    }

    $entry
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

function ConvertTo-UtcTimestamp {
    param(
        [Parameter(Mandatory)]
        $Value
    )

    if ($Value -is [datetime]) {
        return $Value.ToUniversalTime().ToString('o')
    }

    ([datetimeoffset]::Parse(
        [string]$Value,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal
    )).ToUniversalTime().ToString('o')
}

function Get-MediaType {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $extension = [IO.Path]::GetExtension(([Uri]$Url).AbsolutePath).ToLowerInvariant()

    if ($extension -in @('.mp4', '.mov', '.webm', '.m4v')) {
        return 'video'
    }

    if ($extension -in @('.mp3', '.m4a', '.wav', '.ogg')) {
        return 'audio'
    }

    'image'
}

function Get-PublicArchive {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $response = Invoke-WebRequest -Uri $Url -Headers @{ Accept = 'application/json' } -TimeoutSec 120
    $contentType = [string]$response.Headers['Content-Type']

    if ($contentType -notmatch 'application/json') {
        throw "Public archive returned unexpected content type '$contentType'."
    }

    $items = @($response.Content | ConvertFrom-Json)
    if ($items.Count -eq 0) {
        throw 'Public archive returned no posts.'
    }

    $seenIds = @{}
    foreach ($item in $items) {
        $id = [string]$item.id
        $urlValue = [string]$item.url

        if (-not $id -or -not $item.created_at -or -not $urlValue) {
            throw 'Public archive contains a post missing id, created_at, or url.'
        }

        if ($urlValue -notmatch '^https://truthsocial\.com/@realDonaldTrump/\d+$') {
            throw "Public archive contains an unexpected post URL: $urlValue"
        }

        if ($seenIds.ContainsKey($id)) {
            throw "Public archive contains duplicate post ID $id."
        }

        $seenIds[$id] = $true
    }

    [pscustomobject]@{
        Items        = $items
        LastModified = [string]$response.Headers['Last-Modified']
    }
}

function ConvertTo-ArchivePost {
    param(
        [Parameter(Mandatory)]
        $Post,

        [Parameter(Mandatory)]
        [string]$ScrapedAt
    )

    $mediaAttachments = @(
        foreach ($mediaValue in @($Post.media)) {
            $mediaUrl = [string]$mediaValue
            if (-not $mediaUrl) {
                continue
            }

            [pscustomobject]@{
                url         = $mediaUrl
                preview_url = $mediaUrl
                type        = Get-MediaType -Url $mediaUrl
                description = $null
            }
        }
    )

    $rawContent = [string]$Post.content

    [pscustomobject]@{
        profile_account_id   = $Profile.AccountId
        profile_username     = $Profile.Username
        profile_display_name = $Profile.DisplayName
        id                   = [string]$Post.id
        created_at           = ConvertTo-UtcTimestamp -Value $Post.created_at
        url                  = [string]$Post.url
        text                 = ConvertFrom-HtmlText -Html $rawContent
        raw_content          = $rawContent
        replies_count        = [int64]$Post.replies_count
        reblogs_count        = [int64]$Post.reblogs_count
        favourites_count     = [int64]$Post.favourites_count
        media_count          = $mediaAttachments.Count
        media_attachments    = $mediaAttachments
        quote_id             = $null
        in_reply_to_id       = $null
        scraped_at           = $ScrapedAt
    }
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
        ForEach-Object { $_ | ConvertFrom-Json -DateKind String }
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

function Add-JsonLines {
    param(
        [AllowEmptyCollection()]
        [array]$Items,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($Items.Count -eq 0) {
        return
    }

    $Items |
        ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 20 -Compress } |
        Add-Content -LiteralPath $Path -Encoding utf8
}

if (-not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}

$configuredProfile = Get-ConfiguredProfile -Path $ProfilesPath
$runAt = (Get-Date).ToUniversalTime().ToString('o')
$postsPath = Join-Path $OutputRoot 'posts.jsonl'
$archiveSummaryPath = Join-Path $OutputRoot 'archive-summary.json'
$existingPosts = @()

try {
    $existingPosts = @(Read-JsonLines -Path $postsPath)

    Write-Host "Downloading public archive from $SourceUrl"
    $publicArchive = Get-PublicArchive -Url $SourceUrl
    $sourcePosts = @(
        foreach ($post in $publicArchive.Items) {
            ConvertTo-ArchivePost -Post $post -ScrapedAt $runAt
        }
    )

    $existingIds = @{}
    foreach ($post in $existingPosts) {
        if ($post.id) {
            $existingIds[[string]$post.id] = $true
        }
    }

    $newPosts = @($sourcePosts | Where-Object { -not $existingIds.ContainsKey([string]$_.id) })
    if ($existingPosts.Count -eq 0) {
        Save-JsonLines -Items $newPosts -Path $postsPath
    }
    else {
        Add-JsonLines -Items $newPosts -Path $postsPath
    }

    $totalPosts = $existingPosts.Count + $newPosts.Count

    $archiveSummary = [pscustomobject]@{
        run_at               = $runAt
        status               = 'ok'
        source_url           = $SourceUrl
        source_last_modified = $publicArchive.LastModified
        profile_count        = 1
        total_posts          = $totalPosts
        new_posts            = $newPosts.Count
        profiles             = @(
            [pscustomobject]@{
                input          = $configuredProfile
                account_id     = $Profile.AccountId
                username       = $Profile.Username
                display_name   = $Profile.DisplayName
                status         = 'ok'
                total_posts    = $totalPosts
                existing_posts = $existingPosts.Count
                fetched_posts  = $sourcePosts.Count
                new_posts      = $newPosts.Count
                message        = $null
            }
        )
    }

    Save-JsonObject -Item $archiveSummary -Path $archiveSummaryPath
    Write-Host "Archived $totalPosts total posts. Added $($newPosts.Count) new posts."
}
catch {
    $message = $_.Exception.Message
    $archiveSummary = [pscustomobject]@{
        run_at               = $runAt
        status               = 'error'
        source_url           = $SourceUrl
        source_last_modified = $null
        profile_count        = 1
        total_posts          = $existingPosts.Count
        new_posts            = 0
        profiles             = @(
            [pscustomobject]@{
                input          = $configuredProfile
                account_id     = $Profile.AccountId
                username       = $Profile.Username
                display_name   = $Profile.DisplayName
                status         = 'error'
                total_posts    = $existingPosts.Count
                existing_posts = $existingPosts.Count
                fetched_posts  = 0
                new_posts      = 0
                message        = $message
            }
        )
    }

    Save-JsonObject -Item $archiveSummary -Path $archiveSummaryPath
    Write-Error "Public archive failed: $message" -ErrorAction Continue
    exit 1
}
