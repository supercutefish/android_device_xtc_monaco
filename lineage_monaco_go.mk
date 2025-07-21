$(call inherit-product, device/xtc/monaco_go/device.mk)

PRODUCT_DEVICE := monaco_go
PRODUCT_NAME := lineage_monaco_go
PRODUCT_MANUFACTURER := xtc
PRODUCT_BRAND := XTC

PRODUCT_GMS_CLIENTID_BASE := android-xtc

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="ND03-user 11 RKQ1.220916.001 root02020137 release-keys"

BUILD_FINGERPRINT := XTC/ND03/monaco_go:11/RKQ1.220916.001/root02020137:user/release-keys
