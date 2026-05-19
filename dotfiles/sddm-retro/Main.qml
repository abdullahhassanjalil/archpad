// ============================================================
//  SDDM Theme — retro-warm
//  Minimal — only basic QtQuick 2.0 + SddmComponents
// ============================================================

import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    width:  Screen.width
    height: Screen.height

    readonly property color cream:   config.on_primary      || "#e8dcc8"
    readonly property color rust:    config.primary          || "#c94a1a"
    readonly property color crimson: config.error            || "#a82010"
    readonly property color dark:    config.on_surface       || "#2a1008"
    readonly property color mid:     config.outline          || "#7a3010"
    readonly property color cardbg:  config.background_color || "#17130b"

    // ── Background ───────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: root.cardbg
    }

    Image {
        anchors.fill: parent
        source: "file:///usr/share/sddm/themes/retro-warm/background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    // ── Clock ─────────────────────────────────────────────────

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.16
        spacing: 6

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "HH:mm")
            color: root.cream
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 96
            font.weight: Font.Bold
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
            color: root.mid
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeLabel.text = Qt.formatTime(new Date(), "HH:mm")
            dateLabel.text = Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
        }
    }

    // ── Login card ────────────────────────────────────────────

    Rectangle {
        width:  360
        height: cardCol.height + 56
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        color:  Qt.rgba(0, 0, 0, 0.55)
        radius: 14
        border.color: root.rust
        border.width: 2

        Column {
            id: cardCol
            anchors {
                left:      parent.left
                right:     parent.right
                top:       parent.top
                margins:   24
                topMargin: 28
            }
            spacing: 12

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text:  userModel.lastUser !== "" ? userModel.lastUser : sddm.hostName
                color: root.cream
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                font.weight:    Font.Bold
            }

            ComboBox {
                id: session
                width:  parent.width
                height: 36
                model:  sessionModel
                index:  sessionModel.lastIndex
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }

            TextBox {
                id: password
                width:    parent.width
                height:   40
                echoMode: TextInput.Password
                text:     ""
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                focus: true
                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed:  doLogin()
            }

            Text {
                id: errorText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                color:   root.crimson
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width:  parent.width
                height: 40
                color:  loginMouse.containsMouse ? root.crimson : root.rust
                radius: 7

                Text {
                    anchors.centerIn: parent
                    text:  "Login"
                    color: root.cream
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.weight:    Font.Bold
                }

                MouseArea {
                    id: loginMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: doLogin()
                }
            }

            Item { height: 4 }
        }
    }

    // ── System buttons ────────────────────────────────────────

    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Rectangle {
            width:  120
            height: 36
            color:  rebootMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            radius: 7
            border.color: Qt.rgba(1, 1, 1, 0.4)
            border.width: 1
            visible: sddm.canReboot

            Text {
                anchors.centerIn: parent
                text:  "⟳  Reboot"
                color: root.cream
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }

            MouseArea {
                id: rebootMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.reboot()
            }
        }

        Rectangle {
            width:  120
            height: 36
            color:  shutdownMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            radius: 7
            border.color: Qt.rgba(1, 1, 1, 0.4)
            border.width: 1
            visible: sddm.canPowerOff

            Text {
                anchors.centerIn: parent
                text:  "⏻  Shutdown"
                color: root.cream
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }

            MouseArea {
                id: shutdownMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.powerOff()
            }
        }
    }

    function doLogin() {
        errorText.text = ""
        sddm.login(userModel.lastUser, password.text, session.index)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            password.focus = true
            errorText.text = "Incorrect password — try again"
        }
    }
}
