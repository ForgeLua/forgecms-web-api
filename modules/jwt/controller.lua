--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

local jwt        = require("luajwtjitsi")
local secret     = require("secret")
local controller = { }

local function generate_token()
    local payload = {
        iss = "",
        nbf = os.time(),
        exp = os.time() + 31536000
    }

    local token, err = jwt.encode( payload, secret, "HS256" )
    if ( err ) then
        error( string.format( "Erreur lors de la génération du token : %s", err ) )
    end

    return token
end

local function verify_token(token)
    local payload, err = jwt.verify(token, "HS256", secret)

    if err then
        return nil, err
    else
        return payload
    end
end

function controller.decode(self)
    local authHeader = self.req.headers.Authorization
    if not authHeader then
        self:write({ status = 401, json = { error = "Token is missing" } })
        return false
    end

    local token = authHeader:match('Bearer (.+)')
    if not token then
        self:write({ status = 401, json = { error = "Token format is invalid" } })
        return false
    end

    local payload, err = verify_token(token)
    if err then
        self:write({ status = 403, json = { error = "Token is invalid" } })
        return false
    end
end

return controller