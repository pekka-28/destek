<!-- ChannelTrace.md -->

# Channel traces and playback

Each row contains an ISO 8601 timestamp with offset, a tab, an event name
padded to eight columns, a tab, and the event body. Direction is relative
to the host running the sender. *Table Channel events* defines the records.

*Table Channel events*

| Event | Representation | Meaning |
| --- | --- | --- |
| Comment | Readable | Trace filename, contents, and expected outcome |
| Send | Hex | Exact wire octets submitted for transmission |
| Sent | Readable | Decoded frame or replay transmission description |
| Receive | Hex | Exact octets returned by a serial or pipe read |
| Received | Readable | Completed decoded frame, or input matched in replay |
| Status | Readable | Connection, readiness, and retry events |
| Expected | Hex | Expected input when replay detects a mismatch |
| Complete | Readable | Acknowledged image transfer or completed playback |

Receive records preserve the actual read boundaries, which may split a
frame or contain several frames. The interpreter emits Received only after
assembling a complete frame. *Table START trace example* shows the raw and
readable forms of a transmitted frame.

*Table START trace example*

| Timestamp | Event | Body |
| --- | --- | --- |
| `2026-09-09T14:40:02.0000000+02:00` | Send | `AA F5 00 00 FF 73 8C AA FE` |
| `2026-09-09T14:40:02.0010000+02:00` | Sent | `START 00 00 FF [8C73]` |

Readable messages show the message name, ADDR/LOCAL/REMOTE fields, optional
application command and content, and CRC in brackets. Printable payloads
use quoted text; binary payloads use hex in braces. REQUEST identifies a
client DATA record requesting initial control or a range of slots. POLL
identifies the distinct waiting-state message; they are not interchangeable.

# Replay timing and matching

Playback consumes only Send and Receive records. Comment and other readable
records do not affect timing or bytes. Hex must be well formed and timestamps
must be monotonically nondecreasing.

Receive waits for and compares the specified bytes regardless of how the
new reads are split. The next Send uses the recorded gap from the preceding
raw event, anchored to when that event actually occurred. Late input thus
shifts subsequent sending instead of allowing it to run ahead. A monotonic
clock controls the delays; scheduling lag is recorded.

A different byte raises a terminating error identifying the record, byte
position, expected value, and received value. Disconnects and missing input
also fail; the default receive allowance is ten seconds beyond the expected
arrival. Playback never skips mismatches or switches to the interpreter.

Use Send mode to capture a new image exchange, as described in the
[package instructions](README.md). Replay sends the recorded bytes exactly;
it does not repair CRCs, counters, or deliberately invalid test frames.
Keep replay input separate from its output log.
