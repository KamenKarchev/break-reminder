# Break Reminder
Simple KDE Plasma widget that reminds you to rest regularly :)

It also gives health tips and motivational quotes to encourage you to take care of yourself.

![imagen](https://github.com/user-attachments/assets/672c8468-a435-4775-bec1-920aacfa49c9)

## Usage
- Left-click: Open the popup (Start Focus / Start Deny Timer / status).
- Right-click: Access widget configuration.

### Deny mode
After a focus session ends, the widget enters **deny mode** for the configured break length: if the desktop is unlocked, it forces the machine back to sleep (`loginctl suspend`) after a configurable grace period, in a loop, until the break window elapses. There is no override once it starts — this is by design. You can also start a deny-mode timer manually from the popup, without a prior focus session.

### KOrganizer integration (optional)
Tag today's KOrganizer events/todos with a **Category** of `f`, `s`, or `b`:
- `f` (free): plain notifications only, no enforcement, for that time range.
- `s` (strict): the normal focus → break → deny-mode cycle applies as usual.
- `b` (blocked): the entire mapped time range is deny mode, unconditionally.

This requires building the `korg-helper` C++ tool (see Development below), then enabling it and pointing at the built binary in the widget's configuration.

## Installation
Get it directly through "Get New Widgets" on your desktop or through https://store.kde.org/p/2270856

## Development
You need a distro running Plasma 6, no additional deps. Follow the [Plasma Widget docs](https://develop.kde.org/docs/plasma/widget/testing/) to test locally or install your modified version.

### Building the KOrganizer helper
Only needed if you want the KOrganizer integration. Requires Akonadi/KCalendarCore dev headers and a C++ toolchain:

```
sudo dnf install -y cmake extra-cmake-modules akonadi-server-devel akonadi-calendar-devel
cmake -B korg-helper/build -S korg-helper
cmake --build korg-helper/build
```

The binary ends up at `korg-helper/build/break-reminder-korg-helper`. Point the widget's "Helper binary path" config field at it and enable the integration.

## Credits
- Thanks to [Praveen Juge](https://github.com/praveenjuge) for the Myna UI icons!
