#!/usr/bin/env bash

# AlexandriteOS recovery mode grub entry generator v1.00
# 
# (c) 2022 Project Alexandrite , nexryai
#
# リカバリーモードのGRUBエントリーを生成
#
#
# GOD_BLESS_UKRAINE
#

tmpfile=`mktemp`
line_counts=0
target_file=/etc/grub.d/39_recovery

# rm /etc/grub.d/39_recovery
touch ${target_file}

# ノーマルブートの構成ファイルを取得
cat /boot/grub2/grub.cfg | grep -A 100 "### BEGIN /etc/grub.d/10_linux ###" >> ${tmpfile}

while read line
do
  line_counts=$(( line_counts + 1 ))
  if [ "$line" = "}" ]; then
    cat ${tmpfile} | head -n ${line_counts} > ${target_file}
    break
  fi
done < ${tmpfile}

sed -i '1d' ${target_file}

# レスキューモードで起動するオプションを追記
sed -i '/\/boot\/vmlinuz/s/$/ systemd.unit=rescue.target/' ${target_file}

# vmlinuzとinitrdのバージョンを指定しないで起動するようにする
kernel_path_line=`grep -e "/boot/vmlinuz" -n ${target_file} | sed -e 's/:.*//g'`
initrd_path_line=`grep -e "/boot/initrd" -n ${target_file} | sed -e 's/:.*//g'`

vmlinuz_path=`sed -n ${kernel_path_line}P ${target_file} | awk '{print $2}'`
initrd_path=`sed -n ${initrd_path_line}P ${target_file} | awk '{print $2}'`

if [[ "${vmlinuz_path}" =~ "@" ]]; then
  sed -i -e ${kernel_path_line}s:${vmlinuz_path}:/@/boot/vmlinuz:g ${target_file}
  sed -i -e ${initrd_path_line}s:${initrd_path}:/@/boot/initrd:g ${target_file}
else
  sed -i -e ${kernel_path_line}s:${vmlinuz_path}:/boot/vmlinuz:g ${target_file}
  sed -i -e ${initrd_path_line}s:${initrd_path}:/boot/initrd:g ${target_file}
fi



# 最終調整
sed -i '1d' ${target_file}
sed -i -e "1i menuentry \"Recovery mode\"{" ${target_file}
sed -i -e "1i exec tail -n +3 \$0" ${target_file}
sed -i -e "1i #!/bin/sh" ${target_file}

rm ${tmpfile}
chmod +x /etc/grub.d/39_recovery
