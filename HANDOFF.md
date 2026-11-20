# Omarchy on MacBook Pro 16" M5 Max (J716c): handoff

Written from macOS on the same Mac, 2026-11-20, for the agent that continues inside Linux. The owner speaks Russian, wants things done for him, accepts reinstalling (it is fast). macOS must stay intact.

## Machine

- Mac17,6, `apple,j716c`, J716cAP, chip T6050 (M5 Max), 18 CPU cores, 128 GB, 2 TB.
- macOS 27.3 beta 2 (26C5047e), system iBoot `mBoot-20457.60.77.501.2`.
- Disk: macOS APFS ~337 GB (disk0s2); Omarchy stub APFS 6 GB; ESP FAT32 "EFI - OMARC" 512 MB; Linux /boot 1.1 GB; Linux root ~1.7 TB.

## How it was installed

Aurora Installer v0.1.0-alpha.22, rebuilt locally as a developer build with the Omarchy profile (`AURORA_ENABLE_OMARCHY=1`) because the public build hides it. Catalogs are the official signed ones (key sha256:5e510a66…). Payload: `aurora-silicon/omarchy-aurora` release `payload-omarchy-hyprland-44239549153` (2026-11-18), kernel `linux-aurora 7.3.0.aurora1-40`, aura `1.0.0b13.1` (commit 5dcf62d0), mesa-aurora 26.3.0-devel d4ad4a4d.

Local installer patch (`aurora-installer-j716c-27.3.patch` here):
1. Stub firmware for j716c = macOS **27.3 beta 1 (26C5035r)** IPSW instead of 27.2 (26B123). Reason: Apple's 27.2 iBoot brings up only one CPU on M5 Pro/Max with a custom boot object; fixed in 26C5035r. Beta 1, not beta 2, because aura only knows iBoot `mBoot-20457.60.65.0.1` (aura #216, V27_3B).
2. Common Stage 1 admitted on "27.3" for j716cap.
3. Stub manifest read budget 32 MB → 64 MB (27.3 BuildManifest.plist is 36.5 MB).

First install (27.2 firmware) booted but felt like one core; that install was erased and reinstalled with the patch above.

## First things to check

```
nproc                                   # expect 18
ls /dev/dri                             # renderD128 = GPU driver bound
journalctl -k -b | grep -iE "asahi|gpu|dcp|smp|secondary" | head -50
cat /proc/cmdline; uname -r
ls -la /boot/efi /boot/efi/m1n1 2>/dev/null || findmnt -t vfat
```

## Goal: GPU acceleration

Needed pieces (none of them are in the installed payload for M5 Max on 27.3):

| Piece | Source | State 2026-11-20 |
|---|---|---|
| Aura stage 2 that hands the G17C (M5 Max) GPU over on 27.3 | aurora-silicon/aura `main` (82ee5d6f) + PR #172 (head 81883316) | open PR; built fine on macOS: `make USE_CLANG=1 BUILDSTD=1 CHAINLOADING=1 ESP_STAGE2=1` → build/aura.bin (~3.9 MB) |
| Kernel drm/asahi that accepts the 27.3 G17C firmware | aurora-silicon/linux `integration/aurora` + PR #1602 (head 7617bd03) | open PR |
| DCP (display) 27.3 method table | aurora-silicon/linux PR #1816 (head 337fdca4) | open PR |
| J716c device tree | aurora-silicon/linux `arch/arm64/boot/dts/apple/t6050-j716c*.dts*` | in tree |
| Mesa | mesa-aurora already installed | ok |

Reference recipe (different board, K114c 14" OLED, same chip): https://joshuawarren.com/blog/omarchy-m5-proled-complete-recipe/ and https://joshuawarren.com/blog/omarchy-on-the-m5-max-macbook-pro/
J716c prior art (RAM boot only, 27.2.1): cameroncooper in https://github.com/omacom/linux-aurora/issues/293

Kernel build rules from those notes: clang `LLVM=1` (BTI: modules built without it fault), Rust on (GPU driver is Rust), start from the running config (`zcat /proc/config.gz`), keep `CONFIG_ARM64_MTE` off unless aura reserves the tag store (aura #184 is in main).

## Boot chain on this install

iBoot (26C5035r stub) → Aurora common Stage 1 (padded Mach-O, CTXR window) → confined Stage 2 from the ESP. Payload board files: `esp/m1n1/boot-j716c.bin` and `esp/m1n1/boot-ctxr-j716c.bin` (confined slot limit 16 MiB). Inspect the live ESP before replacing anything; the stage 2 file may carry an appended config (`boot=…`, `chosen.bootargs=…`) that must be preserved.

## Safety rules

- Before replacing any file on the ESP or /boot: copy the original next to it (`*.orig`), `sync`, verify sha256 after writing.
- Rollback without Linux: hold power → Macintosh HD → in macOS the ESP is disk0s4 (`sudo diskutil mount disk0s4`), copy `*.orig` back. Worst case: Aurora Installer → Erase Linux → reinstall (~30 min).
- Never touch disk0s2 (macOS) or the Apple recovery partitions.
- Speakers: do not raise volume before speaker protection (speakerguardd) is confirmed running.

## Files on the Mac (macOS side, not reachable from Linux)

`~/omarchy-j716c/`: `src/` patched installer source, `aura-main/` aura main + #172, `gpu-prep/aura-main-pr172.bin`, `release/` sealed catalogs, installer pkg.
