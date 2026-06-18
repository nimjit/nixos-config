import QtQuick
import org.kde.kwin

Item {
    function focusAtIndex(idx) {
        var desk = workspace.currentDesktop;
        var allWins = workspace.windows;
        var wins = [];
        for (var i = 0; i < allWins.length; i++) {
            var w = allWins[i];
            if (!w.normalWindow || w.minimized || w.skipTaskbar) continue;
            if (!w.onAllDesktops) {
                var onDesk = false;
                var desktops = w.desktops;
                for (var j = 0; j < desktops.length; j++) {
                    if (desktops[j] === desk) { onDesk = true; break; }
                }
                if (!onDesk) continue;
            }
            wins.push(w);
        }
        wins.sort(function(a, b) {
            if (a.frameGeometry.x !== b.frameGeometry.x)
                return a.frameGeometry.x - b.frameGeometry.x;
            return a.frameGeometry.y - b.frameGeometry.y;
        });
        if (idx < wins.length)
            workspace.activeWindow = wins[idx];
    }

    ShortcutHandler {
        name: "FocusPosition1"
        text: "Focus leftmost window"
        sequence: "Alt+H"
        onActivated: focusAtIndex(0)
    }
    ShortcutHandler {
        name: "FocusPosition2"
        text: "Focus 2nd window"
        sequence: "Alt+J"
        onActivated: focusAtIndex(1)
    }
    ShortcutHandler {
        name: "FocusPosition3"
        text: "Focus 3rd window"
        sequence: "Alt+K"
        onActivated: focusAtIndex(2)
    }
    ShortcutHandler {
        name: "FocusPosition4"
        text: "Focus rightmost window"
        sequence: "Alt+L"
        onActivated: focusAtIndex(3)
    }
}
