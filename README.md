<h1>SSPanel UIM</h1>

<br/>




## 使用

## 第一步
	git clone --depth=1 https://github.com/domparso/SSPanel-Uim-Release.git

## 第二步
	cd SSPanel-Uim-Release
	修改 dicker/.env 文件


## 第三步
	chmod +x ./install
	./install

## 测试
	因为环境问题，只测试了debian

## 使用于xrayr的解锁检测脚本
	curl -LsO https://raw.githubusercontent.com/domparso/SSPanel-Uim-Release/master/csm-xrayr.sh \
	&& chmod +x csm-xrayr.sh \
	&& ./csm-xrayr.sh