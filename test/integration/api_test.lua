local t = require('luatest')
local g = t.group('integration_api')

local helper = require('test.helper.integration')
local cluster = helper.cluster
local deepcopy = require('table').deepcopy


local s = { ["name"] = 'War and peace', ["author"] = 'Leo Tolstoy'}
local val = deepcopy(s)
local test_car = {
    key = "1",
    value= "",
}
test_car.value=s

g.test_sample = function()
    local server = cluster.main_server
    local response = server:http_request('post', '/admin/api', {json = {query = '{}'}})
    t.assert_equals(response.json, {data = {}})
    t.assert_equals(server.net_box:eval('return box.cfg.memtx_dir'), server.workdir)
end


g.test_on_get_not_found = function()
    helper.assert_http_json_request('get', '/kv/1', {}, {body = {info = "car not found"}, status = 404})
end
g.test_on_post_ok = function ()
    local new_car = deepcopy(test_car)
    helper.assert_http_json_request('post', '/kv', new_car, {body = {info = "Successfully created"}, status=201})
end

g.test_on_post_conflict = function()
    local new_car = deepcopy(test_car)
    helper.assert_http_json_request('post', '/kv', new_car, {body = {info = "car already exist"}, status=409})
end

g.test_on_get_ok = function ()
    helper.assert_http_json_request('get', '/kv/1', {}, {body = test_car, status = 200})
end

g.test_on_put_not_found = function()
    local changes = {
        ['year'] = '2020'
    }
    helper.assert_http_json_request('put', '/kv/2', {value = changes},{body = {info = "car not found"}, status = 404})
end

g.test_on_put_ok = function()
    local change_car = deepcopy(test_car)
    change_car.value = val
    helper.assert_http_json_request('put', '/kv/1', {value = val}, {body = val, status = 200})
end

g.test_get_after_put = function ()
    local expect_car = deepcopy(test_car)
    expect_car.value = val
    helper.assert_http_json_request('get', '/kv/1', {}, {body = expect_car, status = 200})
    
end

g.test_on_delete_not_found = function ()
    helper.assert_http_json_request('delete', '/kv/2', {}, {body = {info = "car not found"}, status = 404})
end

g.test_on_delete_ok = function()
    helper.assert_http_json_request('delete', '/kv/1', {}, {body = {info = "Deleted"}, status = 200})
end

g.test_not_found_after_delete_ok = function()
    helper.assert_http_json_request('get', '/kv/1', {}, {body = {info = "car not found"}, status = 404})
end
