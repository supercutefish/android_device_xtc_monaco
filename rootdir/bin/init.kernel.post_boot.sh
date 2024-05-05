#=============================================================================
# Copyright (c) 2021 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2012-2013, 2016-2020, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

function configure_zram_parameters() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	# Zram disk - 75% for < 2GB devices .
	# For >2GB devices, size = 50% of RAM size. Limit the size to 4GB.

	let RamSizeGB="( $MemTotal / 1048576 ) + 1"
	let zRamSizeMB="( $RamSizeGB * 1024 ) * 3 / 4"
	diskSizeUnit=M

	# use MB avoid 32 bit overflow
	if [ $zRamSizeMB -gt 4096 ]; then
		let zRamSizeMB=4096
	fi

	echo lz4 > /sys/block/zram0/comp_algorithm

	if [ -f /sys/block/zram0/disksize ]; then
		if [ -f /sys/block/zram0/use_dedup ]; then
			echo 1 > /sys/block/zram0/use_dedup
		fi
		echo "$zRamSizeMB""$diskSizeUnit" > /sys/block/zram0/disksize

		# ZRAM may use more memory than it saves if SLAB_STORE_USER
		# debug option is enabled.
		if [ -e /sys/kernel/slab/zs_handle ]; then
			echo 0 > /sys/kernel/slab/zs_handle/store_user
		fi
		if [ -e /sys/kernel/slab/zspage ]; then
			echo 0 > /sys/kernel/slab/zspage/store_user
		fi

		mkswap /dev/block/zram0
		swapon /dev/block/zram0 -p 32758
	fi
}

function configure_read_ahead_kb_values() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc)

	# Set 128 for <= 3GB
	ra_kb=128
	if [ -f /sys/block/mmcblk0/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0/bdi/read_ahead_kb
	fi
	if [ -f /sys/block/mmcblk0rpmb/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
	fi
	for dm in $dmpts; do
		echo $ra_kb > $dm
	done
}

function configure_memory_parameters() {
	# Set Memory parameters.

	# Set swappiness to 100 for all targets
	echo 100 > /proc/sys/vm/swappiness

	# Disable wsf for all targets beacause we are using efk.
	# wsf Range : 1..1000 So set to bare minimum value 1.
	echo 1 > /proc/sys/vm/watermark_scale_factor
	echo 1 > /proc/sys/vm/reap_mem_on_sigkill
	echo 100 > /proc/sys/vm/watermark_boost_factor

	configure_zram_parameters

	configure_read_ahead_kb_values
}

# disable unfiltering
echo 20000000 > /proc/sys/kernel/sched_task_unfilter_period

# cpuset parameters
echo 0-3 > /dev/cpuset/background/cpus
echo 0-3 > /dev/cpuset/system-background/cpus

# Turn off scheduler boost at the end
echo 0 > /proc/sys/kernel/sched_boost

# TO DO:
# Needs review
# configure input boost settings
#echo "0:1190400" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
#echo 120 > /sys/devices/system/cpu/cpu_boost/input_boost_ms

# Enable bus-dcvs
for device in /sys/devices/platform/soc
do
	for cpubw in $device/*cpu-cpu-ddr-bw/devfreq/*cpu-cpu-ddr-bw
	do
		cat $cpubw/available_frequencies | cut -d " " -f 1 > $cpubw/min_freq
		echo "bw_hwmon" > $cpubw/governor
		echo 4 > $cpubw/bw_hwmon/sample_ms
		echo 68 > $cpubw/bw_hwmon/io_percent
		echo 20 > $cpubw/bw_hwmon/hist_memory
		echo 0 > $cpubw/bw_hwmon/hyst_length
		echo 80 > $cpubw/bw_hwmon/down_thres
		echo 30 > $cpubw/bw_hwmon/guard_band_mbps
	done

	# configure compute settings for silver latfloor
	for latfloor in $device/*cpu0-cpu*latfloor/devfreq/*cpu0-cpu*latfloor
	do
		cat $latfloor/available_frequencies | cut -d " " -f 1 > $latfloor/min_freq
		echo 10 > $latfloor/polling_interval
	done

	# TO DO:
	# Needs review
	# configure mem_latency settings for DDR scaling
	#for memlat in $device/*lat/devfreq/*lat
	#do
	#	cat $memlat/available_frequencies | cut -d " " -f 1 > $memlat/min_freq
	#	echo 8 > $memlat/polling_interval
	#	echo 400 > $memlat/mem_latency/ratio_ceil
	#done
done

for gpu_bimc_io_percent in /sys/class/devfreq/soc:qcom,gpubw/bw_hwmon/io_percent
do
	echo 40 > $gpu_bimc_io_percent
done

# Scheduler configuration
echo 1 > /proc/sys/kernel/sched_prefer_spread

# Schedutil parameters
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
echo 1363200 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
echo 864000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 85 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_load
echo -10 > /sys/devices/system/cpu/cpu0/sched_load_boost
echo -10 > /sys/devices/system/cpu/cpu1/sched_load_boost
echo -10 > /sys/devices/system/cpu/cpu2/sched_load_boost
echo -10 > /sys/devices/system/cpu/cpu3/sched_load_boost

# enable core control
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
echo 0 1 1 1 > /sys/devices/system/cpu/cpu0/core_ctl/not_preferred
echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
echo 4 > /sys/devices/system/cpu/cpu0/core_ctl/max_cpus
echo 68 68 50 50 > /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
echo 20 > /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/enable

# enable lpm modes
echo N > /sys/module/lpm_levels/parameters/sleep_disabled

# Bring up all cores online
echo 1 > /sys/devices/system/cpu/cpu1/online
echo 1 > /sys/devices/system/cpu/cpu2/online
echo 1 > /sys/devices/system/cpu/cpu3/online

configure_memory_parameters

# Enable s2idle for  memsleep
echo s2idle > /sys/power/mem_sleep

setprop vendor.post_boot.parsed 1
