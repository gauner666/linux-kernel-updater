#!/bin/bash

BOOT_DIR="/boot/ba558252c86442578a6b804878f96474"
MODULES_DIR="/usr/lib/modules"

# Get the running kernel version
RUNNING_KERNEL=$(uname -r)

echo "Running kernel: $RUNNING_KERNEL"
echo "Checking for orphaned kernel modules in $MODULES_DIR..."

# List all kernel versions in /boot/ba558252c86442578a6b804878f96474/
cd "$BOOT_DIR" || exit 1
BOOT_KERNELS=$(ls | grep -E 'vmlinuz-' | sed -E 's/vmlinuz-//g' | sort -u)

# List all kernel versions in /usr/lib/modules/
MODULE_KERNELS=$(ls "$MODULES_DIR" | sort -u)

# For each module directory, check if it exists in /boot
for module_kernel in $MODULE_KERNELS; do
    if [[ "$module_kernel" == "$RUNNING_KERNEL" ]]; then
        echo "Skipping running kernel module: $module_kernel"
        continue
    fi

    if ! echo "$BOOT_KERNELS" | grep -q "^${module_kernel}$"; then
        echo "Orphaned module found: $module_kernel"
        echo "Deleting $MODULES_DIR/$module_kernel..."
        sudo rm -rv "$MODULES_DIR/$module_kernel"
    else
        echo "Module $module_kernel is still in use. Skipping."
    fi
done

echo "Orphaned module cleanup complete."
