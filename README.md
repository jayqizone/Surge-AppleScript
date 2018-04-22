# Surge-AppleScript

[Surge](https://www.nssurge.com) 是知名的 Mac & iOS 网络分析及代理工具

囿于当前 [Surge CLI](https://medium.com/@Blankwonder/surge-cli-%E5%BC%80%E5%A7%8B%E6%B5%8B%E8%AF%95-70bef9fd7169) 功能及接口文档限制，我们可以用 AppleScript 操纵其 Mac 端的菜单项，以便自定义快捷键或者融入到个人工作流中

## 1. 模拟点击 Surge 菜单栏图标

用常规的 macOS GUI Scripting 方法控制 Surge 有一个问题：

Surge 菜单栏必须先手动点开才能获取及操纵其界面元素，而 AppleScript 的 `click` 却不能点开该菜单


因此需要借助第三方工具来模拟点击鼠标，比如 [Keyboard Maestro](https://www.keyboardmaestro.com/main/)

为了自适应屏幕，可以先获取菜单栏坐标，再进行模拟点击

```AppleScript
tell application "System Events"
    tell process "Surge"
        position of menu bar 2
    end tell
end tell
```

![获取工具栏坐标并点击](https://raw.githubusercontent.com/jayqizone/Surge-AppleScript/master/images/menubar.png)

## 2. macOS GUI Scripting

然后就可以用通用编程方法了，如切换到指定节点

```AppleScript
tell application "System Events"
	tell process "Surge"
		tell menu bar item 1 of menu bar 2
			repeat until menu 1 exists
			end repeat
			tell menu item "策略组名称" of menu 1 to {click, click menu item "节点名称" of menu 1}
		end tell
	end tell
end tell
```

### 例外：出站模式

「出站模式」子菜单项目仍然不能通过 `click` 点击。同样可以用之前的方法获取菜单项坐标，然后进行模拟点击

```AppleScript
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
```

![获取菜单项坐标并点击](https://raw.githubusercontent.com/jayqizone/Surge-AppleScript/master/images/outbound.png)
