// Pure presentation helpers. No shell commands, filesystem or network access.
function validIds(value) {
    if (!Array.isArray(value)) return [];
    var seen = {};
    return value.filter(function(id) {
        if (typeof id !== "string" || id.length === 0 || id.length > 512
                || /[\x00-\x1f\x7f-\x9f]/.test(id) || seen["$" + id]) return false;
        seen["$" + id] = true;
        return true;
    });
}

function pinnedEntries(entries, ids) {
    var byId = {};
    entries.forEach(function(entry) { byId["$" + entry.id] = entry; });
    return validIds(ids).map(function(id) { return byId["$" + id]; })
        .filter(function(entry) { return !!entry; });
}

function defaultPins(entries, inherited) {
    var preferred = validIds(inherited).concat([
        "chromium", "firefox", "org.gnome.Nautilus", "foot", "Alacritty",
        "org.gnome.TextEditor", "code", "org.gnome.Calculator", "org.gnome.Calendar",
        "org.gnome.Settings", "org.gnome.SystemMonitor", "org.gnome.Loupe"
    ]);
    var pins = pinnedEntries(entries, preferred).map(function(entry) { return entry.id; });
    return pins.length > 0 ? pins.slice(0, 18) : entries.slice(0, 12).map(function(entry) { return entry.id; });
}

function togglePin(ids, id) {
    var result = validIds(ids);
    if (typeof id !== "string" || validIds([id]).length === 0) return result;
    var at = result.indexOf(id);
    if (at >= 0) result.splice(at, 1);
    else if (result.length < 48) result.push(id);
    return result;
}

function movedIndex(index, dx, dy, columns, count) {
    if (count <= 0) return -1;
    return Math.max(0, Math.min(count - 1, index < 0 ? 0 : index + dx + dy * columns));
}

function categoryId(entry) {
    var values = (entry.categories || []).map(String);
    function has(names) { return names.some(function(name) { return values.indexOf(name) >= 0; }); }
    if (has(["Office", "FileManager", "TextEditor", "WebBrowser", "Email", "InstantMessaging"])) return "productivity";
    if (has(["Graphics", "AudioVideo", "Audio", "Video", "Photography"])) return "creativity";
    if (has(["Game"])) return "games";
    if (has(["Development"])) return "development";
    if (has(["Network"])) return "internet";
    return "utilities";
}

function categories(entries) {
    var definitions = [
        ["productivity", "Productivity", "Productividad"],
        ["utilities", "Utilities & Tools", "Utilidades y herramientas"],
        ["creativity", "Creativity", "Creatividad"],
        ["internet", "Internet", "Internet"],
        ["development", "Development", "Desarrollo"],
        ["games", "Games", "Juegos"]
    ];
    return definitions.map(function(definition) {
        var apps = entries.filter(function(entry) { return categoryId(entry) === definition[0]; });
        return {id: definition[0], name: definition[1], nameEs: definition[2], entries: apps, preview: apps.slice(0, 4)};
    }).filter(function(group) { return group.entries.length > 0; });
}

function powerOptions(suspend, hibernate) {
    var options = [
        {id: "screensaver", name: "Screensaver", nameEs: "Salvapantallas", icon: "screensaver"},
        {id: "lock", name: "Lock", nameEs: "Bloquear", icon: "lock"}
    ];
    if (suspend) options.push({id: "suspend", name: "Sleep", nameEs: "Suspender", icon: "suspend"});
    if (hibernate) options.push({id: "hibernate", name: "Hibernate", nameEs: "Hibernar", icon: "hibernate"});
    return options.concat([
        {id: "logout", name: "Sign out", nameEs: "Cerrar sesión", icon: "logout"},
        {id: "shutdown", name: "Shut down", nameEs: "Apagar", icon: "power"},
        {id: "reboot", name: "Restart", nameEs: "Reiniciar", icon: "restart"}
    ]);
}
