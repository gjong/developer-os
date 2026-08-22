var plasma = getApiVersion(1);

var desktop = desktops()[0];
if (desktop) {
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/wallpapers/DeveloperOS");
    desktop.writeConfig("PreviewImage", "file:///usr/share/wallpapers/DeveloperOS");
}

var topbar = new Panel;
topbar.location = "top";
topbar.height = 26;
topbar.floating = false;
topbar.alignment = "center";
topbar.hiding = "none";
try {
    topbar.lengthMode = "fill";
} catch (e) {
    topbar.maximumLength = -1;
    topbar.minimumLength = -1;
}

var kickoff = topbar.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "developer-os-launcher");

topbar.addWidget("org.kde.plasma.appmenu");
topbar.addWidget("org.kde.plasma.panelspacer");
topbar.addWidget("org.kde.plasma.systemmonitor.cpu");
topbar.addWidget("org.kde.plasma.systemmonitor.memory");
topbar.addWidget("org.kde.plasma.systemtray");

var clock = topbar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "false");
clock.writeConfig("showSeconds", "false");

var dock = new Panel;
dock.location = "bottom";
dock.height = 48;
dock.floating = true;
dock.alignment = "center";
dock.hiding = "dodgewindows";
dock.offset = 0;
try {
    dock.lengthMode = "fit";
} catch (e) {
    dock.maximumLength = 720;
    dock.minimumLength = 280;
}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig(
    "launchers",
    "applications:kitty.desktop,applications:code.desktop,applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:jetbrains-toolbox.desktop,applications:systemsettings.desktop"
);
tasks.writeConfig("maxStripes", "1");
tasks.writeConfig("iconSpacing", "2");
