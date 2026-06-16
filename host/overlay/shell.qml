import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    PanelWindow {
        id: panel

        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: 48
            right: 48
        }
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        property var pressed: ({})
        property int activeLayer: 0
        readonly property var layerNames: ["QWERTY", "Numbers", "Symbols"]
        readonly property real u: 22

        // keymap position -> [col, row] for the 42-key Corne (gap between halves)
        readonly property var grid: [
            [0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [7, 0], [8, 0], [9, 0], [10, 0], [11, 0], [12, 0],
            [0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [7, 1], [8, 1], [9, 1], [10, 1], [11, 1], [12, 1],
            [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [7, 2], [8, 2], [9, 2], [10, 2], [11, 2], [12, 2],
            [3, 3], [4, 3], [5, 3], [7, 3], [8, 3], [9, 3]
        ]

        Rectangle {
            id: card
            anchors.fill: parent
            implicitWidth: kbd.width + 32
            implicitHeight: header.height + kbd.height + 36
            radius: 14
            color: "#dd16161e"
            border.color: "#3370a0ff"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    id: header
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: panel.layerNames[panel.activeLayer] || ("Layer " + panel.activeLayer)
                    color: "#cfe0ff"
                    font.pixelSize: 18
                    font.bold: true
                }

                Item {
                    id: kbd
                    width: 13 * panel.u
                    height: 4 * panel.u

                    Repeater {
                        model: 42

                        delegate: Rectangle {
                            required property int index
                            x: panel.grid[index][0] * panel.u
                            y: panel.grid[index][1] * panel.u
                            width: panel.u - 3
                            height: panel.u - 3
                            radius: 4
                            color: panel.pressed[index] ? "#ff7aa2f7" : "#22ffffff"
                            border.color: "#44ffffff"
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: 60
                                }
                            }
                        }
                    }
                }
            }
        }

        Process {
            id: reader
            command: ["/home/jaidaken/projects/keyb-viewer/host/reader/zig-out/bin/keyb-reader"]
            running: true
            stdout: SplitParser {
                onRead: line => {
                    try {
                        const ev = JSON.parse(line);
                        if (ev.t === "K") {
                            const p = Object.assign({}, panel.pressed);
                            p[ev.p] = (ev.d === 1);
                            panel.pressed = p;
                        } else if (ev.t === "L") {
                            panel.activeLayer = ev.hi;
                        }
                    } catch (e) {}
                }
            }
        }
    }
}
