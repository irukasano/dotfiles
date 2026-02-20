-- -- add mtime on status
-- Status:children_add(function(self)
--     local h = self._current.hovered
--     if not h or (h.is_dir and (#(h.children or {}) == 0)) then
--         return ""
--     end
--     local symlink = ""
--     if h and h.link_to then
--         symlink = " -> " .. tostring(h.link_to)
--     else
--         symlink =  ""
--     end
--     return ui.Line {
--         ui.Span(symlink):fg("#af87ff"),
--         " [",
--         ui.Span(os.date("%Y-%m-%d %H:%M", tostring(h.cha.mtime):sub(1, 10))):fg("#af87ff"),
--         "] ",
--     }
-- end, 3300, Status.LEFT)
--
-- -- add ownername, ownergroup on status
-- Status:children_add(function()
--     local h = cx.active.current.hovered
--     if not h or ya.target_family() ~= "unix" then
--         return ""
--     end
--
--     return ui.Line {
--         ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
--         ":",
--         ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
--         " ",
--     }
-- end, 500, Status.RIGHT)
--
-- -- add hostname, username on header
-- Header:children_add(function()
--     if ya.target_family() ~= "unix" then
--         return ""
--     end
--     return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
-- end, 500, Header.LEFT)
--

-- full-border plugin
require("full-border"):setup()

-- yatline plugin
-- see: https://github.com/imsi32/yatline.yazi/wiki
require("yatline"):setup()

-- bookmark plugin
require("bookmarks"):setup({
    last_directory = { enable = false, persist = false, mode="dir" },
    persist = "all",
    desc_format = "full",
    file_pick_mode = "hover",
    custom_desc_input = true,
    notify = {
        enable = true,
        timeout = 3,
        message = {
            new = "New bookmark '<key>' -> '<folder>'",
            delete = "Deleted bookmark in '<key>'",
            delete_all = "Deleted all bookmarks",
        },
    },
})

-- linemode
function Linemode:fullmode()
    local f = self._file
    local cha = f.cha

    -------------------------------------------------
    -- permission (drwxr-xr-x 形式)
    -------------------------------------------------
    local perm = "-"

    if cha and cha.mode then
        -- perm = perm_string(cha.mode)
        perm = cha:perm()
    end

    -------------------------------------------------
    -- owner
    -------------------------------------------------
    local owner = "-"
    if cha and cha.uid then
        owner = ya.user_name(cha.uid) or tostring(cha.uid)
    end

    -------------------------------------------------
    -- size
    -------------------------------------------------
    local size = f:size()
    local size_s = size and ya.readable_size(size) or "-"

    -------------------------------------------------
    -- mime (20桁固定)
    -------------------------------------------------
    local mime = f:mime() or ""
    if mime == "inode/directory" then
        mime = "dir"
    end

    local mime_s
    if #mime > 20 then
        mime_s = mime:sub(1, 19) .. "…"
    else
        mime_s = string.format("%-20s", mime)
    end

    -------------------------------------------------
    -- mtime
    -------------------------------------------------
    local ts = math.floor(cha and cha.mtime or 0)
    local time = ts > 0 and os.date("%Y-%m-%d %H:%M:%S", ts) or ""

    -------------------------------------------------
    -- 出力
    -------------------------------------------------
    return string.format(
        "%-10s %-8s %8s  %s  %s",
        perm,
        owner,
        size_s,
        mime_s,
        time
    )
end


-- Linemode
function Linemode:size_and_mtime()
    local f = self._file

    -- ---- 時刻 ----
    local ts = math.floor(f.cha.mtime or 0)
    local time = ts > 0 and os.date("%Y-%m-%d %H:%M:%S", ts) or ""

    -- ---- サイズ ----
    local size = f:size()
    local size_s = size and ya.readable_size(size) or "-"

    return string.format("%8s %s", size_s, time)
end

