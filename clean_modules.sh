#!/bin/bash

BOOT_DIR="/boot/ba558252c86442578a6b804878f96474"
LOADER_ENTRIES_DIR="/boot/loader/entries"
MODULES_DIR="/usr/lib/modules"
BOOT_ENTRY_PREFIX="$(basename "$BOOT_DIR")"

# Get the running kernel version
RUNNING_KERNEL=$(uname -r)
LATEST_INSTALLED_KERNEL=$(ls "$MODULES_DIR" | sort -V | tail -n 1)

echo "Running kernel: $RUNNING_KERNEL"
echo "Newest installed kernel modules: $LATEST_INSTALLED_KERNEL"
echo "Checking for orphaned kernel modules in $MODULES_DIR..."

# List all kernel versions that still have boot artifacts.
cd "$BOOT_DIR" || exit 1
BOOT_KERNELS=$(find . -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort -V)

# List all kernel versions in /usr/lib/modules/
MODULE_KERNELS=$(ls "$MODULES_DIR" | sort -u)

# For each module directory, check if it exists in /boot
for module_kernel in $MODULE_KERNELS; do
    if [[ "$module_kernel" == "$RUNNING_KERNEL" ]]; then
        echo "Skipping running kernel module: $module_kernel"
        continue
    fi

    if [[ "$module_kernel" == "$LATEST_INSTALLED_KERNEL" ]]; then
        echo "Skipping newest installed kernel module: $module_kernel"
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

echo "Checking for unused loader entries in $LOADER_ENTRIES_DIR..."

if [ -d "$LOADER_ENTRIES_DIR" ]; then
    for loader_entry in "$LOADER_ENTRIES_DIR"/*.conf; do
        if [ ! -e "$loader_entry" ]; then
            break
        fi

        entry_name=$(basename "$loader_entry")
        entry_kernel=${entry_name#${BOOT_ENTRY_PREFIX}-}
        entry_kernel=${entry_kernel%.conf}

        if [[ "$entry_kernel" == "$RUNNING_KERNEL" ]]; then
            echo "Keeping loader entry for running kernel: $entry_name"
            continue
        fi

        if [[ "$entry_kernel" == "$LATEST_INSTALLED_KERNEL" ]]; then
            echo "Keeping loader entry for newest installed kernel: $entry_name"
            continue
        fi

        if echo "$BOOT_KERNELS" | grep -q "^${entry_kernel}$" && echo "$MODULE_KERNELS" | grep -q "^${entry_kernel}$"; then
            echo "Loader entry $entry_name is still in use. Skipping."
            continue
        fi

        echo "Unused loader entry found: $entry_name"
        echo "Deleting $loader_entry..."
        sudo rm -v "$loader_entry"
    done
fi

echo "Orphaned module cleanup complete."
