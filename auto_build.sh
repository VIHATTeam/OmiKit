#!/bin/bash

# Đường dẫn đến file podspec
PODSPEC_FILE="OmiKit.podspec"

# Hàm tăng version
increment_version() {
    local version=$1
    local IFS=.
    local i ver=($version)
    for ((i=${#ver[@]}-1; i>=0; i--)); do
        ((ver[i]++))
        if [ ${ver[i]} -lt 10 ]; then
            break
        fi
        ver[i]=0
    done
    echo "${ver[*]}"
}

# Lấy version hiện tại từ podspec
CURRENT_VERSION=$(grep -o 'version *= *"[0-9]*\.[0-9]*\.[0-9]*"' $PODSPEC_FILE | grep -o '[0-9]*\.[0-9]*\.[0-9]*')

# Tăng version
NEW_VERSION=$(increment_version $CURRENT_VERSION)

# Cập nhật file podspec với version mới
sed -i '' "s/$CURRENT_VERSION/$NEW_VERSION/g" $PODSPEC_FILE

# echo "Updated podspec to version $NEW_VERSION"

# Commit và push thay đổi
# git add $PODSPEC_FILE
# git commit -m "Increase version to $NEW_VERSION"
# git push origin master

# # Tạo và push tag mới
# git tag $NEW_VERSION
# git push origin $NEW_VERSION
sh push_tag.sh $NEW_VERSION
