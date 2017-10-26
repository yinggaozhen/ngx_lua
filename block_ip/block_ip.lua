-- ip block module for nginx
-- author : Gaozhen Ying
-- email  : yinggaozhen@hotmail.com

package.path='/data/github/ngx_lua/?.lua;'

local lib_redis  = require('lib.redis')
local lib_common = require('lib.common')

local redis_cfg = require('block_ip.config.redis');

local block_ip = {}
local M = block_ip

function M.get_redis_connection()
	local redis = lib_redis:new()

    redis.soft_close = M.soft_close
    redis:set_timeout(redis_cfg.timeout) -- ms

	local ok, err = redis:connect(redis_cfg.host, redis_cfg.port)
	if not ok then
		return nil, err
    end

	return redis
end

function M.soft_close(self)
    return self:set_keepalive(3000, 100) -- max_idle_timeout, pool_size
end

function M.check_ip(ip)
    local connection     = M.get_redis_connection()
    local cache_val, err = connection:get(ip)

    if not cache_val then
        if tonumber(cache_val) == 1 then
            cache_val = 1
        else
            cache_val = 0
        end
        connection:soft_close()
    end

    return tonumber(cache_val) == 1
end

local function reject(msg)
    ngx.header.content_type = "text/plain"
    ngx.status = 403
    msg = msg or "forbidden"
    ngx.say(msg)
    ngx.exit(ngx.status)
end

-- client_ip :　http_x_real_ip > http_x_forwarded_for > remote_addr
local client_ip = lib_common.get_client_ip()

local is_black = M.check_ip(client_ip)

if is_black then
	return reject()
end

