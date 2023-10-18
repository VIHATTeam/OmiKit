current_version=$(grep -o 's.version *= *"[0-9.]*"' YourLibrary.podspec | grep -o '[0-9.]*')
git tag $current_version
git push origin $current_version
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