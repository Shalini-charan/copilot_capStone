<#
.SYNOPSIS
Standalone tests for check-markdown-links.ps1 (COP-5). No external modules.

.DESCRIPTION
Builds fixtures in a temporary folder, runs the checker in a child process under each
available PowerShell edition, and asserts findings and exit codes. Exits 0 when all
assertions pass and 1 otherwise.
#>
[CmdletBinding()]
param()

$checker = Join-Path $PSScriptRoot 'check-markdown-links.ps1'
$script:Failures = New-Object System.Collections.Generic.List[string]
$script:Passed = 0
$script:Skipped = New-Object System.Collections.Generic.List[string]
$script:Edition = ''
$script:Exe = ''

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:Passed++ }
    else { $script:Failures.Add("[$script:Edition] $Message") }
}

function Invoke-Checker {
    param([string[]]$Arguments, [int]$TimeoutSeconds = 60)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $script:Exe
    $psi.Arguments = '-NoProfile -File "' + $checker + '" ' + (($Arguments | ForEach-Object { if ($_ -match '^-') { $_ } else { '"' + $_ + '"' } }) -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        $proc.Kill()
        return [pscustomobject]@{ ExitCode = -1; Out = ''; Err = 'TIMEOUT' }
    }
    $proc.WaitForExit()
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; Out = $outTask.Result; Err = $errTask.Result }
}

