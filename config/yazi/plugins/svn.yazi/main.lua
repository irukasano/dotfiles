local M = {}

------------------------------------------------------------
-- Collect targets
------------------------------------------------------------
local collect_targets = ya.sync(function()
  local targets = {}

  if cx.active.selected and #cx.active.selected > 0 then
    for _, f in ipairs(cx.active.selected) do
      targets[#targets + 1] = tostring(f.url.path)
    end
  else
    local h = cx.active.current and cx.active.current.hovered
    if h then
      targets[#targets + 1] = tostring(h.url.path)
    end
  end

  return targets
end)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function get_action(job)
  local args = job and job.args
  return type(args) == "table" and args[1] or nil
end

local function run_svn(argv)
  local out, err = Command(argv[1])
    :arg({ table.unpack(argv, 2) })
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :output()

  if not out then
    ya.notify({ title = "SVN Error", content = tostring(err), level = "error", timeout = 6.0 })
    return false
  end

  if out.status and out.status.success then
    ya.notify({
      title = "SVN",
      content = (out.stdout ~= "" and out.stdout) or "Success",
      level = "info",
      timeout = 3.0,
    })
    return true
  end

  ya.notify({
    title = "SVN Error",
    content = (out.stderr ~= "" and out.stderr) or "Unknown error",
    level = "error",
    timeout = 6.0,
  })
  return false
end

local function svn_status_raw(paths)
  local out = Command("svn")
    :arg({ "status", table.unpack(paths) })
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :output()

  if not out or not out.status or not out.status.success then
    return nil
  end

  return out.stdout
end

local function has_unversioned(paths)
  local s = svn_status_raw(paths)
  if not s then return false end

  for line in s:gmatch("[^\r\n]+") do
    if line:match("^%?") then
      return true
    end
  end
  return false
end

------------------------------------------------------------
-- Actions
------------------------------------------------------------
local function do_add(targets)
  local argv = { "svn", "add" }
  for _, p in ipairs(targets) do argv[#argv + 1] = p end
  run_svn(argv)
end

local function do_status(targets)
  local s = svn_status_raw(targets)
  if not s then
    ya.notify({ title = "SVN", content = "status failed", level = "error", timeout = 5.0 })
    return
  end

  if s == "" then
    ya.notify({ title = "SVN", content = "Clean", level = "info", timeout = 3.0 })
  else
    ya.notify({ title = "SVN Status", content = s, level = "info", timeout = 8.0 })
  end
end

local function do_update(targets)
  local argv = { "svn", "update" }
  for _, p in ipairs(targets) do argv[#argv + 1] = p end
  run_svn(argv)
end

local function do_commit(targets)
  if has_unversioned(targets) then
    ya.notify({
      title = "SVN",
      content = "Unversioned files exist. Run SVN add first.",
      level = "error",
      timeout = 6.0,
    })
    return
  end

  ya.input({ title = "SVN Commit Message", pos = { "center", w = 60 } }, function(msg)
    if not msg or msg == "" then
      ya.notify({
        title = "SVN",
        content = "Commit cancelled",
        level = "warn",
        timeout = 2.0,
      })
      return
    end

    local argv = { "svn", "commit", "-m", msg }
    for _, p in ipairs(targets) do
      argv[#argv + 1] = p
    end

    -- ✅ 開始通知
    ya.notify({
      title = "SVN",
      content = "Committing...",
      level = "info",
      timeout = 3.0,
    })

    local out, err = Command("svn")
      :arg({ "commit", "-m", msg, table.unpack(targets) })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :output()

    if not out then
      ya.notify({
        title = "SVN",
        content = "Commit failed:\n" .. tostring(err),
        level = "error",
        timeout = 8.0,
      })
      return
    end

    if out.status and out.status.success then
      -- ✅ 成功通知
      ya.notify({
        title = "SVN",
        content = "Commit successful",
        level = "info",
        timeout = 3.0,
      })
    else
      local code = out.status and out.status.code or -1
      local msg2 = (out.stderr and out.stderr ~= "" and out.stderr) or "Unknown error"

      -- ❌ 失敗通知
      ya.notify({
        title = "SVN",
        content = ("Commit failed (code=%d)\n%s"):format(code, msg2),
        level = "error",
        timeout = 8.0,
      })
    end
  end)
end

------------------------------------------------------------
-- Entry
------------------------------------------------------------
function M.entry(_, job)
  local action = get_action(job)
  if not action then
    ya.notify({ title = "SVN", content = "Missing action", level = "error" })
    return
  end

  local targets = collect_targets()
  if #targets == 0 then
    ya.notify({ title = "SVN", content = "No target", level = "warn" })
    return
  end

  if action == "add" then
    do_add(targets)
  elseif action == "status" then
    do_status(targets)
  elseif action == "update" then
    do_update(targets)
  elseif action == "commit" then
    do_commit(targets)
  else
    ya.notify({ title = "SVN", content = "Unknown action: " .. action, level = "error" })
  end
end

return M

