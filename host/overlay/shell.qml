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
            keySize: 39,
            fontSize: 13,
            fontFamily: "FiraCode Nerd Font Mono",
            opacity: 0.8,
            showCombos: true
        })
    readonly property var fallbackColors: ({
            surface: "#111111",
            surfaceVariant: "#202020",
            primary: "#9ece6a",
            onSurface: "#f2f4f8",
            outline: "#6e8f4a"
        })

    property var cfg: defaults
    property var layoutData: ({ keys: [], layers: [], combos: [] })
    property var colors: fallbackColors
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
        mask: Region {}

        property var pressed: ({})
        property int activeLayer: 0

        readonly property var lkeys: root.layoutData.keys || []
        readonly property var combos: root.layoutData.combos || []
        readonly property real scale: (root.cfg.keySize || 39) / 56
        readonly property real minX: {
            var m = 1e9;
            for (var i = 0; i < lkeys.length; i++) {
                var v = lkeys[i].x - lkeys[i].w / 2;
                if (v < m)
                    m = v;
            }
            return lkeys.length ? m : 0;
        }
        readonly property real minY: {
            var m = 1e9;
            for (var i = 0; i < lkeys.length; i++) {
                var v = lkeys[i].y - lkeys[i].h / 2;
                if (v < m)
                    m = v;
            }
            return lkeys.length ? m : 0;
        }
        readonly property real boardW: {
            var m = -1e9;
            for (var i = 0; i < lkeys.length; i++) {
                var v = lkeys[i].x + lkeys[i].w / 2;
                if (v > m)
                    m = v;
            }
            return lkeys.length ? (m - minX) * scale : 0;
        }
        readonly property real boardH: {
            var m = -1e9;
            for (var i = 0; i < lkeys.length; i++) {
                var v = lkeys[i].y + lkeys[i].h / 2;
                if (v > m)
                    m = v;
            }
            return lkeys.length ? (m - minY) * scale : 0;
        }

        function legend(i) {
            const layers = root.layoutData.layers || [];
            if (panel.activeLayer < layers.length && layers[panel.activeLayer].keys && layers[panel.activeLayer].keys[i])
                return layers[panel.activeLayer].keys[i].t || "";
            return "";
        }
        function baseLabel(pos) {
            const layers = root.layoutData.layers || [];
            if (layers.length && layers[0].keys && layers[0].keys[pos])
                return layers[0].keys[pos].t || ("" + pos);
            return "" + pos;
        }

        Rectangle {
            id: card
            anchors.fill: parent
            implicitWidth: Math.max(panel.boardW, combosCol.implicitWidth) + 28
            implicitHeight: panel.boardH + (combosCol.visible ? combosCol.implicitHeight + 14 : 0) + 28
            radius: 14
            opacity: root.cfg.opacity
            color: root.colors.surface
            border.color: root.colors.outline
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 12

                Item {
                    id: kbd
                    width: panel.boardW
                    height: panel.boardH
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: panel.lkeys.length

                        delegate: Rectangle {
                            required property int index
                            readonly property var k: panel.lkeys[index]
                            x: (k.x - k.w / 2 - panel.minX) * panel.scale
                            y: (k.y - k.h / 2 - panel.minY) * panel.scale
                            width: k.w * panel.scale
                            height: k.h * panel.scale
                            rotation: k.r
                            radius: 5
                            color: panel.pressed[index] ? root.colors.primary : root.colors.surfaceVariant
                            border.color: root.colors.outline
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.margins: 2
                                text: panel.legend(index)
                                color: panel.pressed[index] ? root.colors.surface : root.colors.onSurface
                                font.pixelSize: root.cfg.fontSize
                                font.family: root.cfg.fontFamily
                                fontSizeMode: Text.HorizontalFit
                                minimumPixelSize: 6
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Column {
                    id: combosCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3
                    visible: root.cfg.showCombos && panel.combos.length > 0

                    Repeater {
                        model: panel.combos

                        delegate: Text {
                            required property var modelData
                            text: modelData.positions.map(p => panel.baseLabel(p)).join(" + ") + "  →  " + modelData.output
                            color: root.colors.onSurface
                            font.pixelSize: root.cfg.fontSize - 2
                            font.family: root.cfg.fontFamily
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
