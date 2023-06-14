<h1>SSPanel UIM</h1>

<br/>




## 使用

## 第一步
	git clone --depth=1 https://github.com/domparso/SSPanel-Uim-Release.git

## 第二步
	cd SSPanel-Uim-Release
	修改 docker/.env 文件

安装SSPanel的源码仓库可以选择默认的，也可以使用Anankke/SSPanel-Uim的源码仓库，请修改 docker/.env中的"REPOURL"。


初次安装，建议只修改"SSPanel配置"、"MariaDB配置"、"管理员账户"下的参数，其他保持默认。

Mariadb默认是不支持外部访问，如果需要，请将docker/docker-compose.yml的Mariadb服务 ports选项 取消注释。

	ports:
	  - '${DB_PORT}:3306'

## 第三步
	chmod +x ./install
	./install

## SSL证书
使用 acmesh-official/acme.sh 获取证书

## 测试
	因为环境问题，只测试了debian

## 使用于xrayr的解锁检测脚本
	curl -LsO https://raw.githubusercontent.com/domparso/SSPanel-Uim-Release/master/csm-xrayr.sh \
	&& chmod +x csm-xrayr.sh \
	&& ./csm-xrayr.sh