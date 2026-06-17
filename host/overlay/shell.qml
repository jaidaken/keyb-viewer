import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    readonly property string home: "/home/jaidaken"
    readonly property string base: home + "/projects/keyb-viewer/host/overlay"
    readonly property var defaults: ({
            anchor: "bottom-right",
            marginX: 48,
            marginY: 48,
            keySize: 30,
            fontSize: 12,
            fontFamily: "FiraCode Nerd Font Mono",
            opacity: 0.85
        })
    readonly property var fallbackColors: ({
            surface: "#111111",
            surfaceVariant: "#202020",
            primary: "#9ece6a",
            onSurface: "#f2f4f8",
            outline: "#6e8f4a"
        })

    property var cfg: defaults
    property var layoutData: ({ layers: [] })
    property var colors: fallbackColors

    // auto-theme: resolved from noctalia's config.toml [theme] section
    property string paletteMode: "dark"
    property string activePalettePath: home + "/.config/noctalia/palettes/greendot.json"

    function loadCfg(txt) {
        try {
            root.cfg = Object.assign({}, root.defaults, JSON.parse(txt));
        } catch (e) {}
    }
    function loadLayout(txt) {
        try {
            root.layoutData = JSON.parse(txt);
        } catch (e) {}
    }
    function loadPalette(txt) {
        try {
            const p = JSON.parse(txt)[root.paletteMode] || {};
            root.colors = {
                surface: p.mSurface || root.fallbackColors.surface,
                surfaceVariant: p.mSurfaceVariant || root.fallbackColors.surfaceVariant,
                primary: p.mPrimary || root.fallbackColors.primary,
                onSurface: p.mOnSurface || root.fallbackColors.onSurface,
                outline: p.mOutline || root.fallbackColors.outline
            };
        } catch (e) {}
    }

    // parse the [theme] block of noctalia's config.toml without a TOML parser
    function loadTheme(toml) {
        try {
            const start = toml.indexOf("[theme]");
            if (start < 0)
                return;
            let end = toml.length;
            const re = /\n\[[^\]]+\]/g;
            re.lastIndex = start + 1;
            let m;
            while ((m = re.exec(toml)) !== null) {
                if (m[0].indexOf("\n[theme.") !== 0) {
                    end = m.index;
                    break;
                }
            }
            const block = toml.slice(start, end);
            const get = k => {
                const mm = block.match(new RegExp(k + '\\s*=\\s*"([^"]+)"'));
                return mm ? mm[1] : "";
            };
            const source = get("source");
            root.paletteMode = get("mode") || "dark";
            if (source === "community")
                root.activePalettePath = root.home + "/.local/state/noctalia/community-palettes/" + encodeURIComponent(get("community_palette")) + ".json";
            else
                root.activePalettePath = root.home + "/.config/noctalia/palettes/" + (get("custom_palette") || "greendot") + ".json";
        } catch (e) {}
    }

    FileView {
        path: root.base + "/config.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.loadCfg(text())
        onFileChanged: root.loadCfg(text())
    }
    FileView {
        path: root.base + "/layout.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.loadLayout(text())
        onFileChanged: root.loadLayout(text())
    }
    FileView {
        path: root.home + "/.config/noctalia/config.toml"
        blockLoading: true
        watchChanges: true
        onLoaded: root.loadTheme(text())
        onFileChanged: root.loadTheme(text())
    }
    FileView {
        path: root.activePalettePath
        blockLoading: true
        watchChanges: true
        onLoaded: root.loadPalette(text())
        onFileChanged: root.loadPalette(text())
    }

    PanelWindow {
        id: panel

        anchors {
            top: root.cfg.anchor.indexOf("top") >= 0
            bottom: root.cfg.anchor.indexOf("bottom") >= 0
            left: root.cfg.anchor.indexOf("left") >= 0
            right: root.cfg.anchor.indexOf("right") >= 0
        }
        margins {
            top: root.cfg.marginY
            bottom: root.cfg.marginY
            left: root.cfg.marginX
            right: root.cfg.marginX
        }
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        property var pressed: ({})
        property int activeLayer: 0
        readonly property real u: root.cfg.keySize

        readonly property var grid: [
            [0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [7, 0], [8, 0], [9, 0], [10, 0], [11, 0], [12, 0],
            [0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [7, 1], [8, 1], [9, 1], [10, 1], [11, 1], [12, 1],
            [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [7, 2], [8, 2], [9, 2], [10, 2], [11, 2], [12, 2],
            [3, 3], [4, 3], [5, 3], [7, 3], [8, 3], [9, 3]
        ]

        function legend(i) {
            const layers = root.layoutData.layers || [];
            if (panel.activeLayer < layers.length && layers[panel.activeLayer].keys)
                return layers[panel.activeLayer].keys[i] || "";
            return "";
        }
        function layerName() {
            const layers = root.layoutData.layers || [];
            return (panel.activeLayer < layers.length) ? layers[panel.activeLayer].name : ("Layer " + panel.activeLayer);
        }

        Rectangle {
            id: card
            anchors.fill: parent
            implicitWidth: kbd.width + 28
            implicitHeight: kbd.height + 24
            radius: 14
            opacity: root.cfg.opacity
            color: root.colors.surface
            border.color: root.colors.outline
            border.width: 1

            Item {
                id: kbd
                anchors.centerIn: parent
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
                            radius: 5
                            color: panel.pressed[index] ? root.colors.primary : root.colors.surfaceVariant
                            border.color: root.colors.outline
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: 60
                                }
                            }

                            Text {
                                anchors.fill: parent
                                anchors.margins: 2
                                text: panel.legend(index)
                                color: panel.pressed[index] ? root.colors.surface : root.colors.onSurface
                                font.pixelSize: root.cfg.fontSize
                                font.family: root.cfg.fontFamily
                                fontSizeMode: Text.HorizontalFit
                                minimumPixelSize: 7
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
        }

        Process {
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
