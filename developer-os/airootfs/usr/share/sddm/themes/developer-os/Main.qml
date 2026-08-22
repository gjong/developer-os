import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0f1219"

    Background {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#990f1219"
    }

    Rectangle {
        anchors.centerIn: parent
        width: 380
        height: 320
        radius: 16
        color: "#e61a1d26"
        border.color: "#337c3aed"
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 14
            width: 300

            Text {
                text: "Developer OS"
                color: "#e2e8f0"
                font.pixelSize: 26
                font.family: "Inter"
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Sign in"
                color: "#94a3b8"
                font.pixelSize: 13
                font.family: "Inter"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            TextBox {
                id: name
                width: parent.width
                height: 36
                text: userModel.lastUser
                font.pixelSize: 14
                color: "#262b38"
                borderColor: "#7c3aed"
                textColor: "#e2e8f0"
                KeyNavigation.tab: password
                KeyNavigation.backtab: session
            }

            PasswordBox {
                id: password
                width: parent.width
                height: 36
                font.pixelSize: 14
                color: "#262b38"
                borderColor: "#7c3aed"
                textColor: "#e2e8f0"
                focus: true
                KeyNavigation.backtab: name
                KeyNavigation.tab: session
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(name.text, password.text, session.index)
                        event.accepted = true
                    }
                }
            }

            ComboBox {
                id: session
                width: parent.width
                height: 32
                model: sessionModel
                index: sessionModel.lastIndex
                color: "#262b38"
                borderColor: "#2e3442"
                textColor: "#e2e8f0"
                KeyNavigation.backtab: password
                KeyNavigation.tab: loginButton
            }

            Button {
                id: loginButton
                text: "Log in"
                width: parent.width
                height: 36
                color: "#7c3aed"
                textColor: "#ffffff"
                KeyNavigation.backtab: session
                KeyNavigation.tab: name
                onClicked: sddm.login(name.text, password.text, session.index)
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
        }
    }

    Component.onCompleted: {
        if (name.text === "")
            name.focus = true
        else
            password.focus = true
    }
}
