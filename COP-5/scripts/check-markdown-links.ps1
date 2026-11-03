<#
.SYNOPSIS
Reports broken relative links in Markdown files beneath a folder.

.DESCRIPTION
Read-only check for COP-5. Scans *.md files under -Path, checks relative file and folder
link targets, and prints one finding per broken link:
  relative/source.md:LINE: [link text](target) -> unresolved/path
External URLs, other URI schemes, in-page anchors, and root-relative or absolute paths are
skipped and never probed. No network access and no file modification.

Exit codes: 0 no broken links; 1 broken links found; 2 usage, input, or scan error
(an incomplete scan takes precedence over broken links).

.PARAMETER Path
Folder to scan recursively.

.EXAMPLE
.\check-markdown-links.ps1 -Path .\COP-4
#>
[CmdletBinding()]
param(
    [string]$Path,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$UnexpectedArguments
)

$script:ExcludedDirectoryNames = @('.git', 'node_modules')
$script:MaxFileBytes = 10MB
$script:MaxLineLength = 20000
$script:MaxDestinationLength = 500
$script:MaxOutputFieldLength = 200

$script:RegexTimeout = [TimeSpan]::FromSeconds(2)
$script:RegexNone = [System.Text.RegularExpressions.RegexOptions]::None
$script:ReCodeSpan = [regex]::new('(?<!`)(`+)(?!`)(.+?)(?<!`)\1(?!`)', $script:RegexNone, $script:RegexTimeout)
$script:ReRefDef = [regex]::new('^ {0,3}\[(?!\^)((?:[^\]\\]|\\.)+)\]:[ \t]*(<[^>]*>|\S+)', $script:RegexNone, $script:RegexTimeout)
$script:ReDestRun = [regex]::new('\G(?:[^\s()\\]|\\.)*', $script:RegexNone, $script:RegexTimeout)
$script:ReFence = [regex]::new('^ {0,3}(`{3,}|~{3,})(.*)$', $script:RegexNone, $script:RegexTimeout)
$script:ReListMarker = [regex]::new('^\s*(?:[-*+]|\d{1,9}[.)])(?:\s|$)', $script:RegexNone, $script:RegexTimeout)
$script:ReScheme = [regex]::new('^[A-Za-z][A-Za-z0-9+.\-]*:', $script:RegexNone, $script:RegexTimeout)
$script:ReDriveAbsolute = [regex]::new('^[A-Za-z]:[\\/]', $script:RegexNone, $script:RegexTimeout)

function ConvertTo-SafeText {
    param([string]$Text)
    $clean = [regex]::Replace($Text, '[\p{Cc}]', '?')
    if ($clean.Length -gt $script:MaxOutputFieldLength) {
        $clean = $clean.Substring(0, $script:MaxOutputFieldLength) + '...'
    }
    return $clean
}

function Mask-Range {
    param([char[]]$Chars, [int]$Start, [int]$Length)
    for ($k = $Start; $k -lt ($Start + $Length) -and $k -lt $Chars.Length; $k++) { $Chars[$k] = ' ' }
}

function Read-LinkDestination {
    param([string]$Text, [int]$Start)

    $n = $Text.Length
    $p = $Start
    while ($p -lt $n -and ($Text[$p] -eq ' ' -or $Text[$p] -eq "`t")) { $p++ }
    if ($p -ge $n) { return $null }

    if ($Text[$p] -eq '<') {
        $window = [Math]::Min($script:MaxDestinationLength, $n - $p - 1)
        $end = $Text.IndexOf('>', $p + 1, $window)
        if ($end -lt 0) { return $null }
        $dest = $Text.Substring($p + 1, $end - $p - 1)
        $p = $end + 1
    }
    else {
        $q = $p
        $depth = 0
        while ($q -lt $n) {
            $q += $script:ReDestRun.Match($Text, $q).Length
            if ($q - $p -gt $script:MaxDestinationLength) { return $null }
            if ($q -ge $n) { break }
            $c = $Text[$q]
            if ($c -eq '(') { $depth++; $q++ }
            elseif ($c -eq ')') {
                if ($depth -eq 0) { break }
                $depth--; $q++
            }
            else { break }
        }
        $dest = $Text.Substring($p, $q - $p)
        $dest = [regex]::Replace($dest, '\\([()<>\[\]])', '$1')
        $p = $q
    }

    while ($p -lt $n -and ($Text[$p] -eq ' ' -or $Text[$p] -eq "`t")) { $p++ }
    if ($p -lt $n -and $Text[$p] -ne ')') {
        $opener = $Text[$p]
        if ($opener -ne '"' -and $opener -ne "'" -and $opener -ne '(') { return $null }
        $closer = if ($opener -eq '(') { ')' } else { $opener }
        $window = [Math]::Min($script:MaxDestinationLength, $n - $p - 1)
        $end = $Text.IndexOf($closer, $p + 1, $window)
        if ($end -lt 0) { return $null }
        $p = $end + 1
        while ($p -lt $n -and ($Text[$p] -eq ' ' -or $Text[$p] -eq "`t")) { $p++ }
    }
    if ($p -ge $n -or $Text[$p] -ne ')') { return $null }
    return $dest
}

