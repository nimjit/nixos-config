// Focus windows by screen position — Alt+H/J/K/L = positions 1/2/3/4
// Windows are sorted left-to-right by absolute x-coordinate, then top-to-bottom.
// Only visible, normal, non-minimised windows on the current virtual desktop count.

function focusAtIndex(idx) {
    const desk = workspace.currentDesktop;
    const wins = workspace.windows
        .filter(function(w) {
            return w.normalWindow &&
                   !w.minimized &&
                   !w.skipTaskbar &&
                   (w.onAllDesktops || w.desktops.indexOf(desk) !== -1);
        })
        .sort(function(a, b) {
            if (a.frameGeometry.x !== b.frameGeometry.x)
                return a.frameGeometry.x - b.frameGeometry.x;
            return a.frameGeometry.y - b.frameGeometry.y;
        });
    if (idx < wins.length) {
        workspace.activeWindow = wins[idx];
    }
}

registerShortcut("Focus Position 1", "Focus leftmost window",  "Alt+H", function() { focusAtIndex(0); });
registerShortcut("Focus Position 2", "Focus 2nd window",       "Alt+J", function() { focusAtIndex(1); });
registerShortcut("Focus Position 3", "Focus 3rd window",       "Alt+K", function() { focusAtIndex(2); });
registerShortcut("Focus Position 4", "Focus rightmost window", "Alt+L", function() { focusAtIndex(3); });
