[CmdletBinding()]
param(
    [string]$ProfilesPath,
    [string]$OutputRoot,
    [string]$SourceUrl = 'https://ix.cnn.io/data/truth-social/truth_archive.json',
    [string]$RepositoryDataUrl = 'https://raw.githubusercontent.com/mickpletcher/truthsocial-archiver/main/docs/data',
    [switch]$UpdateFromSource
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

$ArchiveProfile = [pscustomobject]@{
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
        profile_account_id   = $ArchiveProfile.AccountId
        profile_username     = $ArchiveProfile.Username
        profile_display_name = $ArchiveProfile.DisplayName
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

function Read-JsonLine {
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

function Save-JsonLine {
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

function Add-JsonLine {
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

function ConvertFrom-WebContent {
    param(
        [Parameter(Mandatory)]
        $Content
    )

    if ($Content -is [byte[]]) {
        return [Text.Encoding]::UTF8.GetString($Content)
    }

    [string]$Content
}

function Get-JsonLineCount {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    $count = 0L
    foreach ($line in [IO.File]::ReadLines($Path)) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $count++
        }
    }

    $count
}

function Get-RepositoryArchiveSummary {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $response = Invoke-WebRequest -Uri $Url -Headers @{
        Accept          = 'application/json'
        'Cache-Control' = 'no-cache'
    } -TimeoutSec 120
    $content = ConvertFrom-WebContent -Content $response.Content
    $summary = $content | ConvertFrom-Json -DateKind String

    if ($summary.status -ne 'ok') {
        throw "Repository archive summary reported status '$($summary.status)'."
    }

    if (-not $summary.run_at) {
        throw 'Repository archive summary is missing run_at.'
    }

    $totalPosts = 0L
    if (-not [long]::TryParse([string]$summary.total_posts, [ref]$totalPosts) -or $totalPosts -lt 1) {
        throw "Repository archive summary has invalid total_posts '$($summary.total_posts)'."
    }

    $profiles = @($summary.profiles)
    if ($profiles.Count -ne 1 -or [string]$profiles[0].username -ne $ArchiveProfile.Username) {
        throw 'Repository archive summary does not describe @realDonaldTrump.'
    }

    $runAt = [datetimeoffset]::Parse(
        [string]$summary.run_at,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal
    )

    [pscustomobject]@{
        Content    = $content
        RunAt      = $runAt
        TotalPosts = $totalPosts
    }
}

function Test-RepositoryArchiveFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [long]$ExpectedPostCount
    )

    $seenIds = @{}
    $postCount = 0L
    $lineNumber = 0L

    foreach ($line in [IO.File]::ReadLines($Path)) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $post = $line | ConvertFrom-Json -DateKind String
        }
        catch {
            throw "Downloaded repository archive contains invalid JSON on line $lineNumber."
        }

        $id = [string]$post.id
        if (-not $id) {
            throw "Downloaded repository archive contains a post without an ID on line $lineNumber."
        }

        if ([string]$post.url -ne "$($ArchiveProfile.Url)/$id") {
            throw "Downloaded repository archive contains an unexpected post URL on line $lineNumber."
        }

        if ($seenIds.ContainsKey($id)) {
            throw "Downloaded repository archive contains duplicate post ID $id."
        }

        $seenIds[$id] = $true
        $postCount++
    }

    if ($postCount -ne $ExpectedPostCount) {
        throw "Downloaded repository archive contains $postCount posts; expected $ExpectedPostCount."
    }

    $postCount
}

