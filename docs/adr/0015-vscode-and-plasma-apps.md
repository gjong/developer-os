# ADR-0015: Code - OSS and Plasma-native desktop apps

## Status

Accepted

## Context

After [ADR-0011](0011-kde-plasma-wayland-session.md) the desktop is Plasma, but the image still shipped **Thunar** and **grim/slurp** from the Hyprland-era profile. Java, .NET, and web users also had no editor until they downloaded a JetBrains IDE from Toolbox.

The Phase 2 audit asked for a VS Code path. Arch extra has **Code - OSS** (`code`). Flathub has **Microsoft Visual Studio Code** (`com.visualstudio.code`), which is required for Microsoft C# Dev Kit. Brave is already a Flatpak and can fail when Flathub is unreachable during the ISO build.

## Decision

1. Ship **`code`** (Code - OSS) from extra on the live image and the disk package list so an editor is present without network or a JetBrains license. Keep **JetBrains Toolbox** for IntelliJ IDEA, Rider, and WebStorm.
2. Do **not** preinstall Microsoft VS Code. Document `flatpak install flathub com.visualstudio.code` for users who need C# Dev Kit or the Microsoft marketplace.
3. Replace **Thunar** / **thunar-volman** with **Dolphin**, and **grim** / **slurp** with **Spectacle**. Keep **gvfs** and **wl-clipboard**.
4. Set system MIME defaults in `/etc/xdg/mimeapps.list` so directories open in Dolphin.

## Consequences

**Positive:** Day-one editor on PATH; Plasma file manager and screenshots match the desktop; no extra Flathub dependency for the editor.

**Negative / trade-offs:** Code - OSS does not run Microsoft C# Dev Kit; ISO grows by the Electron `code` package; users who want the Microsoft build take an extra Flatpak step.

**Follow-up:** None required for this decision. Workflow extras (direnv, mkcert, HTTP/DB clients) remain Phase 3.
