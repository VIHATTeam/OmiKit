#!/bin/bash

# Đường dẫn đến file podspec
PODSPEC_FILE="OmiKit.podspec"

# Lấy version hiện tại từ podspec
CURRENT_VERSION=$(grep -o 'version = "[0-9]*\.[0-9]*\.[0-9]*"' $PODSPEC_FILE | grep -o '[0-9]*\.[0-9]*\.[0-9]*')

# Tách version thành các thành phần
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"

# Tăng patch version (phần tử thứ 3)
((VERSION_PARTS[2]++))

# Tạo version mới
NEW_VERSION="${VERSION_PARTS[0]}.${VERSION_PARTS[1]}.${VERSION_PARTS[2]}"

# Cập nhật file podspec với version mới
sed -i '' "s/$CURRENT_VERSION/$NEW_VERSION/g" $PODSPEC_FILE

# Commit và push thay đổi
git add $PODSPEC_FILE
git commit -m "Increase version to $NEW_VERSION"
git push origin master

# Tạo và push tag mới
git tag $NEW_VERSION
git push origin $NEW_VERSION
