[CmdletBinding()]
param(
    [switch]$Run,
    [string]$SupabaseUrl = $env:SUPABASE_URL,
    [string]$PublishableKey = $env:SUPABASE_PUBLISHABLE_KEY,
    [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Run) {
    throw 'Safety stop: this script creates and removes one temporary demo Journal entry. Re-run with -Run only for a disposable signed-in test account.'
}

foreach ($required in @(
    @{ Name = 'SUPABASE_URL'; Value = $SupabaseUrl },
    @{ Name = 'SUPABASE_PUBLISHABLE_KEY'; Value = $PublishableKey },
    @{ Name = 'SUPABASE_ACCESS_TOKEN'; Value = $AccessToken }
)) {
    if ([string]::IsNullOrWhiteSpace($required.Value)) {
        throw "Missing $($required.Name). Do not use a service-role key; use the access token of a disposable signed-in test account."
    }
}

if ($SupabaseUrl -notmatch '^https://') {
    throw 'SUPABASE_URL must start with https://.'
}

function Get-FirstRecord {
    param([AllowNull()] [object]$Value)

    $records = @($Value)
    if ($records.Count -eq 0 -or $null -eq $records[0]) {
        throw 'The API did not return the expected record.'
    }
    return $records[0]
}

function Invoke-DemoRequest {
    param(
        [Parameter(Mandatory)] [ValidateSet('GET', 'POST', 'PATCH', 'DELETE')] [string]$Method,
        [Parameter(Mandatory)] [string]$Uri,
        [AllowNull()] [object]$Body
    )

    $headers = @{
        apikey = $PublishableKey
        Authorization = "Bearer $AccessToken"
        Accept = 'application/json'
        Prefer = 'return=representation'
    }

    if ($null -eq $Body) {
        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
    }

    return Invoke-RestMethod `
        -Method $Method `
        -Uri $Uri `
        -Headers $headers `
        -ContentType 'application/json' `
        -Body ($Body | ConvertTo-Json -Compress)
}

$baseUrl = $SupabaseUrl.TrimEnd('/')
$endpoint = "$baseUrl/rest/v1/journal_entries"
$marker = "EverCare Demo API verification $(Get-Date -Format 'yyyyMMdd-HHmmss')"
$createdId = $null
$steps = [System.Collections.Generic.List[string]]::new()

try {
    [void](Invoke-DemoRequest -Method GET -Uri "$endpoint?select=id,title&limit=1")
    $steps.Add('PASS  GET    Read authenticated journal data.')

    $created = Get-FirstRecord (Invoke-DemoRequest -Method POST -Uri $endpoint -Body @{
        title = $marker
        body = 'Temporary non-PHI record created by the Week 6 API verification script. It will be deleted automatically.'
    })
    $createdId = [string]$created.id
    if ([string]::IsNullOrWhiteSpace($createdId)) {
        throw 'POST did not return a journal entry ID.'
    }
    $steps.Add('PASS  POST   Created a temporary non-PHI journal record.')

    $filter = [uri]::EscapeDataString($createdId)
    $updated = Get-FirstRecord (Invoke-DemoRequest -Method PATCH -Uri "$endpoint?id=eq.$filter" -Body @{
        title = "$marker (updated)"
        body = 'Temporary non-PHI record updated by the Week 6 API verification script. It will be deleted automatically.'
    })
    if ([string]$updated.title -notlike '*updated)') {
        throw 'PATCH did not return the expected updated title.'
    }
    $steps.Add('PASS  PATCH  Updated the temporary record.')

    $verified = Get-FirstRecord (Invoke-DemoRequest -Method GET -Uri "$endpoint?id=eq.$filter&select=id,title,body")
    if ([string]$verified.title -notlike '*updated)') {
        throw 'GET verification did not return the PATCH result.'
    }
    $steps.Add('PASS  GET    Confirmed the persisted PATCH result.')

    [void](Invoke-DemoRequest -Method DELETE -Uri "$endpoint?id=eq.$filter")
    $steps.Add('PASS  DELETE Removed the temporary record.')

    $afterDelete = @(Invoke-DemoRequest -Method GET -Uri "$endpoint?id=eq.$filter&select=id")
    if ($afterDelete.Count -ne 0) {
        throw 'DELETE verification failed because the temporary record is still visible.'
    }
    $createdId = $null
    $steps.Add('PASS  GET    Confirmed the temporary record is absent.')

    Write-Host ''
    Write-Host 'EverCare Week 6 Supabase CRUD API verification completed.' -ForegroundColor Green
    $steps | ForEach-Object { Write-Host $_ -ForegroundColor Green }
    Write-Host 'No demo record remains. Save this console output as PATCH/DELETE evidence.' -ForegroundColor Green
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($createdId)) {
        try {
            $cleanupFilter = [uri]::EscapeDataString($createdId)
            [void](Invoke-DemoRequest -Method DELETE -Uri "$endpoint?id=eq.$cleanupFilter")
            Write-Warning 'The verification did not finish normally, but its temporary record was removed during cleanup.'
        }
        catch {
            Write-Warning "Cleanup could not remove temporary record $createdId. Delete it manually from the disposable test account."
        }
    }
}
