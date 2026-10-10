; OptionRomPcNetRuntimeTemplate.inc

; PC-NET static data; relocation begins at its d690h tail.

PcNetDriverData:
                db	3ch, 02h, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 09h, 06h, 09h, 06h, 09h, 06h, 09h, 06h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 09h, 06h, 09h, 06h, 09h, 06h, 09h, 06h, 09h, 06h, 0ffh, 0ffh, 00h
                db	00h, 00h, 00h, 00h, 00h, 58h, 02h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0fh, 01h, 00h, 00h, 00h, 00h, 00h
                db	00h, 0ah, 0ffh, 00h, 00h, 0ffh, 00h, 00h, 00h, 00h, 00h, 00h, 0ffh, 00h, 00h, 00h
                db	04h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, 30h, 30h, 58h, 47h, 4dh, 00h, 00h
                db	00h, 00h, 00h, 00h, 0ch, 08h, 00h, 26h, 00h, 60h, 00h, 0f2h, 02h, 04h, 40h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 07h, 00h, 0f5h, 01h, 01h, 00h, 00h, 00h, 00h
                db	1ah, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 21h, 08h, 0ffh, 0ch, 4bh, 0bh, 00h
                db	82h, 00h, 06h, 00h, 06h, 19h, 07h, 00h, 07h, 03h, 0ah, 61h, 08h, 0ffh, 0ch, 4bh
                db	0bh, 00h, 82h, 00h, 06h, 00h, 06h, 00h, 07h, 00h, 07h, 03h, 0ah, 61h, 00h, 0ffh
                db	0ch, 47h, 0bh, 00h, 82h, 00h, 06h, 00h, 06h, 00h, 07h, 00h, 07h, 03h, 0ah, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	00h, 0feh, 0ffh, 00h, 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                db	01h, 80h, 00h, 00h, 00h, 00h

Crc16Table:
                dw	0000h, 0c0c1h, 0c181h, 0140h, 0c301h, 03c0h, 0280h, 0c241h
                dw	0c601h, 06c0h, 0780h, 0c741h, 0500h, 0c5c1h, 0c481h, 0440h
                dw	0cc01h, 0cc0h, 0d80h, 0cd41h, 0f00h, 0cfc1h, 0ce81h, 0e40h
                dw	0a00h, 0cac1h, 0cb81h, 0b40h, 0c901h, 09c0h, 0880h, 0c841h
                dw	0d801h, 18c0h, 1980h, 0d941h, 1b00h, 0dbc1h, 0da81h, 1a40h
                dw	1e00h, 0dec1h, 0df81h, 1f40h, 0dd01h, 1dc0h, 1c80h, 0dc41h
                dw	1400h, 0d4c1h, 0d581h, 1540h, 0d701h, 17c0h, 1680h, 0d641h
                dw	0d201h, 12c0h, 1380h, 0d341h, 1100h, 0d1c1h, 0d081h, 1040h
                dw	0f001h, 30c0h, 3180h, 0f141h, 3300h, 0f3c1h, 0f281h, 3240h
                dw	3600h, 0f6c1h, 0f781h, 3740h, 0f501h, 35c0h, 3480h, 0f441h
                dw	3c00h, 0fcc1h, 0fd81h, 3d40h, 0ff01h, 3fc0h, 3e80h, 0fe41h
                dw	0fa01h, 3ac0h, 3b80h, 0fb41h, 3900h, 0f9c1h, 0f881h, 3840h
                dw	2800h, 0e8c1h, 0e981h, 2940h, 0eb01h, 2bc0h, 2a80h, 0ea41h
                dw	0ee01h, 2ec0h, 2f80h, 0ef41h, 2d00h, 0edc1h, 0ec81h, 2c40h
                dw	0e401h, 24c0h, 2580h, 0e541h, 2700h, 0e7c1h, 0e681h, 2640h
                dw	2200h, 0e2c1h, 0e381h, 2340h, 0e101h, 21c0h, 2080h, 0e041h
                dw	0a001h, 60c0h, 6180h, 0a141h, 6300h, 0a3c1h, 0a281h, 6240h
                dw	6600h, 0a6c1h, 0a781h, 6740h, 0a501h, 65c0h, 6480h, 0a441h
                dw	6c00h, 0acc1h, 0ad81h, 6d40h, 0af01h, 6fc0h, 6e80h, 0ae41h
                dw	0aa01h, 6ac0h, 6b80h, 0ab41h, 6900h, 0a9c1h, 0a881h, 6840h
                dw	7800h, 0b8c1h, 0b981h, 7940h, 0b801h, 7bc0h, 7a80h, 0ba41h
                dw	0be01h, 7ec0h, 7f80h, 0bf41h, 7d00h, 0bdc1h, 0bc81h, 7c40h
                dw	0b401h, 74c0h, 7580h, 0b541h, 7700h, 0b7c1h, 0b681h, 7640h
                dw	7200h, 0b2c1h, 0b381h, 7340h, 0b101h, 71c0h, 7080h, 0b041h
                dw	5000h, 90c1h, 9181h, 5140h, 9301h, 53c0h, 5280h, 9241h
                dw	9601h, 56c0h, 5780h, 9741h, 5500h, 95c1h, 9481h, 5440h
                dw	9c01h, 5cc0h, 5d80h, 9d41h, 5f00h, 9fc1h, 9e81h, 5e40h
                dw	5a00h, 9ac1h, 9b81h, 5b40h, 9901h, 59c0h, 5880h, 9841h
                dw	8801h, 48c0h, 4980h, 8941h, 4b00h, 8bc1h, 8a81h, 4a40h
                dw	4e00h, 8ec1h, 8f81h, 4f40h, 8d01h, 4dc0h, 4c80h, 8c41h
                dw	4400h, 84c1h, 8581h, 4540h, 8701h, 47c0h, 4680h, 8641h
                dw	8201h, 42c0h, 4380h, 8341h, 4100h, 81c1h, 8081h, 4040h

Crc16TableTrailer:
                dw	030fh
