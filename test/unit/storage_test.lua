
local t = require('luatest')
local g = t.group('unit_storage_utils')
local helper = require('test.helper.unit')

require('test.helper.unit')
local storage = require('app.roles.storage')
local utils = storage.utils
local deepcopy = helper.shared.deepcopy

local s = { ["firm"] = 'Mersedes', ["model"] = 'AMG'}
local val = deepcopy(s)
local test_car = {
    key = "1",
    bucket_id = 1,
    value= "",
}

local test_car_no_shadow = deepcopy(test_car)
test_car_no_shadow.bucket_id = nil

test_car_no_shadow.value = val
test_car.value = val

g.test_sample = function()
    t.assert_equals(type(box.cfg), 'table')
end

g.test_car_get_not_found = function()
    local res = utils.car_get(tostring(1))
    res.error = res.error.err
    t.assert_equals(res, {car = nil, error = "car not found"})
end

g.test_car_get_found = function()
    box.space.cars:insert(box.space.cars:frommap(test_car))
    t.assert_equals(utils.car_get(tostring(1)), {car = test_car_no_shadow, error = nil})
end

g.test_car_add_ok = function()
    local to_insert = deepcopy(test_car)
    to_insert.value = val
    t.assert_equals(utils.car_add(to_insert), {ok = true})
    local from_space = box.space.cars:get(tostring(1))

    t.assert_equals(from_space, box.space.cars:frommap(to_insert))
end

g.test_car_add_conflict = function()
    box.space.cars:insert(box.space.cars:frommap(test_car))
    local res = utils.car_add(test_car)
    res.error = res.error.err
    t.assert_equals(res, {ok = false, error = "car already exist"})
end

g.test_profile_update_ok = function()
    box.space.cars:insert(box.space.cars:frommap(test_car))

    local changes = {
        model = "Maybach "
    }

    local car_upd = deepcopy(test_car)
    car_upd.value = changes

    t.assert_equals(utils.car_update(tostring(1), changes), {car = changes})
    t.assert_equals(box.space.cars:get(tostring(1)), box.space.cars:frommap(car_upd))
end

g.test_car_update_not_found = function()
    local res = utils.car_update(tostring(1),{year = 2020})
    res.error = res.error.err
    t.assert_equals(res, {car = nil, error = res.error})
end

g.test_profile_delete_ok = function()
    box.space.cars:insert(box.space.cars:frommap(test_car))
    t.assert_equals(utils.car_delete(tostring(1)), {ok = true})
    t.assert_equals(box.space.cars:get(tostring(1)), nil)
end

g.test_profile_delete_not_found = function()
    local res = utils.car_delete(tostring(1))
    res.error = res.error.err
    t.assert_equals(res, {ok = false, error = "car not found"})
end


g.before_all(function()
    storage.init({is_master = true})
end)

g.before_each(function ()
    box.space.cars:truncate()
end)