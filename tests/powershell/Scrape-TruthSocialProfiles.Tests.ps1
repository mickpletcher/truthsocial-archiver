BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '../../scripts/Scrape-TruthSocialProfiles.ps1'
    . $scriptPath

    function Get-TestPost {
        param(
            [Parameter(Mandatory)]
            [string]$Id
        )

        [pscustomobject]@{
            id               = $Id
            created_at       = '2026-08-30T01:00:00Z'
            url              = "https://truthsocial.com/@realDonaldTrump/$Id"
            content          = "<p>Post $Id</p>"
            replies_count    = 1
            reblogs_count    = 2
            favourites_count = 3
            media            = @()
        }
    }

    function Get-SourceResponse {
        param(
            [Parameter(Mandatory)]
            [array]$Posts
        )

        [pscustomobject]@{
            Content = ConvertTo-Json -InputObject $Posts -Depth 10 -Compress
            Headers = @{
                'Content-Type'  = 'application/json'
                'Last-Modified' = 'Sun, 30 Aug 2026 06:00:00 GMT'
            }
        }
    }
}

Describe 'Get-PublicArchive' {
    It 'rejects duplicate post IDs' {
        Mock Invoke-WebRequest {
            Get-SourceResponse -Posts @((Get-TestPost -Id '1'), (Get-TestPost -Id '1'))
        }

        { Get-PublicArchive -Url 'https://example.test/archive.json' } |
            Should -Throw '*duplicate post ID 1*'
    }

    It 'rejects unexpected profile URLs' {
        $post = Get-TestPost -Id '1'
        $post.url = 'https://truthsocial.com/@someoneElse/1'
        Mock Invoke-WebRequest { Get-SourceResponse -Posts @($post) }

        { Get-PublicArchive -Url 'https://example.test/archive.json' } |
            Should -Throw '*unexpected post URL*'
    }

    It 'rejects records missing required fields' {
        $post = Get-TestPost -Id '1'
        $post.created_at = $null
        Mock Invoke-WebRequest { Get-SourceResponse -Posts @($post) }

        { Get-PublicArchive -Url 'https://example.test/archive.json' } |
            Should -Throw '*missing id, created_at, or url*'
    }
}

Describe 'Invoke-ArchiveUpdate' {
    BeforeEach {
        $script:outputRoot = Join-Path $TestDrive 'archive'
        $script:profilesPath = Join-Path $TestDrive 'profiles.txt'
        Set-Content -LiteralPath $script:profilesPath -Value '@realDonaldTrump'
    }

    It 'is append-only and idempotent for repeated source updates' {
        Mock Get-PublicArchive {
            [pscustomobject]@{
                Items        = @((Get-TestPost -Id '1'), (Get-TestPost -Id '2'))
                LastModified = 'Sun, 30 Aug 2026 06:00:00 GMT'
            }
        }

        Invoke-ArchiveUpdate -ProfilesPath $script:profilesPath -OutputRoot $script:outputRoot `
            -SourceUrl 'https://example.test/archive.json' -UpdateFromSource
        Invoke-ArchiveUpdate -ProfilesPath $script:profilesPath -OutputRoot $script:outputRoot `
            -SourceUrl 'https://example.test/archive.json' -UpdateFromSource

        $posts = @(Get-Content -LiteralPath (Join-Path $script:outputRoot 'posts.jsonl'))
        $summary = Get-Content -Raw -LiteralPath (Join-Path $script:outputRoot 'archive-summary.json') |
            ConvertFrom-Json

        $posts.Count | Should -Be 2
        @($posts | ForEach-Object { ($_ | ConvertFrom-Json).id }) | Should -Be @('1', '2')
        $summary.status | Should -Be 'ok'
        $summary.total_posts | Should -Be 2
        $summary.new_posts | Should -Be 0
        Should -Invoke Get-PublicArchive -Times 2 -Exactly
    }

    It 'writes an error summary and throws when the source fails' {
        Mock Get-PublicArchive { throw 'upstream unavailable' }

        {
            Invoke-ArchiveUpdate -ProfilesPath $script:profilesPath -OutputRoot $script:outputRoot `
                -SourceUrl 'https://example.test/archive.json' -UpdateFromSource
        } | Should -Throw '*Public archive failed: upstream unavailable*'

        $summary = Get-Content -Raw -LiteralPath (Join-Path $script:outputRoot 'archive-summary.json') |
            ConvertFrom-Json
        $summary.status | Should -Be 'error'
        $summary.profiles[0].status | Should -Be 'error'
        $summary.profiles[0].message | Should -Be 'upstream unavailable'
    }
}
