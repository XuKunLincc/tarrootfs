#!/bin/bash
#	2017.06.08
#	v.1.0
#	by xkl
#   进行文件系统打包
#	执行步骤：
#		1，遍历配置	暂未实现
#		2，选择配置	暂未实现
#		3，按照顺序进行打包
#
#    注意： 创建每个新的事务，首要任务就算要进入其相应的工作空间


WORKSPEC=$PWD			#工作空间
SOURCESPEC=$PWD			#源空间
OUTDIR=$WORKSPEC/out		#输出目录		相对于工作空间
TARGET=$OUTDIR/rootfs.tar	#目标文件		相对与输出目录
dirconfig=filesdir.cfg		#配置文件存放文件的配置文件
config_file=config		#版本配置信息
tmp=tmp				#缓存目录名

rootfs_name=rootfs		#解压根文件目录
rootfszip_name=rootfs.tar.bz2	#根文件压缩包名称
codesys_ver=emula		#codesys版本选择
application_ver=V1.5		#application版本选择

codesys_dep=(codesys/real)			#codesys依赖关系 	相对路径
application_dep=(application/configure)		#application依赖关系	相对路径



codesys=(${codesys_dep[*]} codesys/${codesys_ver})
application=(${application_dep[*]} application/${application_ver})

##### 通过修改该变量实现的动态打包
SOURCES=(rootfs ${codesys[*]} ${application[*]})

# 解析配置文件并进行将其拷贝到缓存文件夹
copyfiles_by_cfg () {
	echo 根据${dirconfig}配置进行打包
	while read line
	do
		if [ ${line:0:4} = 'src:' ]
		then
			SRC=${line:4}
		elif [ ${line:0:4} = 'des:' ]
		then
			mkdir -p ${WORKSPEC}/${tmp}/${line:4} >& /dev/null; cp -R $SRC ${WORKSPEC}/$tmp/${line:4} >& /dev/null
		fi
	done < $dirconfig
}

copyfiles () {
	if [ -f $dirconfig ]
	then
		copyfiles_by_cfg
	else
		mkdir ${WORKSPEC}/$tmp >& /dev/null
		cp -R * ${WORKSPEC}/$tmp >& /dev/null
	fi
}


tarall () {

	cd $SOURCESPEC				#切换到源工作目录

	if [ -d $rootfs_name ]
	then
		echo 根文件系统已解压
	else
		if [ -f $rootfszip_name ]
		then
			echo 正在解压根文件系统
			tar xjf $rootfszip_name $rootfs_name
			echo 根文件系统解压完成
		else
			echo 根文件系统压缩包不存在
			exit
		fi	
	fi

	echo 正在打包文件系统....
	for SOURCE in ${SOURCES[*]}
	do
		echo 进入目录：${SOURCE}
		cd $SOURCESPEC/${SOURCE}
		copyfiles
	done

	cd ${WORKSPEC}/$tmp
	mkdir -p $OUTDIR
	echo "rootfs_ver:1.0" > etc/rootfsver
	echo "codesys_ver:${codesys_ver}" >> etc/rootfsver
	echo "application_ver:${application_ver}" >> etc/rootfsver
	tar cf $TARGET *

	echo 文件系统打包完成
	echo 输出文件： $TARGET
}

### 清除缓存
clean_tmp(){
	echo 清理缓存文件.....
	cd ${WORKSPEC}			#进入工作目录
	rm -rf $tmp
	rm -rf $TARGET
	rm -rf ${SOURCESPEC}/$rootfs_name
	cd - >& /dev/null
	echo 缓存清理完成
}

### 通过cmd执行事务
start_transaction(){
	echo 执行事务 $cmd
	if [ $cmd = 'clean' ]
	then
		clean_tmp
	elif [ $cmd = 'tarall' ]
	then
		tarall
	fi
}


#######程序入口###########

######解析命令并执行############

cmds=$*
if [ -z $cmds ]
then
	echo nothing to do 
fi

for cmd in ${cmds[*]}
do
	if [ ${cmd:0:1} = '-' ]
	then
		echo 配置参数
	else
		start_transaction	#执行事务
	fi
done
