import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.75
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "Installing Developer OS with the same Plasma, development tools, Flatpak, and profile defaults as the live environment."
        }
    }

    function onActivate() {}
    function onLeave() {}
}
