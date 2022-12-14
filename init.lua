-- yaml/init.lua

local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME) .. "/"
local WORLD_PATH = minetest.get_worldpath() .. "/"

local defaultName = "config.yml"

-- export the global yaml object
if (not rawget(_G, MOD_NAME)) then
  yaml = {}

  local function contains(list, x)
    if list == nil then return false end
    for _, v in pairs(list) do
      if v == x then return true end
    end
    return false
  end
  yaml.contains = contains

  local function defaults(t1, t2, exclude)
    if (not t2) then return t1 end
    if (not t1) then return t2 end
    for k,v in pairs(t2) do
      if not contains(exclude, k) then
        if type(v) == "table" then
          if type(t1[k] or false) == "table" then
            defaults(t1[k] or {}, t2[k] or {})
          else
            t1[k] = v
          end
        else
          if (t1[k] == nil or type(t1[k]) ~= type(t2[k])) then t1[k] = v end
        end
      end
    end
    return t1
  end
  yaml.defaults = defaults

  local function readFile(filepath, mode)
    if type(mode) ~= "string" or #mode == 0 then mode = "rb" end
    local f = io.open(filepath, mode)
    if f then
      local content = f:read("*all")
      f:close()
      return content
    end
  end

  local function writeFile(filepath, content, mode)
    if type(mode) ~= "string" or #mode == 0 then
      mode = "wb"
    end
    local f = io.open(filepath, mode)
    if f then
      if mode:sub(1,1) == "a" then
        f:write("\n")
      end
      f:write(content)
      f:close()
      return true
    end
  end

  local Yaml = dofile(MOD_PATH .. "/yaml/yaml.lua")
  yaml.dump = Yaml.dump
  yaml.eval = Yaml.eval

  local function readYamlFile(filepath)
    local content = readFile(filepath)
    if content then
      local result = Yaml.eval(content)
      return result
    end
  end
  yaml.readFile = readYamlFile

  local function readModConfig(filename, modName)
    local modPath = minetest.get_modpath(modName)
    if modPath then
      -- if modPath:sub(-1) ~= "/" then modPath = modPath .. "/" end
      return readYamlFile(modPath .. DIR_DELIM .. filename)
    end
  end
  yaml.readModConfig = readModConfig

  local function readModDataConfig(filename, modName)
    local pattern = "(.*" .. DIR_DELIM .. ")worlds" .. DIR_DELIM .. ".*" .. DIR_DELIM
    local modDataPath = string.match(WORLD_PATH, pattern) .. "mod_data" .. DIR_DELIM ..
    modName .. DIR_DELIM .. filename
    return readYamlFile(modDataPath)
  end
  yaml.readModDataConfig = readModDataConfig

  local function readWorldConfig(filename, modName)
    if modName then filename = modName .. "_" .. filename end
    return readYamlFile(WORLD_PATH .. filename)
  end
  yaml.readWorldConfig = readWorldConfig

  yaml.readConfig = function(modName, filename, exclude)
    if not filename then filename = defaultName end
    local modConf = readModConfig(filename, modName)
    local vModName = minetest.get_current_modname()
    if (vModName) then
      local modData = readModDataConfig(filename, modName)
      modConf = defaults(modData, modConf, exclude)
    end
    local worldConf = readWorldConfig(filename, modName)
    return defaults(worldConf, modConf, exclude)
  end

  local function writeYamlFile(filepath, content, mode)
    local str = Yaml.dump(content)
    if str then
      local result = writeFile(filepath, str, mode)
      return result
    end
  end
  yaml.writeFile = writeYamlFile

  local function writeModConfig(filename, content, modName, mode)
    local modPath = minetest.get_modpath(modName)
    if modPath then
      if modPath:sub(-1) ~= DIR_DELIM then modPath = modPath .. DIR_DELIM end
      return writeYamlFile(modPath .. filename, content, mode)
    end
  end
  yaml.writeModConfig = writeModConfig

  local function writeModDataConfig(filename, content, modName, mode)
    local pattern = "(.*" .. DIR_DELIM .. ")worlds" .. DIR_DELIM .. ".*" .. DIR_DELIM
    local modDataPath = string.match(WORLD_PATH, pattern) .. "mod_data" .. DIR_DELIM ..
    modName .. DIR_DELIM .. filename

    return writeYamlFile(modDataPath, content, mode)
  end
  yaml.writeModDataConfig = writeModDataConfig

  local function writeWorldConfig(content, filename, mode)
    return writeYamlFile(WORLD_PATH .. filename, content, mode)
  end
  yaml.writeWorldConfig = writeWorldConfig

  local function writeConfig(content, filename, modName, mode)
    if not filename then filename = defaultName end
    if modName then filename = modName .. "_" .. filename end
    return writeWorldConfig(content, filename, mode)
  end
  yaml.writeConfig = writeConfig

end

