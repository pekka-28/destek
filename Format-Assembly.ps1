# Format-Assembly.ps1

[CmdletBinding()]
param([string[]]$Path, [switch]$Check)

$ErrorActionPreference = 'Stop'

function Split-AssemblyLine([string]$Line) {
    $code = [Text.StringBuilder]::new()
    $quote = [char]0
    $space = $false
    for ($i = 0; $i -lt $Line.Length; $i++) {
        $c = $Line[$i]
        if ($quote -ne [char]0) {
            [void]$code.Append($c)
            if ($c -eq $quote) {
                if ($i + 1 -lt $Line.Length -and $Line[$i + 1] -eq $quote) {
                    [void]$code.Append($Line[++$i])
                } else { $quote = [char]0 }
            }
            continue
        }
        if ($c -eq ';') {
            return @{ Code = $code.ToString(); Comment = $Line.Substring($i).TrimEnd() }
        }
        if ([char]::IsWhiteSpace($c)) { $space = $true; continue }
        if ($space -and $code.Length) { [void]$code.Append(' ') }
        $space = $false
        # A Z80 register suffix such as AF' is not a string delimiter.
        if (($c -eq "'" -or $c -eq '"') -and
            ($i -eq 0 -or $Line[$i - 1] -notmatch '[\w]')) { $quote = $c }
        [void]$code.Append($c)
    }
    return @{ Code = $code.ToString(); Comment = '' }
}

function Convert-AssemblyLayout([string]$Text) {
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($line in [regex]::Split($Text, '\r?\n')) {
        $parts = Split-AssemblyLine $line
        $code = $parts.Code
        $comment = $parts.Comment
        if (-not $code -and $comment) {
            $words = ($comment.Substring(1).Trim() -split '\s+')
            $wrapped = ';'
            foreach ($word in $words) {
                if ($wrapped.Length + 1 + $word.Length -gt 72 -and $wrapped -ne ';') {
                    $lines.Add($wrapped)
                    $wrapped = ';'
                }
                if ($word) { $wrapped += ' ' + $word }
            }
            $lines.Add($wrapped)
            continue
        }
        $prefix = ''
        $operation = ''
        if ($code -match '^\S+:$') {
            $formatted = $code
        } elseif ($code -match '^(\S+:?)\s+((?:(?:segment|ends|proc|endp|equ|db|dw|dd|label|macro)\b|(?:byte|word|dword)\b(?!\s+ptr\b)).*)$' -or
                  $code -match '^(\S+:)\s+(.+)$') {
            $label = $Matches[1]
            $operation = $Matches[2]
            $width = 16 * ([Math]::Floor($label.Length / 16) + 1)
            $prefix = $label.PadRight($width)
        } elseif ($code) {
            $prefix = ' ' * 16
            $operation = $code
        } else { $formatted = '' }
        if ($operation) {
            $fields = $operation -split ' ', 2
            $formatted = $prefix + $fields[0]
            if ($fields.Count -eq 2) { $formatted += "`t" + $fields[1] }
        }
        if ($comment) {
            $column = Get-AssemblyColumn $formatted
            $formatted += (' ' * [Math]::Max(1, 48 - $column)) + $comment
        }
        $lines.Add($formatted)
    }

    $result = [Collections.Generic.List[string]]::new()
    $previous = ''
    foreach ($line in $lines) {
        if (-not $line) {
            if ($result.Count -and $result[$result.Count - 1]) { $result.Add('') }
            continue
        }
        $commentBoundary = ($line.StartsWith(';') -ne $previous.StartsWith(';'))
        $before = $line -match '^\S+\s+proc\b|^\s+assume\b|^\s+include\b'
        $after = $previous -match '^\S+\s+endp\b|^\s+include\b'
        $label = $line -match '^\S+:$'
        $terminal = (Split-AssemblyLine $previous).Code -match '^(jmp|ret|retf|iret)\b'
        $data = (Split-AssemblyLine $previous).Code -match '^(db|dw|dd|Message)\b'
        $nextData = (Split-AssemblyLine $line).Code -match '^(db|dw|dd|Message)\b'
        $after = $after -or ($label -and ($terminal -or $data)) -or
            ($data -and -not $nextData -and -not $label)
        # A label and its body, and a final instruction and ENDP, stay together.
        $closeGap = ($previous -match '^\S+:$|^\S+\s+proc\b' -and
            -not ($commentBoundary -or $before)) -or
            ($line -match '^\S+\s+endp\b' -and -not $previous.StartsWith(';'))
        if ($closeGap -and $result.Count -and -not $result[$result.Count - 1]) {
            $result.RemoveAt($result.Count - 1)
        }
        if ($result.Count -and ($commentBoundary -or $before -or $after) -and
            $result[$result.Count - 1]) { $result.Add('') }
        $result.Add($line)
        $previous = $line
    }
    while ($result.Count -and -not $result[$result.Count - 1]) { $result.RemoveAt($result.Count - 1) }
    return ($result -join "`r`n") + "`r`n"
}

function Get-AssemblyColumn([string]$Text) {
    $column = 0
    foreach ($c in $Text.ToCharArray()) {
        if ($c -eq "`t") { $column += 8 - ($column % 8) }
        else { $column++ }
    }
    return $column
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $Path) {
        $Path = @(Get-ChildItem $PSScriptRoot -Recurse -File |
            Where-Object Extension -in '.asm','.inc' | Select-Object -ExpandProperty FullName)
    }
    $differences = [Collections.Generic.List[string]]::new()
    foreach ($file in $Path) {
        $fullPath = (Resolve-Path -LiteralPath $file).Path
        $original = [IO.File]::ReadAllText($fullPath)
        $formatted = Convert-AssemblyLayout $original
        if ($original -cne $formatted) {
            if ($Check) { $differences.Add($fullPath) }
            else { [IO.File]::WriteAllText($fullPath, $formatted, [Text.UTF8Encoding]::new($false)) }
        }
    }
    if ($differences.Count) { throw "Assembly formatting differs: $($differences -join ', ')" }
    Write-Host "Assembly layout $(if ($Check) { 'verified' } else { 'formatted' }) in $($Path.Count) files."
}
