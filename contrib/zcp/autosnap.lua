-- Recursively snapshot every dataset with a given property
--
-- Usage: zfs program <pool> autosnap.lua [noop] [<property>] <snapshot>

results = {}

args = ...
argv = args["argv"]
usage = [[


usage: zfs program <pool> autosnap.lua [noop] [<property>] <snapshot>

	noop: performs checks only, does not take snapshots
	property: property to check. [default=com.sun:auto-snapshot]
	snapshot: root snapshot to create example: tank@backup
]]

if #argv == 0 then
	error(usage)
end

noop = false
-- 'noop' is a workaround for issue #9056
if argv[1] == "noop" or argv[1] == "-n" then
	noop = true
	table.remove(argv, 1)
end

if #argv == 0 then
	error(usage)
end

property = "com.sun:auto-snapshot"
if #argv > 1 then
	property = table.remove(argv, 1)
end

root_snap = argv[1]

root_ds_name = ""
snap_name = ""
for i = 1, #root_snap do
	if root_snap:sub(i, i) == "@" then
		root_ds_name = root_snap:sub(1, i-1)
		snap_name = root_snap:sub(i+1, root_snap:len())
	end
end

function auto_snap(root)
	auto, source = zfs.get_prop(root, property)
	if auto == "true" then
		ds_snap_name = root .. "@" .. snap_name
		err = 0
		if noop then
			err = zfs.check.snapshot(ds_snap_name)
		else
			err = zfs.sync.snapshot(ds_snap_name)
		end
		results[ds_snap_name] = err
	end
	for child in zfs.list.children(root) do
		auto_snap(child)
	end
end

auto_snap(root_ds_name)
err_txt = ""
for ds, err in pairs(results) do
	if err ~= 0 then
		err_txt = err_txt .. "failed to create " .. ds .. ": " .. err .. "\n"
	end
end
if err_txt ~= "" then
	error(err_txt)
end

return results
