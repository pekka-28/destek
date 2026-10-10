# Inspect-WalkthroughMenu.gdb - menu regression with documentation screenshots

set pagination off
set confirm off
set architecture i8086
set remotetimeout 180
target remote 127.0.0.1:12345
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/00-menu-reset.png'], check=True)
hbreak *0xc8a87
ignore 1 2000
continue
python
import gdb
import os
key = int(os.environ.get('DESTEK_MENU_KEY','3'))
memory = gdb.selected_inferior()
menu = bytes(memory.read_memory(0x8000, 256))
if menu[:2] != b'\0\0' or menu[2:5] != b'\1\0\1':
    raise gdb.GdbError('Downloaded menu header does not match')
if menu[10:40] != b'Hello, world!'.ljust(30) or menu[70:100] != b'Starting, then Hello'.ljust(30):
    raise gdb.GdbError('Downloaded captions do not match')
video = bytes(memory.read_memory(0xb0000, 4000))[::2]
if b'F1: Hello, world!' not in video or b'F3: Starting, then Hello' not in video or b'F2:' in video:
    raise gdb.GdbError('Displayed menu does not match enabled captions')
gdb.write('Verified downloaded menu and enabled F1/F3 captions on MDA\n')
end
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/05-menu.png'], check=True)
dump binary memory testing/boot/86box/Menu.table.bin 0x8000 0x8100
dump binary memory testing/boot/86box/Menu.video.bin 0xb0000 0xb1000
shell powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/86box/Send-FunctionKey.ps1 -Key 2
delete breakpoints
hbreak *0xc8aca
continue
if ($eax & 255) != 1 || ($ebx & 255) != 0
  printf "Disabled F2 did not reach the rejection branch\n"
  quit 1
end
stepi
if $eip != 0xc8a87
  printf "Disabled key did not return to keyboard polling\n"
  quit 1
end
printf "Disabled F2 rejected without a session selection\n"
python
gdb.execute('shell powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/86box/Send-FunctionKey.ps1 -Key %d' % key)
end
delete breakpoints
hbreak *0xc8acc
continue
python
if int(gdb.parse_and_eval('$eax')) & 255 != key-1:
    raise gdb.GdbError('Wrong function-key selection')
gdb.write('ROM accepted F%d through keyboard polling\n' % key)
end
delete breakpoints
hbreak *0xc8934
continue
python
import os
with open(os.environ['DESTEK_TEST_IMAGE'], 'rb') as source:
    expected = source.read()
actual = bytes(memory.read_memory(0x8000,min(256,len(expected))))
if len(expected)>256:
    actual += bytes(memory.read_memory(0x500,len(expected)-256))
if actual != expected:
    raise gdb.GdbError('Selected image differs at handoff')
gdb.write('Verified all %d selected image bytes at handoff\n' % len(expected))
end
delete breakpoints
python
gdb.execute('hbreak *0x%x' % (0x801e if len(expected)==128 else 0x51e))
end
continue
printf "Selected Hello image completed\n"
dump binary memory testing/boot/86box/Menu.completed.video.bin 0xb0000 0xb1000
python
video = bytes(memory.read_memory(0xb0000,4000))[::2]
if b'Hello, world!' not in video or (len(expected)>256 and b'Starting ...' not in video):
    raise gdb.GdbError('Selected application output is missing')
gdb.write('Verified selected application text on MDA\n')
end
detach
python __import__('subprocess').run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'testing/boot/86box/Capture-Window.ps1', '-Path', 'docs/screenshots/06-staged-hello.png'], check=True)
quit


