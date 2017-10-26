local common = {};

local M = common;

M.version = '0.0.0';

-- http_x_real_ip > http_x_forwarded_for > remote_addr
function M.get_client_ip()
    local ip = ngx.var.remote_addr

    local x_real_ip = ngx.var.http_x_real_ip
    if x_real_ip then
        ip = x_real_ip
    end

    local x_forwarded_for = ngx.var.http_x_forwarded_for
    if x_forwarded_for then
        local ip1 = string.gsub(x_forwarded_for, "^([%d.]+).*", "%1")
        if ip1 then
            ip = ip1
        end
    end

    return ip
end


function M.hello()
    return "hello world";
end

return M;