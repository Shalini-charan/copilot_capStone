[CmdletBinding()]
param(
    [string]$RequirementsPath = (Join-Path $PSScriptRoot '..\requirements.md'),
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RequirementsValidationErrors {
    param([Parameter(Mandatory)][string]$Content)

    $errors = [System.Collections.Generic.List[string]]::new()
    $frontMatterMatch = [regex]::Match(
        $Content,
        '\A---\r?\n(?<front>.*?)\r?\n---(?:\r?\n|$)',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if (-not $frontMatterMatch.Success) {
        $errors.Add('Missing or malformed YAML front matter.')
        return $errors.ToArray()
    }

    $frontMatter = $frontMatterMatch.Groups['front'].Value
    $frontMatterValues = @{}
    foreach ($line in ($frontMatter -split '\r?\n')) {
        if ($line -notmatch '^(?<key>[A-Za-z][A-Za-z0-9_-]*):\s*(?<value>.*)$') {
            $errors.Add('Front matter contains a line that is not a supported key/value entry.')
            continue
        }

        $key = $Matches['key']
        if ($frontMatterValues.ContainsKey($key)) {
            $errors.Add("Front matter contains duplicate key '$key'.")
            continue
        }

        $frontMatterValues[$key] = $Matches['value'].Trim()
    }

    $requiredFields = @('title', 'description', 'author', 'date', 'version', 'status', 'tags')
    foreach ($field in $requiredFields) {
        if (-not $frontMatterValues.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($frontMatterValues[$field])) {
            $errors.Add("Required front-matter field '$field' is missing or empty.")
        }
    }
    if (@($frontMatterValues.Keys | Where-Object { $_ -notin $requiredFields }).Count -gt 0) {
        $errors.Add('Front matter contains unsupported fields.')
    }

    foreach ($field in @('title', 'description', 'author')) {
        if ($frontMatterValues.ContainsKey($field) -and $frontMatterValues[$field] -notmatch "^[A-Za-z0-9][A-Za-z0-9 .,()'/_-]*$") {
            $errors.Add("Front-matter field '$field' must be a non-empty plain-text scalar.")
        }
    }
    if ($frontMatterValues.ContainsKey('date')) {
        $parsedDate = [datetime]::MinValue
        $validDate = [datetime]::TryParseExact(
            $frontMatterValues['date'],
            'yyyy-MM-dd',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None,
            [ref]$parsedDate
        )
        if (-not $validDate) {
            $errors.Add("Front-matter field 'date' must be a real calendar date in YYYY-MM-DD format.")
        }
    }
    if ($frontMatterValues.ContainsKey('version') -and $frontMatterValues['version'] -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
        $errors.Add("Front-matter field 'version' must use canonical major.minor.patch semantic version format.")
    }
    if ($frontMatterValues.ContainsKey('status') -and $frontMatterValues['status'] -ne 'approved') {
        $errors.Add('Requirements artifact must be approved before this POC validation.')
    }
    if ($frontMatterValues.ContainsKey('tags') -and $frontMatterValues['tags'] -notmatch '^\[[a-z0-9][a-z0-9-]*(?:\s*,\s*[a-z0-9][a-z0-9-]*)*\]$') {
        $errors.Add("Front-matter field 'tags' must be a non-empty inline list of lowercase tags.")
    }

    if ($Content -notmatch 'COP-2' -or $Content -notmatch 'COP-3') {
        $errors.Add('Requirements artifact must trace both the source issue COP-2 and POC scope COP-3.')
    }

    $scopeSection = [regex]::Match($Content, '(?ms)^### POC Scope\s*(?<body>.*?)(?=^\d+\.\s+|^### |^## |\z)')
    if (-not $scopeSection.Success) {
        $errors.Add('The COP-3 POC scope section is missing.')
    }
    else {
        $scopeBody = $scopeSection.Groups['body'].Value
        $scopeBullets = [regex]::Matches($scopeBody, '(?m)^-\s+.+$')
        $sourceEntries = [regex]::Matches($scopeBody, '(?im)^-\s+Source:\s*(.+?)\s*$')
        $targetEntries = [regex]::Matches($scopeBody, '(?im)^-\s+Target:\s*(.+?)\s*$')
        $directionEntries = [regex]::Matches($scopeBody, '(?im)^-\s+Direction:\s*(.+?)\s*$')
        $scopeNonEmptyLines = @($scopeBody -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $expectedDirection = 'one-way Jira-to-repository transfer with human review; no production or scheduled automation.'
        if ($scopeBullets.Count -ne 3 -or $scopeNonEmptyLines.Count -ne 3 -or $sourceEntries.Count -ne 1 -or $sourceEntries[0].Groups[1].Value.Trim() -ne 'Jira issue COP-2.' -or
            $targetEntries.Count -ne 1 -or $targetEntries[0].Groups[1].Value.Trim() -ne 'repository `requirements.md`.' -or
            $directionEntries.Count -ne 1 -or $directionEntries[0].Groups[1].Value.Trim() -ne $expectedDirection) {
            $errors.Add('The POC scope must define exactly one source (Jira issue COP-2), one target (repository requirements.md), and a human-reviewed, non-production direction.')
        }
    }

    $requirementIds = [regex]::Matches($Content, '(?m)^\| (FR-\d+) \|') |
        ForEach-Object { $_.Groups[1].Value }
    $expectedRequirementIds = 1..8 | ForEach-Object { "FR-$_" }
    $uniqueRequirementIds = @($requirementIds | Select-Object -Unique)
    $missingRequirementIds = @($expectedRequirementIds | Where-Object { $_ -notin $uniqueRequirementIds })
    $unexpectedRequirementIds = @($uniqueRequirementIds | Where-Object { $_ -notin $expectedRequirementIds })
    if ($requirementIds.Count -ne 8 -or $uniqueRequirementIds.Count -ne 8 -or $missingRequirementIds.Count -gt 0 -or $unexpectedRequirementIds.Count -gt 0) {
        $errors.Add('Expected exactly eight unique functional requirement IDs (FR-1 through FR-8).')
    }

    $pocSection = [regex]::Match($Content, '(?ms)^## POC Acceptance Criteria \(COP-3\)\s*$(?<body>.*?)(?=^## |\z)')
    if (-not $pocSection.Success) {
        $errors.Add('COP-3 POC acceptance criteria section is missing.')
    }
    else {
        $pocCriteria = [regex]::Matches($pocSection.Groups['body'].Value, '(?m)^(\d+)\.\s+')
        $criterionNumbers = @($pocCriteria | ForEach-Object { [int]$_.Groups[1].Value })
        $expectedCriterionNumbers = 1..6
        if ($criterionNumbers.Count -ne 6 -or ($criterionNumbers -join ',') -ne ($expectedCriterionNumbers -join ',')) {
            $errors.Add('Expected COP-3 POC acceptance criteria numbered once each, in order from 1 through 6.')
        }
    }

    return $errors.ToArray()
}

if (-not (Test-Path -LiteralPath $RequirementsPath -PathType Leaf)) {
    Write-Error "Requirements artifact not found: $RequirementsPath"
    exit 1
}

$content = Get-Content -LiteralPath $RequirementsPath -Raw
$validationErrors = @(Get-RequirementsValidationErrors -Content $content)
if ($validationErrors.Count -gt 0) {
    foreach ($validationError in $validationErrors) {
        Write-Error $validationError -ErrorAction Continue
    }
    exit 1
}

if ($SelfTest) {
    $malformedFrontMatterContent = [regex]::Replace($content, '\A---\r?\n', '', 1)
    if (@(Get-RequirementsValidationErrors -Content $malformedFrontMatterContent).Count -eq 0) {
        Write-Error 'Self-test failed: malformed front matter was accepted.'
        exit 1
    }

    $invalidYamlContent = [regex]::Replace($content, '(?m)^tags:.*$', 'tags: [unterminated', 1)
    if (@(Get-RequirementsValidationErrors -Content $invalidYamlContent).Count -eq 0) {
        Write-Error 'Self-test failed: malformed front-matter list was accepted.'
        exit 1
    }

    $invalidDateContent = [regex]::Replace($content, '(?m)^date:.*$', 'date: 2026-99-99', 1)
    if (@(Get-RequirementsValidationErrors -Content $invalidDateContent).Count -eq 0) {
        Write-Error 'Self-test failed: impossible calendar date was accepted.'
        exit 1
    }

    $invalidVersionContent = [regex]::Replace($content, '(?m)^version:.*$', 'version: 01.0.0', 1)
    if (@(Get-RequirementsValidationErrors -Content $invalidVersionContent).Count -eq 0) {
        Write-Error 'Self-test failed: non-canonical semantic version was accepted.'
        exit 1
    }

    $missingMetadataContent = [regex]::Replace($content, '(?m)^author:.*\r?\n', '', 1)
    if (@(Get-RequirementsValidationErrors -Content $missingMetadataContent).Count -eq 0) {
        Write-Error 'Self-test failed: missing required metadata was accepted.'
        exit 1
    }

    $firstRequirement = [regex]::Match($content, '(?m)^\| FR-1 \|.*$').Value
    if ([string]::IsNullOrWhiteSpace($firstRequirement)) {
        Write-Error 'Self-test setup failed: FR-1 row not found.'
        exit 1
    }

    $duplicateContent = $content + [Environment]::NewLine + $firstRequirement
    if (@(Get-RequirementsValidationErrors -Content $duplicateContent).Count -eq 0) {
        Write-Error 'Self-test failed: duplicate requirement ID was accepted.'
        exit 1
    }

    $outOfRangeContent = [regex]::Replace($content, '(?m)^\| FR-8 \|', '| FR-9 |', 1)
    if (@(Get-RequirementsValidationErrors -Content $outOfRangeContent).Count -eq 0) {
        Write-Error 'Self-test failed: an out-of-range requirement ID was accepted.'
        exit 1
    }

    $invalidCriteriaNumberingContent = [regex]::Replace($content, '(?m)^1\.\s+', '2. ', 1)
    if (@(Get-RequirementsValidationErrors -Content $invalidCriteriaNumberingContent).Count -eq 0) {
        Write-Error 'Self-test failed: duplicate acceptance-criteria numbering was accepted.'
        exit 1
    }

    $extraSourceContent = [regex]::Replace($content, '(?m)^- Source:.*$', '$0' + [Environment]::NewLine + '- Source: Jira issue COP-4.', 1)
    if (@(Get-RequirementsValidationErrors -Content $extraSourceContent).Count -eq 0) {
        Write-Error 'Self-test failed: additional source scope was accepted.'
        exit 1
    }

    Write-Output 'Self-test passed: malformed front matter, missing metadata, invalid date/version, duplicate/out-of-range IDs, invalid criteria numbering, and expanded source scope are detected.'
}

Write-Output "COP-3 POC artifact validation passed: $RequirementsPath"
