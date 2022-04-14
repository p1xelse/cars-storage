local checks = require('checks')
local errors = require('errors')
local log = require('log')



local err_storage = errors.new_class("Storage error")

local function tuple_to_table(format, tuple)
    local map = {}
    for i, v in ipairs(format) do
        map[v.name] = tuple[i]
    end
    return map
end

local function init_space()
    local cars = box.schema.space.create(
        'cars',
        {
            format = {
                {'key', 'string'},
                {'bucket_id', 'unsigned'},
                {'value', 'any'},
            },

            if_not_exists = true,
        }
    )

    cars:create_index('key', {
        parts = {'key'},
        if_not_exists = true,
    })

    cars:create_index('bucket_id', {
        parts = {'bucket_id'},
        unique = false,
        if_not_exists = true,
    })
end

local function car_add(car)
    checks('table')

    local exist = box.space.cars:get(car.key)
    if exist ~= nil then
        log.info("car with id %d already exist", car.key)
        return {ok = false, error = err_storage:new("car already exist")}
    end

    box.space.cars:insert(box.space.cars:frommap(car))

    return {ok = true, error = nil}
end

local function car_update(key, changes)
    checks('string', 'table')

    local exists = box.space.cars:get(key)

    if exists == nil then
        log.info("car with id %d not found", key)
        return {car = nil, error = err_storage:new("car not found")}
    end

    exists = tuple_to_table(box.space.cars:format(), exists)
    exists.value = changes

    box.space.cars:replace(box.space.cars:frommap(exists))

    changes.bucket_id = nil

    return {car = changes, error = nil}
end

local function car_get(id)
    checks('string')
    
    local car = box.space.cars:get(id)
    if car == nil then
        log.info("car with id %s not found", id)
        return {cars = nil, error = err_storage:new("car not found")}
    end

    car = tuple_to_table(box.space.cars:format(), car)
    
    car.bucket_id = nil
    return {car = car, error = nil}
end

local function car_delete(key)
    checks('string')
    
    local exists = box.space.cars:get(key)
    if exists == nil then
        log.info("car with id %d not found", key)
        return {ok = false, error = err_storage:new("car not found")}
    end
    exists = tuple_to_table(box.space.cars:format(), exists)

    box.space.cars:delete(key)
    return {ok = true, error = nil}
end

local function init(opts)
    if opts.is_master then
        init_space()

        box.schema.func.create('car_add', {if_not_exists = true})
        box.schema.func.create('car_get', {if_not_exists = true})
        box.schema.func.create('car_update', {if_not_exists = true})
        box.schema.func.create('car_delete', {if_not_exists = true})
    end

    rawset(_G, 'car_add', car_add)
    rawset(_G, 'car_get', car_get)
    rawset(_G, 'car_update', car_update)
    rawset(_G, 'car_delete', car_delete)

    return true
end

return {
    role_name = 'storage',
    init = init,
    utils = {
        car_add = car_add,
        car_update = car_update,
        car_get = car_get,
        car_delete = car_delete,
    },
    dependencies = {
        'cartridge.roles.vshard-storage'
    }
}