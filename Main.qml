import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Components

Window {
    id: root
    flags: Qt.FramelessWindowHint | Qt.Window
    x:      Qt.platform.os === "osx" ? macScreenX      : Screen.virtualX
    y:      Qt.platform.os === "osx" ? macScreenY      : Screen.virtualY
    width:  Qt.platform.os === "osx" ? macScreenWidth  : Screen.width
    height: Qt.platform.os === "osx" ? macScreenHeight : Screen.height
    visible: true
    color: root.surfaceColor

    // --- Color Schemes ---
    readonly property var themes: ({
        "Video 1": {
            "primary": "#FFFFFF",
            "secondary": "#C2BFE4",
            "tertiary": "#8480C9",
            "surface": "#0A0094",
            "accent": "#AECFFF"
        },
        "Late Night": {
            "primary": "#FFFFFF",
            "secondary": "#A1A1A1",
            "tertiary": "#444444",
            "surface": "#000000",
            "accent": "#FFD900"
        },
        "Synthwave": {
            "primary": "#FFFFFF",
            "secondary": "#D48BFF",
            "tertiary": "#7836B5",
            "surface": "#12012B",
            "accent": "#00E5FF"
        },
        "Terminal": {
            "primary": "#4AF626",
            "secondary": "#32A81B",
            "tertiary": "#1A590E",
            "surface": "#000000",
            "accent": "#4AF626"
        },
        "T-120": {
            "primary": "#000000",
            "secondary": "#818181",
            "tertiary": "#df9c27",
            "surface": "#FAF5E8",
            "accent": "#EE442F"
        },
        "Amber": {
            "primary": "#FFB000",
            "secondary": "#B37B00",
            "tertiary": "#B37B00",
            "surface": "#000000",
            "accent": "#FFEE11"
        },
        "Kinescope": {
            "primary": "#FFFFFF",
            "secondary": "#9E9E9E",
            "tertiary": "#424242",
            "surface": "#121212",
            "accent": "#FFFFFF"
        },
        "Off Air": {
            "primary": "#FFFFFF",
            "secondary": "#E8E8E8",
            "tertiary": "#8A8A8A",
            "surface": "#050505",
            "accent": "#FF6A00",
            "static": true
        }
    })
    property var allThemes: themes  // may gain a "Custom" entry on startup
    property string currentTheme: "Off Air"
    readonly property var offAirHighlightColors: ({
        "Orange": "#FF6A00",
        "Cyan": "#00E5FF",
        "Green": "#39FF14",
        "Magenta": "#FF2BD6",
        "Red": "#FF3030",
        "Blue": "#3EA0FF",
        "Amber": "#FFB000",
        "White": "#FFFFFF"
    })
    property string offAirHighlightColor: "Orange"
    property string primaryColor:   (allThemes[currentTheme] || allThemes["Off Air"]).primary
    property string secondaryColor: (allThemes[currentTheme] || allThemes["Off Air"]).secondary
    property string tertiaryColor:  (allThemes[currentTheme] || allThemes["Off Air"]).tertiary
    property string surfaceColor:   (allThemes[currentTheme] || allThemes["Off Air"]).surface
    property string accentColor:    currentTheme === "Off Air"
        ? (offAirHighlightColors[offAirHighlightColor] || offAirHighlightColors["Orange"])
        : (allThemes[currentTheme] || allThemes["Off Air"]).accent
    property bool staticBackgroundEnabled: !!((allThemes[currentTheme] || allThemes["Off Air"]).static)

    readonly property real sw: width
    readonly property real sh: height

    Connections {
        target: appCore
        function onAppSettingChanged(key, value) {
            if (key === "color_scheme") root.currentTheme = value
            if (key === "off_air_highlight_color") root.offAirHighlightColor = value
        }
    }

    Component.onCompleted: {
        var cfg = appCore.get_settings()

        var custom = appCore.getCustomColorScheme()
        if (Object.keys(custom).length === 5) {
            var t = Object.assign({}, themes)
            t["Custom"] = custom
            root.allThemes = t
        }

        var savedTheme = (cfg.app && cfg.app.color_scheme) || "Off Air"
        if (savedTheme === "Custom" && !root.allThemes["Custom"]) {
            appCore.save_setting("", "color_scheme", "Off Air")
            savedTheme = "Off Air"
        }
        root.currentTheme = savedTheme

        var savedOffAirHighlight = (cfg.app && cfg.app.off_air_highlight_color) || "Orange"
        if (!root.offAirHighlightColors[savedOffAirHighlight]) {
            appCore.save_setting("", "off_air_highlight_color", "Orange")
            savedOffAirHighlight = "Orange"
        }
        root.offAirHighlightColor = savedOffAirHighlight

        // Break declarative bindings on macOS so the C++ NSWindow override
        // in forceWindowFullScreen() isn't immediately re-fought by QML.
        if (Qt.platform.os === "osx") {
            root.x = macScreenX
            root.y = macScreenY
            root.width = macScreenWidth
            root.height = macScreenHeight
        }
    }
    
    FontLoader {
        id: font; source: "assets/fonts/VCR_OSD_MONO_1.001.ttf"
    }
    property string globalFont: font.name;

    // --- INPUT / APP INFO MIRRORS ---
    // Views must bind these via `root.*`, never the appCore/inputManager
    // context properties directly: when the module Loader swaps views, the
    // dying view's context properties resolve to null and any binding on them
    // throws a TypeError during teardown. id-resolved `root.*` stays valid
    // (root lives as long as the app), so these mirrors are teardown-safe.
    // The null guards absorb the same nulling here at app shutdown, when the
    // engine invalidates the root context itself.
    readonly property var hints: inputManager ? inputManager.hints : ({})
    readonly property string appVersion: appCore ? appCore.appVersion : ""

    // --- APP-LEVEL NAV STACK ---
    property var appNavStack: []
    property var appCurrentParams: ({})

    // --- MODULE LOADER ---
    StaticBackground {
        anchors.fill: parent
        visible: root.staticBackgroundEnabled
        running: visible
    }

    Loader {
        id: moduleLoader;
        anchors.fill: parent;
        focus: true;
        source: "views/ModuleList.qml";

        Keys.onPressed: (event) => {
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Q) {
                Qt.quit()
            }
        }

        onLoaded: item.forceActiveFocus()

        Connections {
            target: moduleLoader.item
            ignoreUnknownSignals: true

            function onNavigateTo(path, params, listState) {
                root.appNavStack.push({ source: moduleLoader.source, params: root.appCurrentParams, listState: listState || {} })
                root.appCurrentParams = params || {}
                moduleLoader.setSource(path, { "navParams": params || {} })
            }

            function onGoBack() {
                if (root.appNavStack.length === 0) return
                var prev = root.appNavStack.pop()
                root.appCurrentParams = prev.params
                moduleLoader.setSource(prev.source, { "navParams": prev.params, "navListState": prev.listState || {} })
            }

        }
    }
}
