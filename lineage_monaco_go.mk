$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/xtc/monaco_go/device.mk)

PRODUCT_DEVICE := monaco_go
PRODUCT_NAME := lineage_monaco_go
PRODUCT_MANUFACTURER := xtc

PRODUCT_GMS_CLIENTID_BASE := android-xtc

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="ND03-user 11 RKQ1.220916.001 root02020137 release-keys"

BUILD_FINGERPRINT := XTC/ND03/monaco_go:11/RKQ1.220916.001/root02020137:user/release-keys
