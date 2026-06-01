# 发布流程：草稿 → 上线

线上站点：<https://vibeux.space>（GitHub Pages + 自定义域名）。

**发布分支 = `main`**（Pages 取 `main` 分支的 `docs/` 目录）。
> 第一次请到 GitHub 仓库 **Settings → Pages** 确认一次 Source 分支确实是 `main`。如果不是，把下文的 `main` 换成实际那个分支即可。

## 一条核心规则

> **只有「合并进 `main` 并推送」的内容，才会出现在 vibeux.space。
> 其它任何分支上的东西，公网都看不到。**

这就是你要的「权限开关」：草稿待在别的分支 = 别人看不到、你能随便改；合并进 `main` = 开权限、公开。

---

## 1. 写草稿（别人看不到，自己随便改）

```bash
# 从最新的上线版本开一个草稿分支
git checkout main && git pull
git checkout -b draft/文章名

# 在 docs/writing/ 下新建这篇文章的 HTML，随意编辑
# 本地直接用浏览器打开 docs/writing/xxx.html 预览即可
```

想存档或换设备继续写，可以把草稿分支推上去（**仍然不会上线**）：

```bash
git push -u origin draft/文章名
```

此刻：文章只在草稿分支 → vibeux.space 上没有 → 别人看不到；你可以接着改。

## 2. 发布（开权限，让别人能看到）

定稿后：

```bash
git checkout main && git pull
git merge draft/文章名
git push
```

GitHub Pages 会自动重建，几十秒后文章就出现在 vibeux.space。

## 3. 发布后还想改

继续在草稿分支改 → 再 `git merge draft/文章名` 到 `main` → `git push`，线上版本随之更新。

---

## 两条习惯（避免「不小心提前公开」）

1. **草稿文章的链接不要加进 `main` 上的列表页**。列表里只放已发布的文章；草稿的入口链接只留在草稿分支。这样即使草稿文件哪天上了线，列表里也没人点得到。
2. **每篇文章独立成文件 + 独立提交**，方便「只发布这一篇」，不被其它没写完的草稿连累。

> 注意：GitHub Pages 是公开托管，做不到「登录后才能看」。本方案靠的是「草稿根本不在线上分支」来保证私密——只要不合并进 `main`，就是安全的。

---

## 当前待办（重要）

整套改版目前在 **`design-refresh`** 分支，**尚未合并进 `main`**，所以线上还是旧版。
等你确认改版可以正式上线时，执行：

```bash
git checkout main && git pull
git merge design-refresh
git push
```