function Add-InlineLinkCandidates {
    param([string]$Masked, [string]$Original, [int]$LineNumber, $Candidates)

    # Single pass matches brackets so scanning stays linear on untrusted lines.
    $openStack = New-Object System.Collections.Generic.Stack[int]
    for ($i = 0; $i -lt $Masked.Length; $i++) {
        $c = $Masked[$i]
        if ($c -eq '[') { $openStack.Push($i) }
        elseif ($c -eq ']') {
            if ($openStack.Count -eq 0) { continue }
            $open = $openStack.Pop()
            if (($i + 1) -lt $Masked.Length -and $Masked[$i + 1] -eq '(') {
                $dest = Read-LinkDestination -Text $Masked -Start ($i + 2)
                if ($null -ne $dest) {
                    $Candidates.Add([pscustomobject]@{
                            Line   = $LineNumber
                            Text   = $Original.Substring($open + 1, $i - $open - 1)
                            Target = $dest
                        })
                }
            }
        }
    }
}

function Get-MarkdownLinkCandidates {
    param([string]$FilePath, $Candidates)

    $info = [System.IO.FileInfo]::new($FilePath)
    if ($info.Length -gt $script:MaxFileBytes) {
        throw "file exceeds the $($script:MaxFileBytes) byte limit"
    }
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $text = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $text = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    else {
        $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $text = $strictUtf8.GetString($bytes)
        if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }
    }

    $lines = [regex]::Split($text, "\r\n|\n|\r")

    $frontEnd = -1
    if ($lines.Count -gt 1 -and $lines[0] -match '^---\s*$') {
        for ($f = 1; $f -lt $lines.Count; $f++) {
            if ($lines[$f] -match '^(---|\.\.\.)\s*$') { $frontEnd = $f; break }
        }
    }

    $fenceChar = $null
    $fenceLength = 0
    $inComment = $false
    $inIndentedCode = $false
    $inList = $false
    $prevBlank = $true

    for ($n = 0; $n -lt $lines.Count; $n++) {
        $line = $lines[$n]
        $lineNumber = $n + 1
        if ($line.Length -gt $script:MaxLineLength) {
            throw "line $lineNumber exceeds the $($script:MaxLineLength) character limit"
        }
        if ($n -le $frontEnd) { continue }

        if ($null -ne $fenceChar) {
            $m = $script:ReFence.Match($line)
            if ($m.Success -and $m.Groups[1].Value[0] -eq $fenceChar -and
                $m.Groups[1].Value.Length -ge $fenceLength -and $m.Groups[2].Value.Trim().Length -eq 0) {
                $fenceChar = $null
            }
            continue
        }

        $work = $line
        if ($inComment) {
            $end = $work.IndexOf('-->', [StringComparison]::Ordinal)
            if ($end -lt 0) { $prevBlank = $false; continue }
            $work = (' ' * ($end + 3)) + $work.Substring($end + 3)
            $inComment = $false
        }

        $isBlank = $work.Trim().Length -eq 0
        $isIndented = $line.Length -gt 0 -and ($line.StartsWith('    ') -or $line[0] -eq "`t")

        if ($inIndentedCode) {
            if ($isBlank -or $isIndented) { continue }
            $inIndentedCode = $false
        }
        if ($isBlank) { $prevBlank = $true; continue }
        if ($isIndented -and $prevBlank -and -not $inList) {
            $inIndentedCode = $true
            continue
        }

        $fm = $script:ReFence.Match($work)
        if ($fm.Success -and -not ($fm.Groups[1].Value[0] -eq '`' -and $fm.Groups[2].Value.Contains('`'))) {
            $fenceChar = $fm.Groups[1].Value[0]
            $fenceLength = $fm.Groups[1].Value.Length
            $prevBlank = $false
            continue
        }

        if ($script:ReListMarker.IsMatch($work)) { $inList = $true }
        elseif (-not $isIndented) { $inList = $false }
        $prevBlank = $false

        $chars = $work.ToCharArray()
        foreach ($span in $script:ReCodeSpan.Matches($work)) {
            Mask-Range -Chars $chars -Start $span.Index -Length $span.Length
        }
        $masked = [string]::new($chars)
        $pos = 0
        while (($start = $masked.IndexOf('<!--', $pos, [StringComparison]::Ordinal)) -ge 0) {
            $close = $masked.IndexOf('-->', $start + 4, [StringComparison]::Ordinal)
            if ($close -lt 0) {
                Mask-Range -Chars $chars -Start $start -Length ($chars.Length - $start)
                $inComment = $true
                break
            }
            Mask-Range -Chars $chars -Start $start -Length ($close + 3 - $start)
            $pos = $close + 3
            $masked = [string]::new($chars)
        }
        $masked = [string]::new($chars)
        $masked = $masked.Replace('\[', '  ').Replace('\]', '  ')

        $def = $script:ReRefDef.Match($masked)
        if ($def.Success) {
            $target = $def.Groups[2].Value
            if ($target.StartsWith('<') -and $target.EndsWith('>')) { $target = $target.Substring(1, $target.Length - 2) }
            $Candidates.Add([pscustomobject]@{
                    Line   = $lineNumber
                    Text   = $def.Groups[1].Value
                    Target = $target
                })
            continue
        }

        Add-InlineLinkCandidates -Masked $masked -Original $line -LineNumber $lineNumber -Candidates $Candidates
    }
}

