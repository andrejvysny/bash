Windows: found a likely cause in the installer hook. Checking the other two issues in code.

The macOS delay lines up with auth's 5-minute release cache (RELEASE_CACHE_SECONDS = 300), since checks just after the 00:13 publish still got the old answer. I'm now checking the Windows shortcut behavior in Tauri's installer template.

Root causes found for all three. Checking my analysis before writing it up.

Zataino is most likely installed on the Windows VM; it's just left without shortcuts. All three issues are explained below, and the Windows one is serious: **every Windows install that updates from a BlackPen version loses its shortcuts the same way.** I haven't changed anything yet.

## 1. Windows: the app is installed, but has no shortcuts

How the update goes:
1. The old BlackPen app downloads `Zataino_Windows_x64-setup.exe` and runs it with `/UPDATE`. That's how Tauri's updater always starts the installer (`tauri-plugin-updater` 2.10.1, `updater.rs:812`).
2. **Our hook in desktop#139** (`src-tauri/windows/hooks.nsh`) finds the old BlackPen install, runs its uninstaller with data kept, then **deletes `BlackPen.lnk` from the Start menu and the desktop**.
3. The installer has no previous Zataino location on record, so it installs fresh to **`%LOCALAPPDATA%\Zataino`**, with a new "Apps & features" entry `Zataino`.
4. **Tauri's installer creates no shortcuts in update mode**: both shortcut functions return early when `$UpdateMode = 1`. It assumes the old ones still exist under the same name, and our hook just deleted them.
5. The installer then relaunches the app from the new folder, which is why you saw 0.3.15 running.

Result: installed, but nothing in the Start menu or on the desktop, and the Start menu search uses those shortcuts. A manual install from zataino.com isn't affected, because it doesn't run in update mode.

**Fix proposal** for `hooks.nsh`: in the pre-install step, remember that BlackPen was removed. Then in a post-install step, create `Zataino.lnk` in the Start menu (and on the desktop if BlackPen had one there), with the same app ID Tauri sets. Installs already on 0.3.15 are fixed by the next in-app update, which still runs in update mode, so the post-install step also has to create the Start menu shortcut whenever it's missing. A test on the alpha channel with the VM snapshot comes before any public release.

## 2. Signing in again after the update (Mac and Windows)

This was built that way: desktop#139 commit `8c9f7e9`, "ask for a new sign-in when Clerk moves". If the saved sign-in was made at a different Clerk host than the one built into the app, it counts as ended. The aim was to avoid old builds silently waiting forever on a dead `clerk.blackpen.sk`.

The `clerk.blackpen.sk` pass-through changed that premise: sessions made by old builds since tonight are already on the new Clerk instance domain. So **every v0.3 user now signs in twice**: once in the old app, and once more after the update. A possible fix is to try the saved session at `clerk.zataino.com` first, and count it as ended only if Clerk refuses it. That's only worth doing if a real test shows Clerk accepts such a session (an old build signed in through the pass-through, then updated to a test build).

## 3. macOS "You have the latest version" right after the release

auth keeps the latest release in memory for **5 minutes** (`RELEASE_CACHE_SECONDS = 300` in `installers/releases.py`). Checks in the first minutes after the 00:13 publish still got v0.3.14. That fits restarting three times before it worked, but I haven't compared it with the request logs. The app also only checks at launch or when you click the button. If it matters, the cache can be cut, or emptied when a release is published.

## Checking the Windows 11 VM

**Take a VM snapshot first.** The current broken state is the test case for the fix.

Then in PowerShell, as the same user who uses the app (not as administrator). The comments say what each command should show if my analysis is right.

```powershell
# 1. Installed? Expect Zataino.exe here
Get-ChildItem "$env:LOCALAPPDATA\Zataino" | Select-Object Name, Length, LastWriteTime
```

```powershell
# 2. Old folder gone? Expect: False
Test-Path "$env:LOCALAPPDATA\BlackPen"
```

```powershell
# 3. "Apps & features" entries: expect Zataino with InstallLocation ...\Zataino, and no BlackPen key
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Zataino","HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\BlackPen" -ErrorAction SilentlyContinue | Select-Object PSChildName, DisplayName, DisplayVersion, InstallLocation
```

```powershell
# 4. Shortcuts: expect no Zataino.lnk or BlackPen.lnk anywhere
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs","$([Environment]::GetFolderPath('Desktop'))" -Filter *.lnk -Recurse | Where-Object Name -match 'Zataino|BlackPen' | Select-Object FullName
```

```powershell
# 5. With the app open: where does it run from? Expect ...\AppData\Local\Zataino\Zataino.exe
Get-Process | Where-Object { $_.Path -match 'Zataino|BlackPen' } | Select-Object Name, Path
```

```powershell
# 6. Data kept? Expect com.blackpen.desktop with the database
Get-ChildItem "$env:APPDATA\com.blackpen.desktop","$env:LOCALAPPDATA\com.blackpen.desktop" -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime
```

How to read the results:

| Finding | Meaning |
|---|---|
| 1 shows `Zataino.exe`, 3 shows the Zataino key, 4 shows nothing | installed without shortcuts (my diagnosis) |
| 1 is empty and 3 has no Zataino key | really not installed |
| `Zataino.exe` sits in `...\BlackPen` | installed into the old folder |

**Last step, after the snapshot:** download the installer from zataino.com and run it by hand. It runs as a normal install, not an update, so it should create the shortcuts again, with documents and licence kept. If it does, that's the workaround for affected testers until the fix ships.

## Containment

v0.3.15 is the public latest right now. Every Windows v0.3 install that signs in and accepts the update loses its shortcuts. Option: mark v0.3.15 as a **pre-release** on GitHub.
- auth then serves v0.3.14 again as the latest, within the 5-minute cache.
- Macs already on 0.3.15 stay there; the updater doesn't downgrade.
- The website download goes back to BlackPen v0.3.14. Its file names still work (auth#22), and it signs in through the pass-through.
- Then re-publish once a fixed build is tested.

I haven't checked this fallback live, so I'd confirm it right after marking. Nothing changes until you decide.

Should I pause v0.3.15 by marking it pre-release until the Windows fix ships, or keep it public?
