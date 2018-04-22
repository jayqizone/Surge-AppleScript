-- 需要先点开菜单栏，否则会持续等待
tell application "System Events"
	tell process "Surge"
		tell menu bar item 1 of menu bar 2
			repeat until menu 1 exists
			end repeat
			tell menu item "策略组名称" of menu 1 to {click, click menu item "节点名称" of menu 1}
		end tell
	end tell
end tell