function Get-MarkdownFiles {
    param([string]$Root, $Errors)

    $files = New-Object System.Collections.Generic.List[object]
    $stack = New-Object System.Collections.Generic.Stack[object]
    $stack.Push([pscustomobject]@{ Full = $Root; Rel = '' })
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        $prefix = if ($current.Rel) { $current.Rel + '/' } else { '' }
        try {
            $dirInfo = [System.IO.DirectoryInfo]::new($current.Full)
            foreach ($file in $dirInfo.GetFiles()) {
                if ($file.Name.EndsWith('.md', [StringComparison]::OrdinalIgnoreCase)) {
                    $files.Add([pscustomobject]@{ Full = $file.FullName; Rel = $prefix + $file.Name })
                }
            }
            foreach ($sub in $dirInfo.GetDirectories()) {
                if ($sub.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { continue }
                if ($script:ExcludedDirectoryNames -contains $sub.Name) { continue }
                $stack.Push([pscustomobject]@{ Full = $sub.FullName; Rel = $prefix + $sub.Name })
            }
        }
        catch {
            $where = if ($current.Rel) { $current.Rel } else { '.' }
            $Errors.Add("cannot enumerate directory '$where': $($_.Exception.Message)")
        }
    }
    $files.Sort([Comparison[object]] { param($x, $y) [string]::CompareOrdinal($x.Rel, $y.Rel) })
    return , $files.ToArray()
}

function Join-RelativePath {
    param([string]$BaseDir, [string]$Target)
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($seg in (($BaseDir + '/' + $Target) -split '[\\/]')) {
        if ($seg -eq '' -or $seg -eq '.') { continue }
        if ($seg -eq '..') {
            if ($parts.Count -gt 0 -and $parts[$parts.Count - 1] -ne '..') { $parts.RemoveAt($parts.Count - 1) }
            else { $parts.Add('..') }
        }
        else { $parts.Add($seg) }
    }
    return ($parts -join '/')
}

