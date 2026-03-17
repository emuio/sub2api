# Fork 二开部署说明

这个目录适合你维护自己的 `sub2api` fork，重点场景是：

- 改 UI 文案、Logo、布局、主题
- 增加你自己的前端展示逻辑
- 保持 Docker 部署方式不变，但镜像由你自己的源码构建

仓库里现在同时提供两套方式：

- 本地源码构建：`deploy/docker-compose.custom.yml`
- 远端服务器拉 GHCR 镜像：`deploy/docker-compose.ghcr.yml`
- 服务器切换脚本：`deploy/use-custom-ui.sh`、`deploy/use-official-ui.sh`

## 推荐分支

```bash
git checkout ui-custom
```

日常只在 `ui-custom` 上改动，`main` 尽量保持接近官方。

## 首次启动

在仓库根目录执行：

```bash
cp deploy/.env.example deploy/.env
mkdir -p deploy/data deploy/postgres_data deploy/redis_data
docker compose -f deploy/docker-compose.custom.yml --env-file deploy/.env up -d --build
```

说明：

- `docker-compose.custom.yml` 会直接用当前源码构建镜像，不再拉官方 `weishaw/sub2api:latest`
- 你的前端修改会在镜像构建时自动编译并嵌入后端
- 数据目录仍然在 `deploy/data`、`deploy/postgres_data`、`deploy/redis_data`

## 改完 UI 后重新部署

```bash
docker compose -f deploy/docker-compose.custom.yml --env-file deploy/.env up -d --build
```

如果只是重启：

```bash
docker compose -f deploy/docker-compose.custom.yml --env-file deploy/.env restart
```

## GitHub Actions 自动构建镜像

仓库新增了工作流：

- `.github/workflows/custom-image.yml`

触发方式：

- 推送到 `ui-custom`
- 手动执行 `workflow_dispatch`

默认会推送到：

```bash
ghcr.io/emuio/sub2api:ui-custom
```

同时也会推送一个按提交生成的标签，例如：

```bash
ghcr.io/emuio/sub2api:sha-abc1234
```

首次使用前，建议确认：

- GitHub 仓库的 Actions 已启用
- Packages 权限正常
- 如果镜像仓库不是公开的，服务器需要先登录 `ghcr.io`

这个 workflow 已经显式开启：

```yaml
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

这样可以提前验证 Node 24 兼容性，避免之后被 GitHub 默认切换时再暴露问题。

## 远端 Docker 服务器部署

如果你已经在服务器上跑着官方版，并且当前目录是：

```bash
~/sub2api-deploy
```

那么不要替换原来的基础 `docker-compose.yml`，只额外增加一个覆盖文件即可。

服务器上的覆盖文件可以直接写成：

```yaml
services:
  sub2api:
    image: ghcr.io/emuio/sub2api:ui-custom
    pull_policy: always
```

也可以直接复用仓库里的：

- `deploy/docker-compose.ghcr.yml`

切换命令：

```bash
cd ~/sub2api-deploy
docker compose -f docker-compose.yml -f docker-compose.ghcr.yml pull
docker compose -f docker-compose.yml -f docker-compose.ghcr.yml up -d
```

如果镜像是私有的，先登录：

```bash
echo <GHCR_PAT> | docker login ghcr.io -u <github_username> --password-stdin
```

建议 `GHCR_PAT` 至少具备：

- `read:packages`

如果你后面把包设成公开镜像，服务器通常不需要登录。

## 服务器切换脚本

如果你希望在服务器上更省事，建议把下面两个脚本放进：

```bash
~/sub2api-deploy
```

脚本文件：

- `use-custom-ui.sh`
- `use-official-ui.sh`

切到自定义 UI：

```bash
cd ~/sub2api-deploy
./use-custom-ui.sh
```

如果你想切某个特定 tag：

```bash
./use-custom-ui.sh ghcr.io/emuio/sub2api:sha-abc1234
```

回退官方镜像：

```bash
cd ~/sub2api-deploy
./use-official-ui.sh
```

行为说明：

- `use-custom-ui.sh` 会自动写入 `docker-compose.ghcr.yml`，然后拉取并启动自定义镜像
- `use-official-ui.sh` 会删除 `docker-compose.ghcr.yml`，然后按原始 `docker-compose.yml` 回退官方镜像

## 和官方同步

先确认你在 fork 仓库目录：

```bash
cd /Users/emuio/git/sub2api-emuio
```

同步官方更新：

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

把官方更新合并到你的二开分支：

```bash
git checkout ui-custom
git merge main
```

如果有冲突，通常优先检查这些目录：

- `frontend/src`
- `frontend/src/i18n`
- `deploy`

合并完成后重新构建部署：

```bash
docker compose -f deploy/docker-compose.custom.yml --env-file deploy/.env up -d --build
```

如果你走 GHCR 自动构建流，则改成：

```bash
git push origin ui-custom
cd ~/sub2api-deploy
docker compose -f docker-compose.yml -f docker-compose.ghcr.yml pull
docker compose -f docker-compose.yml -f docker-compose.ghcr.yml up -d
```

## 关于界面里的在线更新按钮

不建议在 Docker 二开环境里使用界面内的“在线更新”作为正式升级方案。

原因：

- 它更偏向“替换容器内二进制”，不是标准的 Docker 镜像升级
- 你一旦重建容器，最终仍然以你本地构建出的镜像内容为准
- 对 fork 二开场景，稳定做法是 `git 同步 + docker compose build`

## 建议的改动范围

为了减少后续同步冲突，优先把定制控制在这些位置：

- `frontend/src/views`
- `frontend/src/components`
- `frontend/src/i18n/locales/zh.ts`
- `frontend/public`

如果只是改品牌展示，通常不需要动后端逻辑。
