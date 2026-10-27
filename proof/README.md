# Verification: two swapped keys, with explicit limits

The installed layout and the repository's `layouts/Bulgarian-Phonetic-Windows.keylayout` were confirmed byte-identical. Their SHA-256 is:

```text
fc51a9afa8091b4a58cd20bbfd41e1b99d58c3a750bfadce378cecce3347bb25
```

## 1. Structural comparison

The reference is a normalized XML reconstruction of Apple's Bulgarian Phonetic mappings. In the original Mac layout, the upper physical ISO key reports virtual keycode **10**, and the lower key reports **50**. These are macOS virtual keycodes, not USB HID usage IDs.

The custom XML differs from the reference in exactly:

- Keycode 10 refers to keycode 50's action, and keycode 50 refers to keycode 10's action, in each of ten unique character maps: **20 changed key entries**. All **256 explicit modifier selectors** are identical. Equivalent modifier masks share a character map to avoid duplicating the same action tables.
- Layout name: `Bulgarian - Phonetic` → `Bulgarian - Phonetic Windows`.
- Layout ID: `19529` → `19530`.

All modifier definitions, other key references, action definitions, state transitions, and terminators are byte-identical between the two exports. `ruby tools/check_diff.rb` independently enforces this relationship and regenerates the expected unified diff in memory to check the published patch.

The reference and custom XML deliberately share a representation. This makes the structural diff easy to review, but a shared representation alone cannot establish fidelity to Apple. That requires the separate runtime comparison below.

## 2. Independent comparison with Apple's compiled layout

`tools/verify_runtime.rb` asks macOS for both registered layouts using Text Input Source Services. It obtains each compiled Unicode keyboard mapping and uses `UCKeyTranslate` to compare:

```text
custom(key, modifiers, custom_state)
    == Apple(swap(key), modifiers, original_state)
```

Here `swap(10) = 50`, `swap(50) = 10`, and every other key is unchanged. The checker starts at each layout's neutral state, compares the emitted text, and follows the resulting pairs of next states. State numbers may differ internally; the comparison uses their reachable behavior, not numeric equality.

Coverage per reachable state pair:

- macOS virtual keycodes 0–127;
- all 256 masks covering Command, left Shift, Caps Lock, left Option, left Control, right Shift, right Option, and right Control;
- all next-state pairs reachable through those inputs, including accent/dead-key sequences.

The observed result was **1,015,808 matching translations across 31 reachable state pairs**. The checker performs no installation, registration, source selection, preference writes, or network calls.

This is an independent behavioral check against Apple's compiled mapping through Apple's API. It is not a byte comparison against Apple's binary file, and the report does not claim Apple's original source XML is available.

## 3. Physical use and persistence

The original user physically typed `ч/Ч` from the upper key and `§/±` from the lower key, then rebooted and confirmed correct operation again on 27 October 2026. This confirmed the per-user installation mechanism on one Mac.

Before publication, an expanded test found that the first export merged left/right modifiers, causing right Shift with Caps Lock to differ from Apple. The export was corrected to use all 256 explicit modifier masks, rebuilt, installed, re-registered, and checked again. The final published hash above passed the expanded native comparison.

The user then rebooted the Mac again and confirmed correct physical typing with the final published revision. A fresh native comparison after that reboot again passed all **1,015,808 translations**, with the installed file matching the repository artifact byte for byte. The static XML comparison also passed, and all 4,096 saved British translation cases remained unchanged. The saved input-source configuration retained British and the custom Bulgarian source. `hidutil` reported no active UserKeyMapping values. See [post-reboot-verification.txt](post-reboot-verification.txt). This remains verification on one Mac, not certification for all hardware or macOS versions.

English was not edited or replaced. On the tested Mac, British remained the separate English input source; a before/after comparison of its 4,096 neutral-state translation results matched. Personal preference backups and machine-specific rollback scripts are intentionally excluded from this public repository.

## What is not established

These checks do not certify every macOS release, keyboard type, app-specific shortcut, hardware event path, login or FileVault screen, or every possible input action such as key-up. Native comparisons cover all eight classic modifier bits, but do not exercise Globe/Fn/media-key hardware events. They use key-down translation and the hardware type reported on the machine that runs the checker.

The XML includes a general hardware range, but the exported behavior was taken from the tested ISO keyboard type. The ANSI layout and other hardware have not been physically validated. The two moved positions also exchange their modified/shortcut behavior; the claim is preservation of every **other** mapping within the tested cases.

No test can prove that all future use is harmless. The concrete safety properties are the small mapping scope, inspectable non-executable installed artifact, absence of a background program or security-setting changes, per-user installation, and straightforward removal. Compatibility problems remain possible and should be reported with macOS version and keyboard type.

## Files and provenance

- `verification.txt`: fresh report from the public read-only checker.
- `post-reboot-verification.txt`: repeat checks after the final revision's reboot and the user's physical-typing confirmation.
- `keyboard-layout.diff`: exact unified diff between the reconstructed reference and custom XML.
- `../tools/build.rb`: reads the local Apple layout and writes both normalized exports.

The table data was obtained locally from `com.apple.keylayout.Bulgarian-Phonetic` using macOS APIs. No personal preferences, credentials, typed content, or other user data are needed to reproduce it.
