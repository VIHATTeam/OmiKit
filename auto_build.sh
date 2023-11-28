#!/bin/bash

# Đường dẫn đến file podspec
PODSPEC_FILE="OmiKit.podspec"

# Hàm tăng version
# increment_version() {
#     local version=$1
#     local IFS=.
#     local i ver=($version)
#     for ((i=${#ver[@]}-1; i>=0; i--)); do
#         ((ver[i]++))
#         if [ ${ver[i]} -lt 10 ]; then
#             break
#         fi
#         ver[i]=0
#     done
#     echo "${ver[*]}"
# }

# Lấy version hiện tại từ podspec
CURRENT_VERSION=$(grep -o 'version *= *"[0-9]*\.[0-9]*\.[0-9]*"' $PODSPEC_FILE | grep -o '[0-9]*\.[0-9]*\.[0-9]*')

# Tăng version
# NEW_VERSION=$(increment_version $CURRENT_VERSION)

# Cập nhật file podspec với version mới
# sed -i '' "s/$CURRENT_VERSION/$NEW_VERSION/g" $PODSPEC_FILE

# echo "Updated podspec to version $NEW_VERSION"

# Commit và push thay đổi
# git add $PODSPEC_FILE
# git commit -m "Increase version to $NEW_VERSION"
# git push origin master

# # Tạo và push tag mới
# git tag $NEW_VERSION
# git push origin $NEW_VERSION
git tag -a $CURRENT_VERSION -m "Release version $CURRENT_VERSION"
git push origin --tags 

# Build 
pod lib lint --allow-warnings --no-clean --verbose

if [ $? -eq 0 ]; then
	echo "congratulation,pod verifys success! 💐 💐 💐 💐"

	pod trunk push OmiKit.podspec

	if [ $? -eq 0 ]; then
		echo "congratulation,pod push to midea-specs success! 💐 💐 💐 💐"
	else
		echo "pod push to midea-specs fail!"
	fi
else
	echo "pod verifys fail!"
fi	