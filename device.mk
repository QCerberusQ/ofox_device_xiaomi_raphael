#
# Copyright (C) 2025 Team Win Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Assert
TARGET_OTA_ASSERT_DEVICE := raphael,raphaelin

# Crypto
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Emulated storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)
