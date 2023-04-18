sqlite3 = require 'lsqlite3'

db = sqlite3.open("db.sqlite3")

function get_db_version()
	for version in db:urows("PRAGMA user_version") do
		return version
	end
end

version = get_db_version()
print("current db version:", version)

if version == 0 then
	res = db:exec[[
	  CREATE TABLE requests (
	    id INTEGER PRIMARY KEY,
	    status INTEGER,
	    path TEXT,
	    ip TEXT,
	    time_secs INTEGER,
	    time_nanos INTEGER
	  )
	]]
	assert(res == sqlite3.OK)

	db:exec("PRAGMA user_version = 1")
	new_version = get_db_version()
	print("upgraded database to version", new_version)
end

db:close()


function SetupSql()
	db = sqlite3.open('db.sqlite3')
	db:busy_timeout(1000)
	db:exec[[PRAGMA journal_mode=WAL]]
	db:exec[[PRAGMA synchronous=NORMAL]]
	return db
end

function OnHttpRequest()
	db = SetupSql()

	Route()
	status = GetStatus()
	print("status", status)
	if status == 403 then
		-- we want to mask out directories to prevent people from snooping around
		ServeError(404)
	end
	path = GetPath()
	remote_addr = GetRemoteAddr()
	-- client_addr = GetClientAddr()

	time_secs, time_nanos = unix.clock_gettime()

	insert_stmt = db:prepare[[
		INSERT INTO requests (status, path, ip, time_secs, time_nanos)
		VALUES (?, ?, ?, ?, ?)
	]]

	insert_stmt:bind_values(
		status, 
		path, 
		FormatIp(remote_addr), 
		time_secs,
		time_nanos)

	for result in insert_stmt:nrows() do
		print("unexpected")
	end

	result = insert_stmt:finalize()
	assert(result == sqlite3.OK)

end