function Invoke-MarkdownLinkCheck {
    [CmdletBinding()]
    param([string]$Path)

    $result = [pscustomobject]@{
        Findings     = New-Object System.Collections.Generic.List[string]
        Errors       = New-Object System.Collections.Generic.List[string]
        FilesScanned = 0
        LinksChecked = 0
        LinksSkipped = 0
        Info         = $null
        ExitCode     = 0
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $result.Errors.Add('missing required -Path. Usage: check-markdown-links.ps1 -Path <folder>')
        $result.ExitCode = 2
        return $result
    }

    try {
        $root = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    }
    catch {
        $result.Errors.Add("invalid -Path '$Path': $($_.Exception.Message)")
        $result.ExitCode = 2
        return $result
    }
    if (-not [System.IO.Directory]::Exists($root)) {
        if ([System.IO.File]::Exists($root)) {
            $result.Errors.Add("-Path '$Path' is a file; it must be a folder")
        }
        else {
            $result.Errors.Add("-Path '$Path' does not exist; supply an existing folder")
        }
        $result.ExitCode = 2
        return $result
    }
    $root = $root.TrimEnd('\', '/')

    $files = Get-MarkdownFiles -Root $root -Errors $result.Errors
    if ($files.Count -eq 0 -and $result.Errors.Count -eq 0) {
        $result.Info = "no Markdown files found under '$Path'"
    }

    foreach ($entry in $files) {
        $result.FilesScanned++
        $file = $entry.Full
        $display = $entry.Rel
        $candidates = New-Object System.Collections.Generic.List[object]
        try {
            Get-MarkdownLinkCandidates -FilePath $file -Candidates $candidates
        }
        catch {
            $result.Errors.Add("cannot read '$display': $($_.Exception.Message)")
            continue
        }

        $sourceDir = [System.IO.Path]::GetDirectoryName($file)
        $relDir = if ($display.Contains('/')) { $display.Substring(0, $display.LastIndexOf('/')) } else { '' }
        foreach ($candidate in $candidates) {
            $target = $candidate.Target.Trim()
            if ($target.Length -eq 0 -or $target.StartsWith('#') -or $target.StartsWith('/') -or
                $target.StartsWith('\') -or $script:ReDriveAbsolute.IsMatch($target) -or
                $script:ReScheme.IsMatch($target)) {
                $result.LinksSkipped++
                continue
            }

            $cut = $target.IndexOfAny([char[]]@('#', '?'))
            if ($cut -ge 0) { $target = $target.Substring(0, $cut) }
            if ($target.Length -eq 0) { $result.LinksSkipped++; continue }

            $decoded = [System.Uri]::UnescapeDataString($target)
            $result.LinksChecked++

            $exists = $false
            $full = $null
            try {
                $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($sourceDir, $decoded))
                $exists = [System.IO.File]::Exists($full) -or [System.IO.Directory]::Exists($full)
            }
            catch { $exists = $false }

            if (-not $exists) {
                $unresolved = Join-RelativePath -BaseDir $relDir -Target $decoded
                $result.Findings.Add(('{0}:{1}: [{2}]({3}) -> {4}' -f
                        (ConvertTo-SafeText $display), $candidate.Line,
                        (ConvertTo-SafeText $candidate.Text),
                        (ConvertTo-SafeText $candidate.Target),
                        (ConvertTo-SafeText $unresolved)))
            }
        }
    }

    if ($result.Errors.Count -gt 0) { $result.ExitCode = 2 }
    elseif ($result.Findings.Count -gt 0) { $result.ExitCode = 1 }
    return $result
}

# Skip the entry point when dot-sourced so tests can call the core in-process.
if ($MyInvocation.InvocationName -ne '.') {
    if ($UnexpectedArguments) {
        [Console]::Error.WriteLine("error: unexpected argument(s): $($UnexpectedArguments -join ' '). Usage: check-markdown-links.ps1 -Path <folder>")
        exit 2
    }
    $outcome = Invoke-MarkdownLinkCheck -Path $Path
    foreach ($err in $outcome.Errors) { [Console]::Error.WriteLine("error: $err") }
    if ($outcome.Info) { Write-Output "info: $($outcome.Info)" }
    foreach ($finding in $outcome.Findings) { Write-Output $finding }
    Write-Output ('Summary: files scanned={0}, links checked={1}, links skipped={2}, broken={3}, errors={4}' -f
        $outcome.FilesScanned, $outcome.LinksChecked, $outcome.LinksSkipped, $outcome.Findings.Count, $outcome.Errors.Count)
    exit $outcome.ExitCode
}
