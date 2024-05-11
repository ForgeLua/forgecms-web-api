--[[
    Copyright (C) 2024 - ForgeCMS
    This program is free software licensed under the GNU General Public License v3.0 (GPL-3.0)
    Please see the included LICENSE file for more information
    
    @Authors : iThorgrim
    @Contributors : M4v3r1ck0, alexis-piquet
]]--

--[[ Crypto Lib ]]--
local Openssl_bn       = require("resty.openssl.bn")
local Openssl_rd       = require("resty.openssl.rand")
local Openssl_dg       = require("resty.openssl.digest")

local srp6 = { }

function srp6.calculate_verifier(username, password, salt)
    local g = Openssl_bn.new(7)  -- Set the constant 'g' to 7
    local N = Openssl_bn.from_hex("894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7", 16)  -- Set the constant 'N' using hexadecimal representation

    -- Calculate the first hash (h1)
    local sha_username_password = Openssl_dg.new("SHA1", true)
        sha_username_password:update(string.upper(string.upper(username) .. ':' .. string.upper(password)))
    sha_username_password = sha_username_password:final()

    -- Calculate the second hash (h2)
    local sha_salt = Openssl_dg.new("SHA1", true)
        sha_salt:update(salt .. sha_username_password)
    sha_salt = sha_salt:final()

    local sha_salt_endian = srp6.reverse_endian(sha_salt)

    -- Calculate g^h2 mod N
    local sha_salt_bn = Openssl_bn.from_binary(sha_salt_endian)
    local verifier_bn = Openssl_bn.mod_exp(g, sha_salt_bn, N)
    local verifier_bin = Openssl_bn.to_binary(verifier_bn)

    -- Convert the verifier to a byte array (little-endian) and pad it to 32 bytes
    local verifier = srp6.reverse_endian(verifier_bin)
    return verifier or nil
end

function srp6.generate_salt()
    return Openssl_rd.bytes(32)
end

function srp6.reverse_endian(str)
    local reversed = ""
    for i = #str, 1, -1 do
        reversed = reversed .. string.char(str:byte(i))
    end

    return reversed
end

return srp6