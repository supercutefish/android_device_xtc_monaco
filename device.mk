$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-impl.recovery \
    android.hardware.boot@1.2-service

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

PRODUCT_SHIPPING_API_LEVEL := 30

PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

PRODUCT_ENFORCE_RRO_TARGETS := *

PRODUCT_USE_DYNAMIC_PARTITIONS := true

PRODUCT_CHARACTERISTICS := nosdcard

PRODUCT_PACKAGES += \
    init.class_main.sh \
    init.crda.sh \
    init.kernel.post_boot.sh \
    init.mdm.sh \
    init.qcom.class_core.sh \
    init.qcom.coex.sh \
    init.qcom.early_boot.sh \
    init.qcom.efs.sync.sh \
    init.qcom.post_boot.sh \
    init.qcom.sdio.sh \
    init.qcom.sensors.sh \
    init.qcom.sh \
    init.qcom.usb.sh \
    init.qti.can.sh \
    init.qti.chg_policy.sh \
    init.qti.display_boot.sh \
    init.qti.kernel.debug.sh \
    init.qti.kernel.sh \
    init.qti.media.sh \
    init.qti.qcv.sh \
    qca6234-service.sh \
    vendor_modprobe.sh \

PRODUCT_PACKAGES += \
    fstab.qcom \
    init.qcom.factory.rc \
    init.qcom.rc \
    init.qcom.usb.rc \
    init.qti.kernel.rc \
    init.target.rc \
    init.recovery.qcom.rc \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_VENDOR_RAMDISK_OUT)/first_stage_ramdisk/fstab.qcom

PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

$(call inherit-product, vendor/xtc/monaco_go/monaco_go-vendor.mk)
