-- Runtime-only Hyprland binds. No config edits, polling or keyboard recording.
local M = {}
local owner = "io.github.gsus67.omarchy-theme-eleven"

function M.install(candidates)
    if _G.__eleven_shortcuts then
        error("Eleven shortcut state is already occupied")
    end
    local state = { owner = owner, binds = {} }
    _G.__eleven_shortcuts = state
    for _, candidate in ipairs(candidates) do
        local handle = hl.bind(candidate.keys, hl.dsp.exec_cmd(candidate.command), {
            release = candidate.release,
            description = candidate.description,
        })
        table.insert(state.binds, { keys = candidate.keys, handle = handle })
    end
end

return M