function New-Fixture {
    param([hashtable]$Files)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ('cop5-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $dir | Out-Null
    foreach ($name in $Files.Keys) {
        $full = Join-Path $dir $name
        $parent = Split-Path $full -Parent
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [System.IO.File]::WriteAllText($full, [string]$Files[$name], [System.Text.UTF8Encoding]::new($false))
    }
    return $dir
}

function Get-TreeHash {
    param([string]$Dir)
    $items = Get-ChildItem -LiteralPath $Dir -Recurse -Force -File | Sort-Object FullName
    ($items | ForEach-Object { $_.FullName + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash }) -join '|'
}

function Test-Edition {
    $tmpDirs = New-Object System.Collections.Generic.List[string]
    $fixture = { param($files) $d = New-Fixture $files; $tmpDirs.Add($d); $d }

    try {
        # FR-1, FR-2, FR-5: clean tree.
        $d = & $fixture @{ 'a.md' = "[b](b.md) [dir](sub/) [dir2](sub)`n"; 'b.md' = 'x'; 'sub/c.md' = '[up](../a.md)' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 0) "clean tree exits 0 (got $($r.ExitCode): $($r.Out) $($r.Err))"
        Assert-True ($r.Out -match 'broken=0') 'clean tree reports broken=0'

        # FR-3, FR-5: broken link details.
        $d = & $fixture @{ 'docs/x.md' = "line one`nSee [Missing Page](gone.md) here`n" }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 1) "broken link exits 1 (got $($r.ExitCode))"
        Assert-True ($r.Out -match 'docs/x\.md:2: \[Missing Page\]\(gone\.md\) -> docs/gone\.md') "finding has source, line, text, unresolved (out: $($r.Out))"

        # Source paths are root-relative even when the supplied path uses 8.3 short names.
        $d = & $fixture @{ 'a.md' = '[Top](gone.md)' }
        $suppliedRoot = $d
        try { $suppliedRoot = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($d).ShortPath } catch { $suppliedRoot = $d }
        $r = Invoke-Checker @('-Path', $suppliedRoot)
        Assert-True ($r.Out -match '(?m)^a\.md:1: \[Top\]\(gone\.md\) -> gone\.md\r?$') "root-level finding has a root-relative source path (out: $($r.Out))"

        # FR-4: skipped targets.
        $skip = "[a](http://x.invalid/a) [b](https://x.invalid/b) [c](mailto:a@b.c) [d](tel:123) [e](data:text/plain,hi) [f](file:///nope) [g](#anchor) [h](/root/rel.md) [i](C:\nope.md) [j](\\server\share\f.md) [k](//host/x)"
        $d = & $fixture @{ 'a.md' = $skip }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 0) "external, scheme, anchor, absolute, UNC targets are skipped (got $($r.ExitCode): $($r.Out))"

        # Fragment, query, titles, angle brackets, encoding, nested parentheses, images, reference definitions.
        $d = & $fixture @{
            'a.md'         = @'
[f](b.md#sec) [q](b.md?x=1) [t](b.md "title") [t2](b.md 'title') [t3](b.md (title))
[angle](<my file.md>) [enc](my%20file.md) [paren](file(1).md) ![img](img.png)
[ref]: b.md "Ref Title"
[ref2]: <my file.md>
[nested ![alt](img.png)](b.md)
'@
            'b.md'         = 'x'
            'my file.md'   = 'x'
            'file(1).md'   = 'x'
            'img.png'      = 'x'
        }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 0) "supported link forms resolve (got $($r.ExitCode): $($r.Out))"

        $d = & $fixture @{ 'a.md' = "[ok](b.md#x) [bad](nope.md#x) ![pic](missing.png)`n[badref]: lost.md`n"; 'b.md' = 'x' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 1) 'broken fragment link, image, and reference definition give exit 1'
        Assert-True ($r.Out -match '\[bad\]\(nope\.md#x\)') 'fragment link finding keeps the target as written'
        Assert-True ($r.Out -match '\[pic\]\(missing\.png\)') 'image finding reported'
        Assert-True ($r.Out -match 'a\.md:2: \[badref\]\(lost\.md\)') 'reference definition finding reported with label'
        Assert-True ($r.Out -match 'broken=3') 'exactly three findings'

        # Code, comments, and front matter are ignored.
        $content = @'
---
title: [x](front.md)
---
Plain [real](b.md)
```
[fenced](nope1.md)
```
~~~
[tilde](nope2.md)
~~~
Inline `[code](nope3.md)` and ``[dbl](nope4.md)`` text.
<!-- [comment](nope5.md) -->
<!--
[multi](nope6.md)
-->
After [ok](b.md)

    [indented](nope7.md)

- item

    [list continuation](b.md)
'@
        $d = & $fixture @{ 'a.md' = $content; 'b.md' = 'x' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 0) "links in code, comments, and front matter are ignored (got $($r.ExitCode): $($r.Out))"

        $d = & $fixture @{ 'a.md' = "- item`n`n    [still link](missing-in-list.md)`n" }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 1) 'indented link inside a list is still checked'

        # NFR-6: resolve from each source directory.
        $d = & $fixture @{ 'one/a.md' = '[t](t.md)'; 'one/t.md' = 'x'; 'two/a.md' = '[t](t.md)' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 1 -and $r.Out -match 'two/a\.md:1:' -and $r.Out -notmatch 'one/a\.md:1:') 'targets resolve from their own source directory'

        # ADR-11: targets outside the scan root are existence-checked.
        $d = & $fixture @{ 'README.md' = 'x'; 'scan/a.md' = '[up](../README.md) [gone](../nothing.md)' }
        $r = Invoke-Checker @('-Path', (Join-Path $d 'scan'))
        Assert-True ($r.ExitCode -eq 1 -and $r.Out -match '\[gone\]' -and $r.Out -notmatch '\[up\]') 'outside-root targets are checked for existence only'

        # Exclusions by exact directory name.
        $d = & $fixture @{ '.git/a.md' = '[x](nope.md)'; 'node_modules/p/a.md' = '[x](nope.md)'; '.github/a.md' = '[x](nope.md)' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.Out -match '\.github/a\.md' -and $r.Out -notmatch '\.git/a\.md' -and $r.Out -notmatch 'node_modules') '.github is scanned while .git and node_modules are excluded'

        # Wildcard characters are literal.
        $d = & $fixture @{ 'a.md' = '[x](notes[1].md) [y](a*.md) [z](what?.md)'; 'notes[1].md' = 'x' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 1 -and $r.Out -match '\[y\]\(a\*\.md\)' -and $r.Out -notmatch '\[x\]\(notes') 'wildcard characters are treated literally'

        # NFR-1: input validation.
        $r = Invoke-Checker @()
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match '-Path') 'missing -Path exits 2 with guidance'
        $r = Invoke-Checker @('-Path', (Join-Path ([System.IO.Path]::GetTempPath()) 'cop5-does-not-exist'))
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match 'does not exist') 'nonexistent folder exits 2'
        $d = & $fixture @{ 'a.md' = 'x' }
        $r = Invoke-Checker @('-Path', (Join-Path $d 'a.md'))
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match 'is a file') 'file path exits 2'
        $r = Invoke-Checker @('-Path', $d, '-Bogus', 'x')
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match 'unexpected argument') 'unknown argument exits 2, not 1'

        # NFR-2: no Markdown files.
        $d = & $fixture @{ 'notes.txt' = 'x' }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 0 -and $r.Out -match 'no Markdown files') 'empty scan exits 0 with an explicit message'

        # NFR-3: unreadable file, scan continues, exit 2 takes precedence.
        $d = & $fixture @{ 'a.md' = '[x](nope.md)'; 'locked.md' = 'x' }
        $lock = [System.IO.File]::Open((Join-Path $d 'locked.md'), 'Open', 'ReadWrite', 'None')
        try { $r = Invoke-Checker @('-Path', $d) } finally { $lock.Dispose() }
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match 'locked\.md' -and $r.Out -match 'a\.md:1:') 'locked file reports error, other findings still print, exit 2'

        $d = & $fixture @{ 'ok.md' = 'x' }
        [System.IO.File]::WriteAllBytes((Join-Path $d 'bad.md'), [byte[]](0xC3, 0x28, 0xFF, 0xFE, 0x41))
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match 'bad\.md') 'undecodable file exits 2'

        # Encodings.
        $d = & $fixture @{ 'b.md' = 'x' }
        [System.IO.File]::WriteAllText((Join-Path $d 'bom.md'), '[x](b.md)', [System.Text.UTF8Encoding]::new($true))
        [System.IO.File]::WriteAllText((Join-Path $d 'utf16.md'), '[x](missing16.md)', [System.Text.UnicodeEncoding]::new($false, $true))
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 1 -and $r.Out -match 'utf16\.md:1:' -and $r.Out -notmatch 'bom\.md') 'UTF-8 BOM and UTF-16 files are read correctly'

        # NFR-4: read-only.
        $d = & $fixture @{ 'a.md' = '[x](nope.md)'; 'b.md' = '[y](a.md)' }
        $before = Get-TreeHash $d
        $null = Invoke-Checker @('-Path', $d)
        Assert-True ($before -eq (Get-TreeHash $d)) 'checker does not modify the scanned tree'

        # Deterministic output.
        $d = & $fixture @{ 'z.md' = '[x](n1.md)'; 'a.md' = '[x](n2.md)'; 'm/b.md' = '[x](n3.md)' }
        $r1 = Invoke-Checker @('-Path', $d)
        $r2 = Invoke-Checker @('-Path', $d)
        Assert-True ($r1.Out -eq $r2.Out) 'repeated runs produce identical output'
        Assert-True ($r1.Out.IndexOf('a.md:1') -lt $r1.Out.IndexOf('m/b.md:1') -and $r1.Out.IndexOf('m/b.md:1') -lt $r1.Out.IndexOf('z.md:1')) 'findings are sorted by path'

        # NFR-5 and output sanitization: control characters are stripped.
        $esc = [char]27
        $d = & $fixture @{ 'a.md' = "[evil${esc}[31mtext](nope.md)" }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.Out -notmatch [regex]::Escape([string]$esc)) 'control characters are not echoed'
        $d = & $fixture @{ 'a.md' = "SECRET_TOKEN_12345 and [x](nope.md)" }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.Out -notmatch 'SECRET_TOKEN_12345') 'non-link content is not printed'

        # Junction loop does not hang or duplicate.
        $d = & $fixture @{ 'a.md' = '[x](nope.md)' }
        $junction = Join-Path $d 'loop'
        try {
            New-Item -ItemType Junction -Path $junction -Target $d -ErrorAction Stop | Out-Null
            $r = Invoke-Checker @('-Path', $d) -TimeoutSeconds 30
            Assert-True ($r.ExitCode -eq 1 -and $r.Out -notmatch 'loop/') 'junction loop is not followed'
            (Get-Item -LiteralPath $junction -Force).Delete()
        }
        catch { $script:Skipped.Add("[$script:Edition] junction test skipped: $($_.Exception.Message)") }

        # Pathological line stays bounded.
        $d = & $fixture @{ 'a.md' = (('](' * 9000) + "`n" + ('[' * 9000) + "`n" + '[x](nope.md)') }
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-Checker @('-Path', $d) -TimeoutSeconds 60
        $sw.Stop()
        Assert-True ($r.ExitCode -eq 1 -and $sw.Elapsed.TotalSeconds -lt 60) "pathological lines complete in bounded time ($([int]$sw.Elapsed.TotalSeconds)s)"

        # Over-long line is an operational error.
        $d = & $fixture @{ 'a.md' = ('a' * 30000) }
        $r = Invoke-Checker @('-Path', $d)
        Assert-True ($r.ExitCode -eq 2 -and $r.Err -match 'character limit') 'over-long line exits 2 with an actionable message'

        # Dot-sourcing exposes the core without exiting the host.
        $core = & $script:Exe -NoProfile -Command ". '$checker'; (Invoke-MarkdownLinkCheck -Path '$d').ExitCode"
        Assert-True ("$core".Trim() -eq '2') 'core function can be called in-process without exiting the host'
    }
    finally {
        foreach ($t in $tmpDirs) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

$editions = @()
foreach ($candidate in @(@{ Name = 'pwsh'; Exe = 'pwsh' }, @{ Name = 'powershell'; Exe = 'powershell' })) {
    $cmd = Get-Command $candidate.Exe -ErrorAction SilentlyContinue
    if ($cmd) { $editions += @{ Name = $candidate.Name; Exe = $cmd.Source } }
    else { $script:Skipped.Add("$($candidate.Name) not available; edition not tested") }
}
if ($editions.Count -eq 0) { Write-Error 'No PowerShell executable found'; exit 1 }

foreach ($candidateEdition in $editions) {
    $script:Edition = $candidateEdition.Name
    $script:Exe = $candidateEdition.Exe
    Write-Output "Running tests under $($candidateEdition.Name)"
    Test-Edition
}

Write-Output "Passed assertions: $script:Passed"
if ($script:Passed -eq 0) { $script:Failures.Add('no assertions executed') }
foreach ($s in $script:Skipped) { Write-Output "Skipped: $s" }
if ($script:Failures.Count -gt 0) {
    foreach ($f in $script:Failures) { Write-Output "FAIL: $f" }
    Write-Output "Result: FAILED ($($script:Failures.Count) failures)"
    exit 1
}
Write-Output 'Result: PASSED'
exit 0
