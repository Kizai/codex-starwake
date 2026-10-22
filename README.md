# Codex Starwake ✨

**用一场星海，开启每一次创造。**

Cinematic startup animations for Codex on macOS.

中文 · [English](README.en.md)

![守岸人 · 星海苏醒](docs/images/shorekeeper-preview.png)

给 Codex 的每一次启动，加上 6.8 秒的「星海苏醒」：蓝蝶振翅、星尘流动、海面涟漪与缓慢推进的镜头。默认主题为《鸣潮》守岸人的 AI 同人主视觉。

[观看动画演示](docs/demo.mp4) · [详细安装说明](docs/INSTALL.md) · [素材声明](NOTICE.md)

## 它如何工作

安装后，一个随登录运行的小助手接收 macOS 的应用启动事件。发现 `com.openai.codex` 启动时，用原生 WebKit 窗口播放动画，结束后切回 Codex。

- 从 Dock、访达或原来的应用图标**完全退出后再打开**，自动播放。
- 切换窗口、切换任务或点击已经运行的应用，不会重复播放。
- 无需修改官方应用、签名或 `app.asar`，无需 CDP 调试端口。
- 运行时离线，无遥测、远程字体或账号权限；等待系统事件时不循环轮询。
- Escape 或右上角「跳过」可立即结束；单实例锁防止多段动画叠加。
- 可随时停用、重新启用；卸载会将项目安装文件移到废纸篓，便于恢复。

动画在独立窗口中播放，并非官方内置的启动画面。角色使用静态原画，动态由镜头、蓝蝶、粒子和光效组成。界面中的进度条表示动画进度。

## 快速安装

需要 **macOS 13+**、Codex 桌面应用和 **Apple Command Line Tools**。支持 Apple Silicon / Intel，首次安装会在本机编译。运行不需要 Node.js、Python 或第三方 Swift 包。

```sh
# 首次使用 Swift 编译器时安装（已安装可跳过）
xcode-select --install

git clone https://github.com/Kizai/codex-starwake.git
cd codex-starwake
zsh scripts/install.sh
```

也可以下载并解压 GitHub 的源码 ZIP，然后双击 **Install.command**。请以普通用户运行，无需 `sudo`。编译工具安装完成后，再执行项目安装命令。

完成后，完全退出 Codex 再重新打开即可。安装不会结束正在运行的会话，当前已经打开的应用也不会立即触发动画。

部分 Codex 版本的应用名显示为 ChatGPT；本项目按 bundle identifier `com.openai.codex` 识别，不依赖应用显示名称。普通 ChatGPT 客户端只有在符合这个标识时才会匹配。

### 先看看效果

```sh
zsh scripts/preview.sh   # 原生窗口预览，不打开 Codex
open web/index.html     # 浏览器预览：空格重播，Escape 跳过
```

原生预览也可双击 **Preview.command**。浏览器预览无需安装编译工具。

### 停用、恢复与卸载

```sh
zsh scripts/status.sh
zsh scripts/disable.sh
zsh scripts/enable.sh
zsh scripts/uninstall.sh
```

也可以双击 **Disable.command**、**Enable.command**、**Uninstall.command**。卸载会停止助手、移除登录启动项，并把本项目安装目录与 plist 移入废纸篓；Codex 自身、会话和模型配置不受影响。

安装后可以移动或删除源码仓库。独立安装副本位于：

```text
~/Library/Application Support/Codex Starwake/
~/Library/LaunchAgents/io.github.kizai.codex-starwake.plist
```

源码删除后，安装目录里的 Enable / Disable / Uninstall.command 仍然可用。更新时拉取代码后重新运行安装脚本即可；重新安装会覆盖安装副本中的默认动画文件。

## 换一张主视觉

替换源码中的 `web/assets/shorekeeper.png`，保持文件名，再运行 `zsh scripts/install.sh`。建议使用约 16:9 的横向素材，人物放在右侧，左侧为文字留出暗色空间。网页文字在 `web/index.html`，排版在 `web/style.css`，动画在 `web/animation.js`。

请使用你拥有使用权限的图片；发布主题时附上作者和素材来源。当前版本提供一个默认主题，暂不包含主题商店或图形化切换器。

## 开发与验证

开发测试需要 Node.js 20+。先装好 Apple Command Line Tools，再运行：

```sh
zsh scripts/check.sh       # Swift 编译、shell/JS 语法、隔离的安装/卸载测试
npm ci                    # 仅浏览器测试需要 Playwright
npx playwright install chromium
npm run test:browser      # 桌面/窄屏、跳过、重播、离线资源检查
```

测试安装使用临时目录并跳过 launchctl，不改变你的实际登录启动项。GUI 生命周期、登录后的事件触发需要在真实桌面会话中验证；CI 的编译通过不等于这些行为已经自动验证。

项目结构：

```text
native/Starwake.swift      原生窗口、启动事件监听、应用唤起
web/                      零依赖网页动画与默认主视觉
scripts/                  编译、安装、状态、启停与卸载
tests/                    隔离安装测试与浏览器测试
docs/                     安装说明、预览和生成提示词
```

## 许可与致谢

原始代码和文档采用 [MIT License](LICENSE)，保留仓库作者 Kizai 的署名。默认角色主视觉及其截图、演示属于另行说明的 AI 同人展示素材，详见 [NOTICE.md](NOTICE.md)。《鸣潮》、守岸人、Codex 及相关商标和角色权利归各自权利人；本项目没有官方关联或背书。

实现采用 Swift / AppKit / WebKit 的独立窗口与 macOS 启动事件；没有复制 Codex Dream Skin 的代码。感谢该项目提供的个性化桌面外观灵感。
