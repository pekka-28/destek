# Test-AssemblyLayout.ps1

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot '../../Format-Assembly.ps1') -Check

# Independently audit instruction fields, not just formatter idempotence.
$opcodes = 'mov|movsb|movsw|lods|lodsb|lodsw|stosb|stosw|cmp|test|push|pop|call|jmp|j[a-z]+|loop[e-z]*|ret|retf|iret|in|out|inc|dec|add|adc|sub|sbb|and|or|xor|xchg|lea|les|lds|shl|shr|rol|ror|rcl|rcr|cli|sti|cld|std|nop|rep|repne'
$count = 0
foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot '../..') -Recurse -File |
    Where-Object Extension -in '.asm','.inc') {
    $number = 0
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        $number++
        if ($line -match ('^\s*('+ $opcodes +')\b(?!:)')) {
            if ($line -notmatch ('^ {16}('+ $opcodes +')(?=\t|\s*;|$)')) {
                throw "Incorrect instruction field: $($file.Name):$number"
            }
            $count++
        }
    }
}
Write-Host "Independently audited $count instruction fields."
