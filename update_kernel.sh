#!/bin/bash
running_kernel=$(uname -r)
latest_kernel=$(curl -s "https://www.kernel.org/finger_banner" | grep "The latest stable version" | xargs | cut -d ':' -f 2 | xargs)
dots=$(echo "$latest_kernel" | grep -o '\.' | wc -l)
if [ "$dots" -eq 1 ]; then
  latest_kernel="$latest_kernel.0"
fi
if [ "$running_kernel" == "$latest_kernel" ]; then
 echo "No updates"
else
 if [ -d ~/src/kernel/linux-$latest_kernel ]; then
  echo "Running older kernel but new kernel was already built. exit"
  exit
 fi
 echo "Update needed and directory ~/src/kernel/linux-$latest_kernel does not exist. Adventure Time!"
 cores=$(nproc)
 cores_to_use=$((cores-2))
 majorrelease="v${latest_kernel:0:1}.x"
 echo "Have $cores cores, will use $cores_to_use"
 echo "Waiting 5 secs before start update..."
 sleep 5s
 kerneldownload="https://cdn.kernel.org/pub/linux/kernel/$majorrelease/linux-$latest_kernel.tar.xz"
 mkdir -p ~/src/kernel/
 cd ~/src/kernel/
 wget "$kerneldownload"
 tar -xvJf "linux-$latest_kernel.tar.xz"
 cd "linux-$latest_kernel"
 cp /proc/config.gz .
 gzip -d config.gz
 mv config .config
 echo "Kernel Download and setup completed. Start building kernel" 
 make olddefconfig
 make localmodconfig
 make -j "$cores_to_use"
 ls -A1t /boot/*initramfs* | tail -n +3 | xargs rm
 ls -A1t /boot/*vmlinuz* | tail -n +3 | xargs rm
 ls -A1t /boot/loader/entries/*conf | tail -n +3 | xargs rm
 sudo make modules_install
 sudo make install
 echo "Kernel installation completed." 
 sudo /etc/kernel/postinst.d/zz_gaunerstuff
 echo "Cleanup..."
 cd ~/src/kernel/
 sudo rm -R ./*
 mkdir -p ~/src/kernel/linux-$latest_kernel
 echo "Update completed. Reboot when you have time...."
fi
