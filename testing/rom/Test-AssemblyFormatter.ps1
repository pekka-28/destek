# Test-AssemblyFormatter.ps1

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../Format-Assembly.ps1')
$sample = @'
; sample.asm
Test proc near

 je TestLan1                         ; c287: 74h, 03h
 xor ax,ax ; c289: 33h, c0h
 mov si,offset ALongSymbolThatDoesNotFitTheCommentField ; bytes
 Message 1,2,7,4,'A; B' ; a real comment
 db 'can''t; split',";"
 mov    si,offset MonoCrtcRegisterValues
mov             word    ptr es:[di+2h],si       ; d639: 26h, 89h, 75h, 02h
 cmp byte ptr [bx],0
 push word ptr [bx]
 call dword ptr [bx]
ValueWord word ?
ValueByte byte ?
ValueDword dword ?
 assume ds:nothing
 ret

Test endp
Next proc near
 ret
Next endp
StubOne:
 jmp TargetOne
StubTwo:
 jmp TargetTwo
Values:
 db 1,2
 dw 3
OtherValues:
 db 4
'@
$formatted = Convert-AssemblyLayout $sample
if ((Convert-AssemblyLayout $formatted) -cne $formatted) { throw 'Formatter is not idempotent.' }
$lines = $formatted -split '\r\n'
foreach ($line in $lines | Where-Object { $_ -match '; c28' }) {
    if ((Get-AssemblyColumn $line.Substring(0,$line.IndexOf(';'))) -ne 48) {
        throw 'Short instruction comment is not at column 49.'
    }
}
if ($formatted -notmatch "'A; B'" -or $formatted -notmatch "'can''t; split'") {
    throw 'Quoted text changed.'
}
if ($formatted -notmatch "mov`tsi,offset MonoCrtcRegisterValues") { throw 'Operation spacing differs.' }
if ($formatted -notmatch "`r`n`r`n {16}assume" -or
    $formatted -notmatch "endp`r`n`r`nNext") { throw 'Boundary spacing differs.' }
if ($formatted -match 'proc\s+near\r\n\r\n +je' -or $formatted -match 'ret\r\n\r\nTest') {
    throw 'Procedure body spacing differs.'
}
if ($formatted -notmatch 'TargetOne\r\n\r\nStubTwo:' -or
    $formatted -notmatch 'dw\t3\r\n\r\nOtherValues:') { throw 'Block spacing differs.' }
foreach ($line in $lines | Where-Object { $_ -match '; bytes$' }) {
    $prefix = $line.Substring(0,$line.IndexOf(';'))
    if ((Get-AssemblyColumn $prefix) -ne (Get-AssemblyColumn $prefix.TrimEnd()) + 1) {
        throw 'Long instruction comment overlaps.'
    }
}
foreach ($line in $lines | Where-Object { $_ -match '^ +(?:je|xor|mov|db|dw|Message)\t' }) {
    $tab = $line.IndexOf("`t")
    if ((Get-AssemblyColumn $line.Substring(0,$tab+1)) -ne 24) { throw 'Operand is not at column 25.' }
}
if ($formatted -notmatch "^; sample.asm`r`n`r`nTest {12}proc`tnear") {
    throw 'Named directive operand alignment differs.'
}
foreach ($operation in @('mov','cmp','push','call')) {
    if ($formatted -match ('(?m)^'+$operation+'\s+(byte|word|dword)')) {
        throw 'An instruction with a typed operand was mistaken for a label.'
    }
}
if ($formatted -notmatch '(?m)^ {16}mov\tword ptr es:\[di\+2h\],si') {
    throw 'D639 instruction regression.'
}
foreach ($type in @('Word','Byte','Dword')) {
    if ($formatted -notmatch ('(?m)^Value'+$type+' +'+$type.ToLowerInvariant()+'\t\?')) {
        throw 'Typed data declaration was mistaken for an instruction.'
    }
}
Write-Host 'Assembly formatter fixtures passed.'
