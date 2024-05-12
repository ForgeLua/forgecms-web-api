--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

local lapis      = require("lapis")
local database   = require("lapis.db")
local model      = require("lapis.db.model").Model
local news       = model:extend("news")

local entity     = { }

function entity.count(size)
    return math.ceil(news:count() / size)
end

--[[ Start :: All Section ]]--
function entity.list(page, size)
    return database.query("SELECT id, title, image, date, author FROM news ORDER BY id LIMIT ?, ?;", ( page - 1 ) * size, size)
end
--[[ End   :: All Section ]]--

return entity