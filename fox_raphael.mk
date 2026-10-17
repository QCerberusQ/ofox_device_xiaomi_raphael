#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2021-2025 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

# OrangeFox-specific settings
OF_USE_GREEN_LED := 0
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_NO_MIUI_PATCH_WARNING := 1

# Dinamik bölümler (Retrofit) için gerekli araçlar
OF_ENABLE_ALL_PARTITION_TOOLS := 1
OF_USE_DMCTL := 1

# Hızlı yedekleme listesi
OF_QUICK_BACKUP_LIST := /boot;/data;

# Patch AVB 2.0
OF_PATCH_AVB20 := 1

# OTA Ayarları
OF_SUPPORT_ALL_BLOCK_OTA_UPDATES := 1
OF_FIX_OTA_UPDATE_MANUAL_FLASH_ERROR := 1
OF_DISABLE_MIUI_OTA_BY_DEFAULT := 1

# Format ve Metadata Ayarları
OF_UNBIND_SDCARD_F2FS := 1
OF_WIPE_METADATA_AFTER_DATAFORMAT := 1
OF_FBE_METADATA_MOUNT_IGNORE := 1

# Frp Addon
OF_ENABLE_FRP_ADDON := 1

# Ekran ve Arayüz Optimizasyonları
OF_SCREEN_H := 2340
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
