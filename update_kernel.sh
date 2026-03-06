#!/bin/bash

if [ "$1" ]; then
 value="$1"
fi

running_kernel=$(uname -r)
latest_kernel=$(curl -s "https://www.kernel.org/finger_banner" | grep "The latest stable version" | xargs | cut -d ':' -f 2 | xargs)
echo "$latest_kernel"
dots=$(echo "$latest_kernel" | grep -o '\.' | wc -l)
original_kernel="$latest_kernel"
if [ "$dots" -eq 1 ]; then
  latest_kernel="$latest_kernel.0"
fi
if [ "$running_kernel" == "$latest_kernel" ]; then
 echo "No updates"
 if [ "$value" == "prepare" ]; then
  echo "but you want me to prepare to kernel, so here we go...."
  rm -R ~/src/kernel/linux-$original_kernel
 else
  exit
 fi
fi
if [ -d ~/src/kernel/linux-$original_kernel ]; then
 echo "Running older kernel but new kernel was already built. exit"
 exit
fi
echo "Update needed and directory ~/src/kernel/linux-$original_kernel does not exist. Adventure Time!"
if [ "$value" == "prepare" ]; then
 echo "I will only prepare until config file and then stop"
fi
cores=$(nproc)
cores_to_use=$((cores-2))
majorrelease="v${latest_kernel:0:1}.x"
echo "Have $cores cores, will use $cores_to_use"
echo "Waiting 5 secs before start update..."
sleep 5s
kerneldownload="https://cdn.kernel.org/pub/linux/kernel/$majorrelease/linux-$original_kernel.tar.xz"
mkdir -p ~/src/kernel/
cd ~/src/kernel/
curl -O "$kerneldownload"
tar -xvJf "linux-$original_kernel.tar.xz"
cd "linux-$original_kernel"
cp /proc/config.gz .
gzip -d config.gz
mv config .config
if [ "$value" == "prepare" ]; then
 echo "Exit here as wished"
 exit
fi
echo "Kernel Download and setup completed. Start building kernel" 
make olddefconfig
make localmodconfig
make -j "$cores_to_use"
#ls -A1t /boot/*initramfs* | tail -n +3 | xargs sudo rm
#ls -A1t /boot/*vmlinuz* | tail -n +3 | xargs sudo rm
find /boot/ba558252c86442578a6b804878f96474 -maxdepth 1 -mindepth 1 | sort -r | tail -n +3 | xargs sudo rm -rf
sudo make modules_install
sudo make install
echo "Kernel installation completed." 
sudo /etc/kernel/postinst.d/zz_gaunerstuff
echo "Cleanup..."
cd ~/src/kernel/
sudo rm -R ./*
mkdir -p ~/src/kernel/linux-$original_kernel
echo "Update completed. Reboot when you have time...."

