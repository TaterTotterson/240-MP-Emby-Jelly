import QtQuick

Item {
    id: staticRoot

    property bool running: visible
    property int noiseWidth: 160
    property int noiseHeight: 120
    property int frameInterval: Qt.platform.os === "linux" ? 125 : 83
    property int frameSeed: 240
    readonly property real noiseScale: Math.max(width > 0 ? width / noiseCanvas.width : 1,
                                                height > 0 ? height / noiseCanvas.height : 1)

    Rectangle {
        anchors.fill: parent
        color: "#050505"
    }

    Item {
        anchors.fill: parent
        clip: true

        Canvas {
            id: noiseCanvas
            anchors.centerIn: parent
            width: staticRoot.noiseWidth
            height: staticRoot.noiseHeight
            scale: staticRoot.noiseScale
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Threaded
            smooth: false
            antialiasing: false
            opacity: 0.56

            onPaint: {
                var ctx = getContext("2d")
                var w = Math.max(1, Math.floor(width))
                var h = Math.max(1, Math.floor(height))
                var imageData = ctx.createImageData(w, h)
                var data = imageData.data
                var seed = staticRoot.frameSeed

                for (var y = 0; y < h; y++) {
                    var lineBoost = (y % 13 === 0) ? 26 : 0
                    for (var x = 0; x < w; x++) {
                        seed = (seed * 1103515245 + 12345) & 0x7fffffff
                        var v = (seed >> 8) & 0xff
                        var luma = 18 + Math.floor(v * 0.72) + lineBoost
                        if ((seed & 0x001f0000) === 0)
                            luma = 245
                        if (luma > 255)
                            luma = 255

                        var p = (y * w + x) * 4
                        data[p] = luma
                        data[p + 1] = luma
                        data[p + 2] = luma
                        data[p + 3] = 255
                    }
                }

                ctx.putImageData(imageData, 0, 0)
            }
        }
    }

    Canvas {
        id: scanlineCanvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        smooth: false
        opacity: 0.55

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            if (w <= 0 || h <= 0) return

            ctx.clearRect(0, 0, w, h)
            for (var y = 0; y < h; y += 6) {
                ctx.fillStyle = "rgba(0,0,0," + (y % 12 === 0 ? "0.24" : "0.10") + ")"
                ctx.fillRect(0, y, w, 1)
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Timer {
        interval: staticRoot.frameInterval
        repeat: true
        running: staticRoot.running && staticRoot.visible && staticRoot.width > 0 && staticRoot.height > 0
        onTriggered: {
            staticRoot.frameSeed = (staticRoot.frameSeed * 1664525 + 1013904223) & 0x7fffffff
            noiseCanvas.requestPaint()
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
