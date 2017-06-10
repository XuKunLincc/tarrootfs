
#	2017.06.08
#	v.01
#	by xkl
#   进行文件系统打包
#	执行步骤：
#		1，遍历配置	暂未实现
#		2，选择配置	暂未实现
#		3，按照顺序进行打包


WORKSPEC=$PWD			#工作空间
OUTDIR=$WORKSPEC/out		#输出目录
TARGET=$OUTDIR/rootfs.tar	#目标文件
dirconfig=filesdir.cfg		#配置文件存放文件的配置文件
config_file=config		#版本配置信息
tmp=tmp				#缓存目录名
codesys_ver=emula		#codesys版本选择
application_ver=V1.5		#application版本选择

codesys_dep=(codesys/real)	#codesys依赖关系
application_dep=		#application依赖关系



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
			mkdir -p ${WORKSPEC}/${tmp}/${line:4} >& /dev/null; cp -R $SRC ${WORKSPEC}/$tmp/${line:4}
		fi
	done < $dirconfig
}

copyfiles () {
	echo 
	if [ -f $dirconfig ]
	then
		copyfiles_by_cfg
	else
		mkdir ${WORKSPEC}/$tmp >& /dev/null
		cp -R * ${WORKSPEC}/$tmp
	fi
}


tarall () {
	echo 正在打包文件系统....
	for SOURCE in ${SOURCES[*]}
	do
		echo 正在进入目录${SOURCE}....
		cd ${WORKSPEC}/${SOURCE}
		copyfiles
	done

	mkdir -p $OUTDIR
	cd ${WORKSPEC}/$tmp
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
	rm -rf ${WORKSPEC}/$tmp
	rm $TARGET	
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

#######扫描并配置文件###########
:<<!
echo 扫描配置文件
CONFIGS=			#保存所有配置
flag=0
read_config(){
	while read line
	do
		key=`echo $line | grep -P -o "^.*(?=:)" ` 
		if [ $key = 'CONFIG' ]
			
	done < $config_file
}
search_config(){
	for file in `ls $1`
	do
	if [ -d $file ]
	then
		cd $file
		search_config $PWD
		cd ..
	elif [ -f $config_file ]
	then	
		read_config
		return
	fi
	done
}

search_config ${WORKSPEC}

########选择配置################
echo 选择配置文件

select_config(){
	print_configs		#打印所有配置
	select_from_input	# 选择配置
}
!
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