function Sync-RepositoryArchive {
    param(
        [Parameter(Mandatory)]
        [string]$DataUrl,

        [Parameter(Mandatory)]
        [string]$PostsPath,

        [Parameter(Mandatory)]
        [string]$SummaryPath
    )

    $baseUrl = $DataUrl.TrimEnd('/')
    $remoteSummary = Get-RepositoryArchiveSummary -Url "$baseUrl/archive-summary.json"
    $localPostCount = Get-JsonLineCount -Path $PostsPath
    $localRunAt = $null

    if (Test-Path -LiteralPath $SummaryPath) {
        try {
            $localSummary = Get-Content -Raw -LiteralPath $SummaryPath | ConvertFrom-Json -DateKind String
            if ($localSummary.status -eq 'ok' -and $localSummary.run_at) {
                $localRunAt = [datetimeoffset]::Parse(
                    [string]$localSummary.run_at,
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::AssumeUniversal
                )
            }
            else {
                Write-Warning 'The local archive summary is not successful. The repository summary will replace it when the post counts match.'
            }
        }
        catch {
            Write-Warning 'The local archive summary is invalid. The repository summary will replace it.'
        }
    }

    if ($remoteSummary.TotalPosts -lt $localPostCount) {
        Write-Information "Local archive has $localPostCount posts, which is newer than the repository archive with $($remoteSummary.TotalPosts) posts. No files were replaced." -InformationAction Continue
        return
    }

    $downloadPosts = $remoteSummary.TotalPosts -gt $localPostCount -or -not (Test-Path -LiteralPath $PostsPath)
    $updateSummary = $downloadPosts -or -not $localRunAt -or $remoteSummary.RunAt -gt $localRunAt

    if (-not $downloadPosts -and -not $updateSummary) {
        Write-Information "Local archive is current with $localPostCount posts." -InformationAction Continue
        return
    }

    $temporaryId = [guid]::NewGuid().ToString('N')
    $outputDirectory = Split-Path -Parent $PostsPath
    $temporaryPostsPath = Join-Path $outputDirectory ".posts.$temporaryId.tmp"
    $temporarySummaryPath = Join-Path $outputDirectory ".archive-summary.$temporaryId.tmp"

    try {
        if ($downloadPosts) {
            Write-Information "Downloading newer repository archive with $($remoteSummary.TotalPosts) posts." -InformationAction Continue
            Invoke-WebRequest -Uri "$baseUrl/posts.jsonl" -Headers @{
                Accept          = 'application/x-ndjson, application/json, text/plain'
                'Cache-Control' = 'no-cache'
            } -TimeoutSec 120 -OutFile $temporaryPostsPath
            Test-RepositoryArchiveFile -Path $temporaryPostsPath -ExpectedPostCount $remoteSummary.TotalPosts | Out-Null
        }

        [IO.File]::WriteAllText(
            $temporarySummaryPath,
            $remoteSummary.Content,
            [Text.UTF8Encoding]::new($false)
        )

        if ($downloadPosts) {
            [IO.File]::Move($temporaryPostsPath, $PostsPath, $true)
        }

        [IO.File]::Move($temporarySummaryPath, $SummaryPath, $true)

        if ($downloadPosts) {
            Write-Information "Local archive updated from $localPostCount to $($remoteSummary.TotalPosts) posts." -InformationAction Continue
        }
        else {
            Write-Information "Local archive data is current with $localPostCount posts. Updated the run summary." -InformationAction Continue
        }
    }
    finally {
        foreach ($temporaryPath in @($temporaryPostsPath, $temporarySummaryPath)) {
            if (Test-Path -LiteralPath $temporaryPath) {
                Remove-Item -LiteralPath $temporaryPath -Force
            }
        }
    }
}

function Invoke-ArchiveUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilesPath,

        [Parameter(Mandatory)]
        [string]$OutputRoot,

        [Parameter(Mandatory)]
        [string]$SourceUrl,

        [string]$RepositoryDataUrl,

        [switch]$UpdateFromSource
    )

    if (-not (Test-Path -LiteralPath $OutputRoot)) {
        New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
    }

    $configuredProfile = Get-ConfiguredProfile -Path $ProfilesPath
    $runAt = (Get-Date).ToUniversalTime().ToString('o')
    $postsPath = Join-Path $OutputRoot 'posts.jsonl'
    $archiveSummaryPath = Join-Path $OutputRoot 'archive-summary.json'
    $existingPosts = @()

    $isGitHubActions = [string]::Equals(
        [string]$env:GITHUB_ACTIONS,
        'true',
        [StringComparison]::OrdinalIgnoreCase
    )

    if (-not $isGitHubActions -and -not $UpdateFromSource) {
        try {
            Sync-RepositoryArchive -DataUrl $RepositoryDataUrl -PostsPath $postsPath -SummaryPath $archiveSummaryPath
            return
        }
        catch {
            throw "Repository archive sync failed: $($_.Exception.Message)"
        }
    }

    try {
        $existingPosts = @(Read-JsonLine -Path $postsPath)

        Write-Information "Downloading public archive from $SourceUrl" -InformationAction Continue
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
            Save-JsonLine -Items $newPosts -Path $postsPath
        }
        else {
            Add-JsonLine -Items $newPosts -Path $postsPath
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
                    account_id     = $ArchiveProfile.AccountId
                    username       = $ArchiveProfile.Username
                    display_name   = $ArchiveProfile.DisplayName
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
        Write-Information "Archived $totalPosts total posts. Added $($newPosts.Count) new posts." -InformationAction Continue
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
                    account_id     = $ArchiveProfile.AccountId
                    username       = $ArchiveProfile.Username
                    display_name   = $ArchiveProfile.DisplayName
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
        throw "Public archive failed: $message"
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-ArchiveUpdate -ProfilesPath $ProfilesPath -OutputRoot $OutputRoot -SourceUrl $SourceUrl `
            -RepositoryDataUrl $RepositoryDataUrl -UpdateFromSource:$UpdateFromSource
    }
    catch {
        Write-Error $_.Exception.Message -ErrorAction Continue
        exit 1
    }
}
