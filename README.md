# v2ray 配置脚本

用于在openwrt上运行

依赖`bash` `jq` `wget`

文件:
* base.json - 内容会被合并到最终结果里
* URL.txt - 运行update.sh从此处更新
* lib/create-local-dns-config.sh - 端口转发列表
