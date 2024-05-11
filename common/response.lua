--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

local response = { }

function response.build_meta(code, req_time, total_pages)
    local res_time = os.clock()
    local exec_time = (res_time - req_time) * 1000

    local data = {
        request_date   = os.date("%Y-%m-%d %H:%M:%S", req_time),
        response_date  = os.date("%Y-%m-%d %H:%M:%S", res_time),
        execution_time = exec_time
    }

    if total_pages then
        data.total_pages = total_pages
    end

    if ( code ) then
        data.status_code  = 200
    end

    return data
end

function response.send(code, req_time, results, total_pages)
    local meta = response.build_meta(code == 200, req_time, total_pages)

    local msg;
    if ( code == 200 ) then
        msg = { results = results, meta = meta }
    else
        msg = { error = { message = results, status_code = code }, meta = meta }
    end

    return { json = msg };
end

return response