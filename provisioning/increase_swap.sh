#!/bin/sh

# size of swapfile in megabytes
swapsize=2000

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
  echo 'swapfile not found. Adding swapfile.'
  
  # https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-centos-7
  dd if=/dev/zero of=/swapfile count=${swapsize} bs=1MiB
  #fallocate -l ${swapsize}M /swapfile

  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
  echo 'swapfile found. No changes made.'
fi

# output results to terminal
df -h
cat /proc/swaps
cat /proc/meminfo | grep Swap