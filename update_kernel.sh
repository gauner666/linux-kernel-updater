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
 kerneldownload="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$latest_kernel.tar.xz"
 mkdir -p ~/src/kernel/
 cd ~/src/kernel/
 wget "$kerneldownload"
 tar -xvJf "linux-$latest_kernel.tar.xz"
 cd "linux-$latest_kernel"
 cp /proc/config.gz .
 gzip -d config.gz
 mv config .config
 echo "Kernel Download and setup completed. Start building kernel" 
 make -j$(( $(nproc) - 2 )) localmodconfig
 sudo make modules_install
 sudo make install
 echo "Kernel installation completed." 
 sudo /etc/kernel/postinst.d/zz_gaunerstuff
 echo "Update completed. Reboot when you have time...."
fi