# Surge-AppleScript

[Surge](https://www.nssurge.com) 是知名的 Mac & iOS 网络分析及代理工具

但是高频功能总是需要点击菜单，并不高效。囿于当前还没有官方接口可资利用，我们可以采用 macOS 原生操纵 App 界面元素的方法，将这些功能绑定到全局快捷键或者融入到个人工作流中

> 需要给 Keyboard Maestro Engine 赋予辅助功能权限，其它工具同

![辅助功能权限](https://raw.githubusercontent.com/jayqizone/Surge-AppleScript/master/images/accessibility.png)

## 1. 调用菜单中已绑定快捷键的功能

最简单的，是调用菜单中已经存在的快捷键，这只需要先展开菜单，然后模拟按键即可

但这第一步用常规的方法时却遇到问题，在 AppleScript 中用 `click` 动作并不能点开该菜单：

```applescript
tell application "System Events"
	tell process "Surge"
		click menu bar item 1 of menu bar 2 -- 无效
	end tell
end tell
```

经过研究，发现可以用 `perform action "AXShowMenu"` 解决，于是最终脚本如下：

```applescript
tell application "System Events"
	tell process "Surge"
		tell menu bar item 1 of menu bar 2
			perform action "AXShowMenu"
			keystroke "d" using command down -- 模拟按下 ⌘+D，对应「控制台」功能
		end tell
	end tell
end tell
```

## 2. 点选菜单中的功能

关于 AppleScript 的 UI 操作，Surge 相比其它 App，有两点比较特殊，容易踩坑：
1. 必须先展开菜单栏，才能获取菜单元素
2. 如果还有子菜单，要逐层展开，不能只用一次 `click` 直击目标菜单项

第一个问题之前已经解决了，第二个问题只要逐次点击即可：

```applescript
tell application "System Events"
	tell process "Surge"
		tell menu bar item 1 of menu bar 2
			perform action "AXShowMenu"
			tell menu item "策略组名称" of menu 1 to {click, click menu item "节点名称" of menu 1} -- 点选「某策略组 -> 某节点」
		end tell
	end tell
end tell
```

自然，前述模拟按下快捷键调用的功能，也可以换用此方式实现

## 3. 例外：出站模式

虽然已经解决了一些前置问题，但是特殊情况总是存在的

同样具有子菜单，「策略组 -\> 节点」、「切换配置」，都可以用前面的方式操作，唯独「出站模式」，其子菜单项，再次不响应 `click` 动作。这次不可用 `perform action "AXShowMenu"` 解决，尝试使用其它预定义的 action（如 AXPress、AXPick 等）也不奏效，只能换其它思路

### 3.1 第三方工具辅助点击

一个想法是，用第三方工具，帮我们完成这最后一步模拟鼠标点击的操作，那么我们需要的，就只是目标菜单项的坐标，这很容易：

```applescript
tell application "System Events"
	tell process "Surge"
		tell menu bar item 1 of menu bar 2
			perform action "AXShowMenu"
			tell menu item 1 of menu 1 -- menu item 1 是菜单第一项，即「出站模式」
				click
				position of menu item 1 of menu 1 -- menu item 1 是子菜单第一项，即「直连」，因为分割线的缘故，「全局」和「规则」分别对应 menu item 3 和 5
			end tell
		end tell
	end tell
end tell
```

而这个「第三方工具」，其实 [Keyboard Maestro](https://www.keyboardmaestro.com/main/) 就可以胜任，如图：

![获取菜单项坐标并点击](https://raw.githubusercontent.com/jayqizone/Surge-AppleScript/master/images/outbound.png)

### 3.2 系统原生框架编程

当然还有一个愿望：原生实现最好

思路还是一样的：替代 `Click`，用更「底层」的方式模拟点击操作

联合使用 Objective-C，也是可以做到的，只是有些破坏 AppleScript 使用自然语义编程通俗易懂的优点。下面用 JXA（AppleScript 孪生兄弟）给出一个实现：

```js
// Objective-C Bridge
ObjC.import('AppKit');

// 获取鼠标原始坐标
var event = $.CGEventCreate($());
var orig = $.CGEventGetLocation(event);
$.CFRelease(event);

// 展开菜单。注意：JavaScript 中下标从 0 开始
var menu = Application('System Events').processes.Surge.menuBars[1].menuBarItems[0];
menu.actions.AXShowMenu.perform();
// 获取目标菜单项的坐标并点击。注意：最后一个 menuItems 的索引应为 0、2、4，对应「直连」、「全局」、「规则」
clickMouse(...menu.menus[0].menuItems[0].click().menus[0].menuItems[4].position());

// 恢复鼠标原始坐标
moveMouse(orig.x, orig.y);

// 点击鼠标
function clickMouse(x, y) {
	let event = $.CGEventCreateMouseEvent($(), $.kCGEventLeftMouseDown, $.CGPointMake(x, y), $.kCGMouseButtonLeft);
	$.CGEventPost($.kCGHIDEventTap, event);
	// 少许延迟
	delay(0.1)
	$.CGEventSetType(event, $.kCGEventLeftMouseUp);
	$.CGEventPost($.kCGHIDEventTap, event);
	$.CFRelease(event);
}

// 移动鼠标
function moveMouse(x, y) {
	let event = $.CGEventCreateMouseEvent($(), $.kCGEventMouseMoved, $.CGPointMake(x, y), $.kCGMouseButtonLeft);
	$.CGEventPost($.kCGHIDEventTap, event);
	$.CFRelease(event);
}
```

JXA 在 Shell 中的调用方式是 `osascript -l JavaScript xxx.js`；在 Keyboard Maestro 中是：

![JXA 联合 ObjC 框架](https://raw.githubusercontent.com/jayqizone/Surge-AppleScript/master/images/jxa.png)
