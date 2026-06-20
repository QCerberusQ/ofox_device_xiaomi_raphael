#
# Copyright (C) 2025 Team Win Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Define hardware platform
PRODUCT_PLATFORM := msmnile

# API
PRODUCT_SHIPPING_API_LEVEL := 28

# Assert
TARGET_OTA_ASSERT_DEVICE := raphael,raphaelin

# Crypto
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Fastbootd (Mock implementation for recovery)
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock

# Additional binaries & libraries needed for recovery
TARGET_RECOVERY_DEVICE_MODULES += \
    libion \
    libxml2 \
    vendor.display.config@1.0 \
    vendor.display.config@2.0 \
    libdisplayconfig.qti

TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libxml2.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/vendor.display.config@1.0.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/vendor.display.config@2.0.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/libdisplayconfig.qti.so

# Overrides
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=$(PRODUCT_RELEASE_NAME) \
    TARGET_DEVICE=$(PRODUCT_RELEASE_NAME)

PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.device=$(PRODUCT_RELEASE_NAME)

# Emulated storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)
