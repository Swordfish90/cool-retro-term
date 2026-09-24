# cool-retro-term

|> Default Amber|C:\ IBM DOS|$ Default Green|
|---|---|---|
|![Default Amber Cool Retro Term](https://user-images.githubusercontent.com/121322/32070717-16708784-ba42-11e7-8572-a8fcc10d7f7d.gif)|![IBM DOS](https://user-images.githubusercontent.com/121322/32070716-16567e5c-ba42-11e7-9e64-ba96dfe9b64d.gif)|![Default Green Cool Retro Term](https://user-images.githubusercontent.com/121322/32070715-163a1c94-ba42-11e7-80bb-41fbf10fc634.gif)|

## Description
cool-retro-term is a terminal emulator which mimics the look and feel of the old cathode tube screens.
It has been designed to be eye-candy, customizable, and reasonably lightweight.

It uses the QML port of qtermwidget (Konsole): https://github.com/Swordfish90/qmltermwidget.

This terminal emulator works under Linux and macOS and requires Qt6.

Settings such as colors, fonts, and effects can be reached from the settings
window (`Ctrl+,` on Linux and Windows, `Cmd+,` on macOS). By default the
terminal starts in a "nostalgic" mode: no menu bar, no tab strip, no context
menu and no overlays are ever shown, so nothing on screen hints at the
graphical interface behind it. Every feature stays reachable from the
keyboard.

## Screenshots
![Image](<https://i.imgur.com/TNumkDn.png>)
![Image](<https://i.imgur.com/hfjWOM4.png>)
![Image](<https://i.imgur.com/GYRDPzJ.jpg>)

## Install

If you want to get a hold of the latest version, just go to the Releases page and grab the latest AppImage (Linux) or dmg (macOS).

Alternatively, most distributions such as Ubuntu, Fedora or Arch already package cool-retro-term in their official repositories.

## Building

Check out the wiki and follow the instructions on how to build it on [Linux](https://github.com/Swordfish90/cool-retro-term/wiki/Build-Instructions-(Linux)) and [macOS](https://github.com/Swordfish90/cool-retro-term/wiki/Build-Instructions-(macOS)).

## Keyboard shortcuts

The bindings follow the convention of each platform, so the same function
always sits where the OS puts it.

| Function        | Linux / Windows     | macOS                |
|-----------------|---------------------|----------------------|
| New window      | `Ctrl+Shift+N`      | `Cmd+N`              |
| New tab         | `Ctrl+Shift+T`      | `Cmd+T`              |
| Close tab       | `Ctrl+W`            | `Cmd+W`              |
| Close window    | `Ctrl+Shift+W`      | `Cmd+Shift+W`        |
| Next window     | ``Alt+` ``          | ``Cmd+` ``           |
| Previous window | ``Alt+Shift+` ``    | ``Cmd+Shift+` ``     |
| Settings        | `Ctrl+,`            | `Cmd+,`              |
| Fullscreen      | `F11`               | `Cmd+Ctrl+F`         |
| Copy / Paste    | `Ctrl+Shift+C/V`    | `Cmd+C/V`            |
| Zoom in / out   | `Ctrl++` / `Ctrl+-` | `Cmd++` / `Cmd+-`    |
| Quit            | `Ctrl+Shift+Q`      | `Cmd+Q`              |

Optional IBM 3270 style extras live in the *Retro* tab of the settings
window: the on-screen PF/PA key legend (F1..F12 plus Ctrl+F1..Ctrl+F3 for the
program attention keys), the key click of a 1980s terminal, the attention
bell, the iTerm2 style highlight of the cursor's row and the block/half block
cursor. The legend is drawn inside the phosphor and deliberately has no mouse
handling at all: it is reachable by eye, never by cursor.

## Tests

Two suites cover the retro feature set:

```bash
# Pure logic: key map, PF/PA model, window cycling, chrome visibility,
# sound gating, settings round trip (no Qt required).
node --test

# Qt Quick suite driving the QML the application ships: PF legend, line
# highlight, sound manager, key observation, shared logic modules.
mkdir -p build/tests && cd build/tests
qmake ../../tests/tests.pro          # tests are also built by
make -j"$(nproc)"                    # `qmake CONFIG+=build_tests` at the top
QT_QPA_PLATFORM=offscreen ./tst_retroterm
```

Both suites run in CI on every push.
