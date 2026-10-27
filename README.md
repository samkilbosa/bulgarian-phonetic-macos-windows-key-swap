# Bulgarian Phonetic for macOS — Windows-style Ч ↔ § key swap

Move **ч / Ч to the key immediately left of 1** on an ISO Mac keyboard, and move **§ / ± to the key between Left Shift and Z**. This is a persistent custom Bulgarian keyboard layout. Your English layout stays unchanged.

Българска фонетична подредба за macOS: **ч / Ч до 1**, **§ / ± до левия Shift**. Английската подредба остава непроменена.

This project changes two key positions in Apple's **Bulgarian – Phonetic** layout (displayed as **Bulgarian – QWERTY** on the tested macOS version). It does not replace the entire layout with a Windows keyboard layout.

## What changes

| Physical position on the tested ISO keyboard | Original | This layout |
| --- | --- | --- |
| Immediately left of **1**, below Escape | `§`, Shift: `±` | `ч`, Shift: `Ч` |
| Between **Left Shift** and **Z** | `ч`, Shift: `Ч` | `§`, Shift: `±` |

The complete behavior of these two positions is exchanged, including Caps Lock, Option, Command and Control combinations. Other Bulgarian key mappings and accent sequences are preserved in the tested translation cases. English is a separate input source and is not modified.

The custom layout has its own name, **Bulgarian - Phonetic Windows**, and ID, **19530**, so it can coexist with Apple's original. Those are the only metadata changes in the supplied XML comparison.

## Download and install

1. Choose **Code → Download ZIP** on this repository and extract the ZIP. No Git, developer tools, Ukelele, Ruby, or third-party remapping app is needed to use the layout.
2. In the extracted folder, open `layouts`. Install **only** `Bulgarian-Phonetic-Windows.keylayout`. The `reference` folder is for review, not installation.
3. In Finder, choose **Go → Go to Folder…** and enter `~/Library/Keyboard Layouts`. Create the `Keyboard Layouts` folder inside your user's Library if it does not exist.
4. Copy `Bulgarian-Phonetic-Windows.keylayout` into that folder. This is a per-user installation; no `sudo` or protected system-file changes are needed.
5. Open **System Settings → Keyboard → Text Input → Edit…**, click **+**, and search for **Bulgarian - Phonetic Windows**. It may be under **Others**, rather than Bulgarian. Add it. If it is not listed yet, log out and back in or restart, then try again.
6. Keep your current English input source. Test the custom Bulgarian source, then remove the original **Bulgarian – Phonetic / Bulgarian – QWERTY** entry from the active list if you want just two choices. Removing an entry does not delete Apple's built-in layout.
7. For the Globe/Fn key, set **Keyboard → Press 🌐 / Fn key to → Change Input Source**. Globe then cycles through the enabled sources. With just English and this layout enabled, there is no extra Bulgarian choice.

These use the standard macOS input-source controls. See [Apple's input-source settings guide](https://support.apple.com/guide/mac-help/mchl84525d76/mac) and [SIL's keyboard-layout installation reference](https://software.sil.org/ukelele/).

## Use and check after restarting

Select **Bulgarian - Phonetic Windows** from the input menu or with Globe/Fn. Type the upper-left key: `ч`; hold Shift: `Ч`. The lower key should type `§`; hold Shift: `±`. Switch to English and confirm that its behavior is unchanged.

The layout is a file loaded by macOS, so it needs no login launcher, delay, polling job, or `hidutil` command. Keep the file installed and the custom input source enabled. The original user confirmed the **final published layout worked after a reboot**, followed by a fresh full native comparison; see the [post-reboot report](proof/post-reboot-verification.txt) and [test history and scope](proof/README.md).

## Safety and what the evidence proves

The installed item is a **plain XML `.keylayout` file containing character mappings and accent-state rules**. It is not an executable app, keyboard listener, network client, kernel extension, or background service. It requests no Accessibility or Input Monitoring permissions, changes no security settings, and does not edit `/System`. The optional tools in `tools/` are separate review/build utilities; they are not installed or run during normal use.

macOS may show a generic warning that an installed input-source developer can access typed information. This package's installed artifact is the inspectable mapping file, with no executable input method or background process included. Review the file and the checks below before deciding to install it.

**This is a low-impact, reversible layout change; the tests are not a universal guarantee of harmlessness or compatibility.** A mapping mistake could produce unexpected text. Test it in an ordinary text field before using it for passwords or critical input. FileVault's pre-boot unlock screen may use Apple's built-in layouts. The normal login screen and other accounts may also have different input sources.

Evidence included here:

- [Exact XML diff](proof/keyboard-layout.diff): two key references swapped in each of ten unique character maps, plus the layout name and ID. The 256 explicit modifier selectors are unchanged.
- [Reconstructed original reference](reference/Bulgarian-Phonetic.keylayout): normalized XML derived from Apple's native translation API, **not Apple's original source file**. Apple stores the built-in layout in binary form.
- [Verification report](proof/verification.txt): **1,015,808** output comparisons across 31 reachable pairs of accent states, covering 128 virtual keycodes and **all 256 modifier masks**, including separate left/right modifier bits, for each state pair.
- [Proof methodology and limits](proof/README.md), [static diff checker](tools/check_diff.rb), and [native runtime checker](tools/verify_runtime.rb).
- [SHA-256 manifest](SHA256SUMS) for the layout and reference files.

## Remove or revert

1. In **System Settings → Keyboard → Text Input → Edit…**, add Apple's original **Bulgarian – QWERTY / Bulgarian – Phonetic** input source again.
2. Select English or the original Bulgarian layout. Remove **Bulgarian - Phonetic Windows** from the enabled list.
3. In Finder, open `~/Library/Keyboard Layouts` and move **only** `Bulgarian-Phonetic-Windows.keylayout` to Trash. Log out and back in if the input menu has not refreshed.

This restores the original Bulgarian key positions. Your English input source remains unchanged throughout. There is no daemon, launch agent, app, or system remap to uninstall.

## Compatibility and scope

Tested on **macOS 27.0.1, build 26A434**, with an **internal ISO Mac keyboard**. The final native comparison reported keyboard type **92**; the same Mac reported **198** earlier in the session. The physical keyboard has the extra key between Left Shift and Z. Other macOS versions and external keyboard models have not been physically tested. ANSI keyboards do not have that extra physical key, so this particular swap is intended for ISO keyboards.

The source is Apple's Bulgarian Phonetic/QWERTY layout from that macOS version. It is not Bulgarian BDS, and “Windows-style” refers to the requested **Ч key position**, not to a claim of complete Windows layout equivalence.

## Reproduce the checks or build

Optional developer checks, run from the extracted repository folder:

```sh
# No installation needed; checks the two XML files and exact diff.
ruby tools/check_diff.rb

# After installing/enabling the custom layout on macOS:
ruby tools/verify_runtime.rb

# Build fresh XML exports from the local Apple Bulgarian layout.
# Writes only to the specified output directory; does not install or activate.
ruby tools/build.rb ./generated
```

Ruby and the macOS Carbon/CoreFoundation frameworks are used only by the optional tools. The native checker reports differences if Apple changes its source layout. Inspect and test fresh builds rather than assuming a newer macOS version has identical mappings.

Search terms: Bulgarian phonetic macOS, Bulgarian QWERTY Mac, Windows Ч key, ч до 1, § key swap, ISO keyboard, permanent Bulgarian keyboard layout, Ukelele keylayout, hidutil alternative.
