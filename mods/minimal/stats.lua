-- collection of statistical means
stats = {}

----- Running mean -----

-- `running_mean`: Defines a class to work with running means based on up to
--     `base_count` values (see new(base_count))
stats.running_mean = {}

-- `running_mean:include(value)`: Includes `value` into the calculation,
--     replacing the oldest value, if there were already `base_count` values
--     included.
function stats.running_mean:include(value)
    if self.count then
        local drop_value = self.values[self.next_store]
        if drop_value then
            self.total = self.total - self.values[self.next_store]
            self.count = self.count - 1
        end
    end
    self.values[self.next_store] = value
    self.next_store = self.next_store % self.base_count + 1
    self.total = self.total + value
    self.count = self.count + 1
end

-- `running_mean:mean()`: Returns the average of all currently included values
--     or 0 if there are no values.
function stats.running_mean:mean()
    if self.count == 0 then return 0 end
    return self.total / self.count;
end

-- `running_mean:mean`: Constructs a new object to calculate the running mean
--     of up to `base_count` included values.
-- `base_count`: max. number of values to consider; must be a number or nil;
--     default: 5
function stats.running_mean:new(base_count)
    local instance = {
        include = self.include,
        mean = self.mean,
        values ={},
        next_store = 1,
        total = 0,
        count = 0,
        base_count = base_count or 5
    }
    return instance;
end
