
local save = function (bucket_name,store_permits,max_permits,current_milli,idle_milli)
	redis.replicate_commands()
	redis.call("HMSET",bucket_name,"store_permits",store_permits,"max_permits",max_permits,"current_milli",current_milli,"idle_milli",idle_milli)
end
 
local bucket_name = KEYS[1]
local permits = tonumber(ARGV[1])
local bucket_infos = redis.call("HMGET",bucket_name,"store_permits","max_permits","current_milli","idle_milli")
local store_permits = bucket_infos[1]
local max_permits = bucket_infos[2]
local current_milli = bucket_infos[3]
local idle_milli = bucket_infos[4]
local sys_time = redis.call("time")
local sys_milli = sys_time[1] * 1000 + sys_time[2] / 1000

if  not store_permits  then
	store_permits = 10
	max_permits = 10
	current_milli = sys_milli
	idle_milli = 100
else
	store_permits = tonumber(store_permits)
	max_permits = tonumber(max_permits)
	current_milli = tonumber(current_milli)
	idle_milli = tonumber(idle_milli)
end

if permits > max_permits then
	redis.log(redis.LOG_NOTICE,"************ too max 1**************")
	return false;
end

if permits <= store_permits then
		redis.log(redis.LOG_NOTICE,"************ success **************")

	current_milli = sys_milli
	store_permits = store_permits - permits
	save(bucket_name,store_permits,max_permits,current_milli,idle_milli)
		return true;
else
	local current_idle_milli = sys_milli - current_milli 
	local current_idle_number = current_idle_milli / idle_milli
	if store_permits + current_idle_number > max_permits then
		store_permits = max_permits
	end

	if permits > max_permits then
		redis.log(redis.LOG_NOTICE,"************ too max 2**************")
		save(bucket_name,store_permits,max_permits,current_milli,idle_milli)
		return false;
	else
		redis.log(redis.LOG_NOTICE,"************ success **************")
		store_permits = store_permits - permits
		save(bucket_name,store_permits,max_permits,current_milli,idle_milli)
		return true;
	end
end


