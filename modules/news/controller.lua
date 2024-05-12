--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

local entity           = require("modules.news.entity")
local meta             = require("common.meta")
local pagination       = require("common.pagination")
local response         = require("common.response")

local req_time         = os.clock()
local controller       = { }

function controller.list(self)
    local page, size    = pagination.get_page_and_size(self.params)
    local all_news      = entity.list(page, size)
    local total_pages   = entity.count(size)

    local news_info = {}
    for _, news in ipairs(all_news) do
        news_info[news.id] = {
            title   = news.title,
            image   = news.image,
            date    = news.date,
            author  = news.author
        }
    end

    return response.send(200, req_time, news_info, total_pages)
end

function controller.get(self)
    local news = entity.get(self.params.id)
    return response.send(200, req_time, news)
end

return controller