#!/bin/bash

if [ "$1" ]; then
 value="$1"
fi

if [ -n "$value" ] && [ "$value" != "prepare" ] && [ "$value" != "continue" ]; then
 echo "Usage: $0 [prepare|continue]"
 exit 1
fi

running_kernel=$(uname -r)
latest_kernel=$(curl -s "https://www.kernel.org/finger_banner" | grep "The latest stable version" | xargs | cut -d ':' -f 2 | xargs)
echo "$latest_kernel"
dots=$(echo "$latest_kernel" | grep -o '\.' | wc -l)
original_kernel="$latest_kernel"
kernel_base_dir="$HOME/src/kernel"
boot_dir="/boot/ba558252c86442578a6b804878f96474"
if [ "$dots" -eq 1 ]; then
  latest_kernel="$latest_kernel.0"
fi
kernel_src_dir="$kernel_base_dir/linux-$original_kernel"

if [ "$running_kernel" == "$latest_kernel" ]; then
 echo "No updates"
 if [ "$value" == "prepare" ]; then
  echo "but you want me to prepare to kernel, so here we go...."
  rm -rf "$kernel_src_dir"
 elif [ "$value" != "continue" ]; then
  exit
 fi
fi

if [ "$value" == "continue" ]; then
 if [ ! -d "$kernel_src_dir" ]; then
  echo "Prepared kernel source tree $kernel_src_dir does not exist. Run $0 prepare first."
  exit 1
 fi
 echo "Continuing kernel build from prepared tree $kernel_src_dir"
elif [ -d "$kernel_src_dir" ]; then
 echo "Running older kernel but new kernel was already built. exit"
 echo "If you already prepared the tree and only want to build/install, run: $0 continue"
 exit
fi

if [ "$value" != "continue" ]; then
 echo "Update needed and directory $kernel_src_dir does not exist. Adventure Time!"
 if [ "$value" == "prepare" ]; then
  echo "I will only prepare until config file and then stop"
 fi
fi

cores=$(nproc)
cores_to_use=$((cores-2))
majorrelease="v${latest_kernel:0:1}.x"
if [ "$cores_to_use" -lt 1 ]; then
 cores_to_use=1
fi
echo "Have $cores cores, will use $cores_to_use"
echo "Waiting 5 secs before start update..."
sleep 5s

if [ "$value" != "continue" ]; then
 kerneldownload="https://cdn.kernel.org/pub/linux/kernel/$majorrelease/linux-$original_kernel.tar.xz"
 mkdir -p "$kernel_base_dir"
 cd "$kernel_base_dir"
 curl -O "$kerneldownload"
 tar -xvJf "linux-$original_kernel.tar.xz"
 cd "$kernel_src_dir"
 cp /proc/config.gz .
 gzip -d config.gz
 mv config .config
 if [ "$value" == "prepare" ]; then
  echo "Exit here as wished"
  exit
 fi
fi

cd "$kernel_src_dir"
echo "Kernel Download and setup completed. Start building kernel"
make olddefconfig
make localmodconfig
make -j "$cores_to_use"
#ls -A1t /boot/*initramfs* | tail -n +3 | xargs sudo rm
#ls -A1t /boot/*vmlinuz* | tail -n +3 | xargs sudo rm
find "$boot_dir" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort -V -r | tail -n +3 | while read -r old_boot_kernel; do
 if [ -n "$old_boot_kernel" ]; then
  sudo rm -rf "$boot_dir/$old_boot_kernel"
 fi
done
sudo make modules_install
sudo make install
echo "Kernel installation completed."
sudo /etc/kernel/postinst.d/zz_gaunerstuff
echo "Cleanup..."
cd "$kernel_base_dir"
sudo rm -R ./*
mkdir -p "$kernel_src_dir"
/usr/local/bin/linux-kernel-updater/clean_modules.sh
echo "Update completed. Reboot when you have time...."

