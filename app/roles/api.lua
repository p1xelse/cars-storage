local cartridge = require('cartridge')
local errors = require('errors')
local log = require('log')
local json = require('json')

local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")

local function json_response(req, json, status)
    local resp = req:render({json = json})
    resp.status = status
    return resp
end

local function internal_error_response(req, error)
    log.info("Error response")
    local resp = json_response(req, {
        info = "Internal error",
        error = error
    }, 500)
    return resp
end

local function car_not_found_response(req)
    log.info("Car not found")
    local resp = json_response(req, {
        info = "car not found"
    }, 404)
    return resp
end

local function car_conflict_response(req)
    log.info("Conflict Response")
    local resp = json_response(req, {
        info = "car already exist"
    }, 409)
    return resp
end

local function car_incorrect_body_response(req, car)
    log.info("Incorrect body %s", car)
    local resp = json_response(req, {
        info = "Incorrect body in request"
    }, 400)
    return resp
end


local function storage_error_response(req, error)
    if error.err == "car already exist" then
        return car_conflict_response(req)
    elseif error.err == "car not found" then
        return car_not_found_response(req)
    elseif error.err == "Incorrect body" then
        return car_incorrect_body_response(req, nil)
    else
        return internal_error_response(req, error)
    end
end

local function http_car_add(req)
    local status, car = pcall(req.json, req)
    if status == false then
        return car_incorrect_body_response(req, car)
    end

    if type(car) ~= 'table' or type(car.value) ~= 'table' then
        return car_incorrect_body_response(req, json.encode(car))
    end

    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(car.key)
    car.bucket_id = bucket_id

    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'write',
        'car_add',
        {car}
    )

    if error then
        return internal_error_response(req, error)
    end
    if resp.error ~= nil then
        return storage_error_response(req, resp.error)
    end
    return json_response(req, {info = "Successfully created"}, 201)
end

local function http_car_update(req)
    local car_id = tostring(req:stash('id'))
    if car_id == nil then 
        return internal_error_response(req)
    end

    local status, data = pcall(req.json, req)
    if status == false then
        return car_incorrect_body_response(req, data)
    end
    
    local changes = data.value
    if type(changes) ~= 'table' then 
        return car_incorrect_body_response(req, json.encode(data))
    end

    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(car_id)
    
    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'read',
        'car_update',
        {car_id, changes}
    )

    if error then
        return internal_error_response(req,error)
    end
    if resp.error then
        return storage_error_response(req, resp.error)
    end
    
    return json_response(req, resp.car, 200)
end

local function http_car_get(req)
    local car_id = tostring(req:stash('id'))
    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(car_id)

    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'read',
        'car_get',
        {car_id}
    )

    if error then
        return internal_error_response(req, error)
    end
    if resp.error then
        return storage_error_response(req, resp.error)
    end

    return json_response(req, resp.car, 200)
end

local function http_car_delete(req)
    local key = tostring(req:stash('id'))
    local router = cartridge.service_get('vshard-router').get()
    local bucket_id = router:bucket_id(key)


    local resp, error = err_vshard_router:pcall(
        router.call,
        router,
        bucket_id,
        'write',
        'car_delete',
        {key}
    )

    if error then
        return internal_error_response(req, error)
    end
    if resp.error then
        return storage_error_response(req, resp.error)
    end

    return json_response(req, {info = "Deleted"}, 200)
end

local function init(opts)
    if opts.is_master then
        box.schema.user.grant('guest',
            'read,write',
            'universe',
            nil, { if_not_exists = true }
        )
    end

    local httpd = cartridge.service_get('httpd')

    if not httpd then
        return nil, err_httpd:new("not found")
    end

    log.info("Starting httpd")

    httpd:route(
        { path = '/kv', method = 'POST', public = true },
        http_car_add
    )
    httpd:route(
        { path = '/kv/:id', method = 'GET', public = true },
        http_car_get
    )
    httpd:route(
        { path = '/kv/:id', method = 'PUT', public = true },
        http_car_update
    )
    httpd:route(
        {path = '/kv/:id', method = 'DELETE', public = true},
        http_car_delete
    )

    log.info("Created httpd")
    return true
end

return {
    role_name = 'api',
    init = init,
    
    dependencies = {
        'cartridge.roles.vshard-router'
    }
}