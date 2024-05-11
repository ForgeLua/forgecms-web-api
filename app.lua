--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

local lapis = require("lapis")
local app   = lapis.Application()

-- Require routers
local jwt_router     = require("modules.jwt.jwt_router")
local news_router    = require("modules.news.news_router")

-- Call routers
jwt_router( app )
news_router( app )

-- Handle Error
app.handle_404 = function (self)
    return { status = 404, json = { error = "Error 404 : The specified path is invalid" } }
end

app.handle_error = function (self, err, trace)
    return { status = 500, json = { error = "Error 500 : Internal server error", detail = err, trace = trace } }
end

return app