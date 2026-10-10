# Inspect-Hello.gdb

set pagination off
set confirm off
set architecture i8086
set remotetimeout 180
target remote 127.0.0.1:12345
hbreak *0xc8003
continue
printf "Original option ROM entry\n"
info registers
delete breakpoints
hbreak *0xc885e
continue
printf "ROM transfer wait\n"
info registers
x/16bx 0x1fa36
x/16bx 0x40
x/64bx 0x400
dump binary memory testing/boot/86box/Hello.loaded.bin 0x8000 0x8080
dump binary memory testing/boot/86box/Hello.workspace.bin 0x1fa00 0x1fc00
delete breakpoints
hbreak *0xc8934
python
import threading
timer = threading.Timer(1, lambda: gdb.post_event(lambda: gdb.execute('interrupt')))
timer.daemon = True
timer.start()
end
continue
python timer.cancel()
printf "Transfer wait outcome\n"
info registers
x/32bx 0x1fa46
if $eip != 0xc8934
  printf "ERROR: far handoff not reached\n"
  quit 1
end
delete breakpoints
hbreak *0x8000
continue
printf "Hello entry\n"
info registers
delete breakpoints
hbreak *0x801e
continue
printf "Hello completion loop\n"
info registers
dump binary memory testing/boot/86box/Hello.video.bin 0xb0000 0xb1000
detach
shell powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/86box/Capture-Window.ps1 -Path testing/boot/86box/Hello-screen.png
quit
