--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

local pagination = {}

function pagination.get_page_and_size(params)
    local page = tonumber(params.page) or 1
    local size = tonumber(params.size) or 10
    return page, size
end

return pagination