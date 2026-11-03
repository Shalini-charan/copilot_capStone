[CmdletBinding()]
param(
    [string]$PagePath = (Join-Path $PSScriptRoot '..\index.html')
)

$ErrorActionPreference = 'Stop'

function Fail-Validation {
    param([Parameter(Mandatory)][string]$Message)
    Write-Error "Login page validation failed: $Message"
    exit 1
}

if (-not (Test-Path -LiteralPath $PagePath -PathType Leaf)) {
    Fail-Validation "Page not found: $PagePath"
}

$content = Get-Content -LiteralPath $PagePath -Raw
$checks = @(
    @{ Pattern = '(?is)<html\s+lang="en"'; Message = 'document language is missing.' },
    @{ Pattern = '(?is)<meta\s+name="viewport"'; Message = 'responsive viewport metadata is missing.' },
    @{ Pattern = '(?is)<form\s+id="loginForm"\s+novalidate>'; Message = 'login form or custom validation configuration is missing.' },
    @{ Pattern = '(?is)<label\s+for="username">Username</label>'; Message = 'username label is missing or not associated.' },
    @{ Pattern = '(?is)<input\s+id="username"\s+type="text"'; Message = 'username input is missing.' },
    @{ Pattern = '(?is)<label\s+for="password">Password</label>'; Message = 'password label is missing or not associated.' },
    @{ Pattern = '(?is)<input\s+id="password"\s+type="password"'; Message = 'masked password input is missing.' },
    @{ Pattern = '(?is)<button\s+type="submit">Sign in</button>'; Message = 'Sign in submit button is missing.' },
    @{ Pattern = '(?is)id="usernameError"'; Message = 'username validation feedback target is missing.' },
    @{ Pattern = '(?is)id="passwordError"'; Message = 'password validation feedback target is missing.' },
    @{ Pattern = '(?is)id="formFeedback"\s+role="status"'; Message = 'accessible form status feedback is missing.' },
    @{ Pattern = '(?is)form\.addEventListener\(''submit''|form\.addEventListener\("submit"'; Message = 'local submit handler is missing.' },
    @{ Pattern = '(?is)event\.preventDefault\(\)'; Message = 'default form submission is not prevented.' },
    @{ Pattern = '(?is)usernameInput\.value\.trim\(\)\.length\s*===\s*0'; Message = 'whitespace-only username validation is missing.' },
    @{ Pattern = '(?is)passwordInput\.value\s*=\s*''''|passwordInput\.value\s*=\s*""'; Message = 'password clearing after unavailable feedback is missing.' },
    @{ Pattern = '(?is)Sign-in is unavailable'; Message = 'unavailable sign-in feedback is missing.' }
)

foreach ($check in $checks) {
    if ($content -notmatch $check.Pattern) {
        Fail-Validation $check.Message
    }
}

$forbiddenPatterns = @(
    @{ Pattern = '(?is)<script\b[^>]*\bsrc\s*='; Message = 'external script dependency is not allowed.' },
    @{ Pattern = '(?is)<form\b[^>]*\baction\s*='; Message = 'form action could submit or navigate unexpectedly.' },
    @{ Pattern = '(?is)\b(fetch|XMLHttpRequest|sendBeacon)\s*\('; Message = 'network submission code is not allowed.' },
    @{ Pattern = '(?is)\b(localStorage|sessionStorage)\b|document\.cookie'; Message = 'credential persistence mechanism is not allowed.' },
    @{ Pattern = '(?is)\bconsole\.(log|info|warn|error)\s*\('; Message = 'console logging is not allowed.' }
)

foreach ($check in $forbiddenPatterns) {
    if ($content -match $check.Pattern) {
        Fail-Validation $check.Message
    }
}

Write-Output "Login page validation passed: $PagePath"