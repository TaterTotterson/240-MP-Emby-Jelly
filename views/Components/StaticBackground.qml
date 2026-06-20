import QtQuick

Item {
    id: staticRoot

    property bool running: visible
    property int cellSize: Math.max(2, Math.round(Math.min(width, height) / 150))
    property real noiseOpacity: 0.50

    Rectangle {
        anchors.fill: parent
        color: "#050505"
    }

    Canvas {
        id: noiseCanvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        smooth: false

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            if (w <= 0 || h <= 0) return

            ctx.fillStyle = "#050505"
            ctx.fillRect(0, 0, w, h)

            var s = staticRoot.cellSize
            for (var y = 0; y < h; y += s) {
                for (var x = 0; x < w; x += s) {
                    var v = 28 + Math.floor(Math.random() * 210)
                    var a = staticRoot.noiseOpacity * (0.25 + Math.random() * 0.75)
                    ctx.fillStyle = "rgba(" + v + "," + v + "," + v + "," + a + ")"
                    ctx.fillRect(x, y, s, s)
                }
            }

            var streaks = Math.max(5, Math.round(h / 64))
            for (var i = 0; i < streaks; i++) {
                var sy = Math.floor(Math.random() * h)
                var shade = Math.random() > 0.5 ? 255 : 0
                var alpha = 0.08 + Math.random() * 0.12
                ctx.fillStyle = "rgba(" + shade + "," + shade + "," + shade + "," + alpha + ")"
                ctx.fillRect(0, sy, w, Math.max(1, Math.floor(s / 2)))
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Timer {
        interval: 62
        repeat: true
        running: staticRoot.running && staticRoot.visible && staticRoot.width > 0 && staticRoot.height > 0
        onTriggered: noiseCanvas.requestPaint()
    }

    Repeater {
        model: Math.ceil(staticRoot.height / 6)

        Rectangle {
            width: staticRoot.width
            height: 1
            y: index * 6
            color: "#000000"
            opacity: index % 2 === 0 ? 0.20 : 0.08
        }
    }

    Rectangle {
        id: trackingBand
        width: parent.width
        height: Math.max(3, parent.height * 0.018)
        y: -height
        color: "#F8F8F8"
        opacity: 0.10
        visible: staticRoot.running

        SequentialAnimation on y {
            running: staticRoot.running
            loops: Animation.Infinite
            PauseAnimation { duration: 750 }
            NumberAnimation {
                from: -trackingBand.height
                to: staticRoot.height
                duration: 1150
                easing.type: Easing.Linear
            }
            PauseAnimation { duration: 2100 }
            NumberAnimation {
                from: staticRoot.height * 0.35
                to: staticRoot.height * 0.43
                duration: 120
                easing.type: Easing.Linear
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.20
    }
}
