-- dirsort.yazi (DDS ind-sort subscriber)
local M = { rules = {}, debug = false }

local function norm(p)
  p = tostring(p or ""):gsub("\\", "/")
  return (#p > 1) and p:gsub("/+$", "") or p
end

local function matches(cwd, path)
  if not path then return false end
  cwd = norm(cwd)
  if path:sub(1, 8) == "pattern:" then
    return cwd:match(path:sub(9)) ~= nil
  end
  if path:sub(-1) == "/" then
    local suf = norm(path)
    return cwd:sub(-#suf) == suf
  end
  return cwd == norm(path)
end

function M:setup(rules, opts)
  self.rules = rules or {}
  self.debug = opts and opts.debug or false

  ps.sub("ind-sort", function(opt)
    local cwd = tostring(cx.active.current.cwd)
    for _, r in ipairs(self.rules) do
      if type(r.path) == "string" and matches(cwd, r.path) then
        opt.by        = r.sort_by or opt.by
        opt.reverse   = r.reverse
        opt.dir_first = r.dir_first
        if self.debug then ya.err("[dirsort] " .. cwd .. " -> " .. tostring(opt.by)) end
        return opt
      end
    end
    return opt
  end)
end

return M

