# Boot checks

Run from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/Test-Distribution.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/Test-ReplayFailure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File testing/boot/Test-MenuTraces.ps1
```

These check the standalone boot package, replay failures and the supplied menu traces.
For execution, follow [EmulatorSetup.md](../../docs/EmulatorSetup.md).
Use Build-HelloImages.ps1 to rebuild the examples with MASM.
