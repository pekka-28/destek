# Capture the unchanged ROM and minimal Hello, with independent memory assertions.
# Run from the repository root through Start-86Box.ps1.
set pagination off
set confirm off
set architecture i8086
set remotetimeout 180
python __import__('os').makedirs('testing/boot/walkthrough', exist_ok=True)
target remote 127.0.0.1:12345
hbreak *0xc8003
continue
printf "STEP 1 BIOS enters original ROM at c800:0003\n"
info registers cs eip ss esp
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/01-bios-entry.png'], check=True)
delete breakpoints
hbreak *0xc85ce
ignore 2 20
continue
printf "STEP 2 ROM initialized, IBM UART selected; early UART interrupt\n"
info registers cs eip ds ss esp
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/02-rom-loading.png'], check=True)
delete breakpoints
hbreak *0xc885e
continue
printf "STEP 3 Download received, waiting for transmit completion\n"
info registers cs eip
python
import gdb
memory = gdb.selected_inferior()
with open('boot/Hello.bin', 'rb') as source:
    expected = source.read()
assert len(expected) == 128
assert bytes(memory.read_memory(0x8000,128)) == expected, 'Downloaded Hello differs'
assert bytes(memory.read_memory(0xb0000,1)) == b'"', 'Expected two TRANSFER increments'
gdb.write('PASS: all 128 downloaded bytes match; progress character is 22h\n')
end
dump binary memory testing/boot/walkthrough/Hello.loaded.bin 0x8000 0x8080
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/03-download-complete.png'], check=True)
delete breakpoints
hbreak *0xc8934
continue
printf "STEP 4 ROM far handoff after BIOS restoration\n"
info registers cs eip ss esp
delete breakpoints
hbreak *0x8000
continue
printf "STEP 5 Downloaded entry at 0040:7c00\n"
info registers cs eip ss esp
delete breakpoints
hbreak *0x801e
continue
printf "STEP 6 Hello completion at 0800:001e\n"
info registers cs eip ds
python
video = bytes(memory.read_memory(0xb0000,4000))
assert video[0:26:2] == b'Hello, world!', 'Hello output missing'
assert video[1:26:2] == bytes([7])*13, 'Hello attributes differ'
gdb.write('PASS: Hello executed and MDA text and attributes match\n')
end
dump binary memory testing/boot/walkthrough/Hello.video.bin 0xb0000 0xb1000
detach
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/04-hello.png'], check=True)
quit

