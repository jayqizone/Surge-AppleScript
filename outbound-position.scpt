-- 需要先点开菜单栏，否则会持续等待
tell application "System Events"
	tell process "Surge"
		tell menu bar item 1 of menu bar 2
			repeat until menu 1 exists
			end repeat
			tell menu item 1 of menu 1
				click
				-- menu item 1: 直接连接, 3: 全局代理, 5: 规则判定
				position of menu item 1 of menu 1
			end tell
		end tell
	end tell
end tell
