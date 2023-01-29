#!/bin/bash
GITHUB_REPO="SamarV-121/linux-xanmod"

function telegram() {
	local CURL_ARGS=()
	local TELEGRAM_CHAT
	local TELEGRAM_METHOD
	TELEGRAM_CHAT="@SamarV121_CI"
	TELEGRAM_METHOD="sendMessage"
	OPTIND=1

	while getopts "es:t:" opt; do
		case "$opt" in
		e)
			TELEGRAM_METHOD="editMessageText"
			CURL_ARGS+=(-d "message_id=$MESSAGE_ID")
			;;
		s)
			TELEGRAM_METHOD="sendSticker"
			CURL_ARGS+=(-d "sticker=$OPTARG")
			;;
		t)
			CURL_ARGS+=(-d "parse_mode=Markdown" -d "disable_web_page_preview=true" -d "text=$OPTARG")
		esac
	done

	RES=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/$TELEGRAM_METHOD" -d "chat_id=$TELEGRAM_CHAT" "${CURL_ARGS[@]}") >/dev/null
	MESSAGE_ID_TMP=$(jq '.result.message_id' <<<"$RES")
	[[ $MESSAGE_ID_TMP =~ ^[0-9]+$ ]] && MESSAGE_ID=$MESSAGE_ID_TMP
}

cd /home/xanmod_builder
git clone "https://github.com/$GITHUB_REPO"

cd "$(cut -d'/' -f2 <<<$GITHUB_REPO)"
VERSION=$(grep pkgver .SRCINFO | cut -d'=' -f2)
VERSION=v${VERSION/ /}-$(date -u +%s)

telegram -t "Compiling XanMod Kernel $VERSION: [See progress]($WORKFLOW_URL)"
BUILD_START=$(date +"%s")
env MAKEFLAGS="-s -j$(nproc)" _compiler=clang _lto=full use_numa=n use_tracers=n makepkg --skippgpcheck
BUILD_STATUS="$?"
BUILD_END=$(date +"%s")
BUILD_DIFF=$((BUILD_END - BUILD_START))
BUILD_TIME="$((BUILD_DIFF / 3600)) hour and $(($((BUILD_DIFF / 60)) % 60)) minute(s)"

if [ "$BUILD_STATUS" = 0 ]; then
	telegram -t "Build completed successfully in $BUILD_TIME"
else
	telegram -t "Build failed in $BUILD_TIME"
	exit
fi

echo "Logining in to GitHub..."
printenv GITHUB_KEY | gh auth login --with-token

echo "Releasing $VERSION binaries into $GITHUB_REPO"
RELEASE_URL=$(gh release create "$VERSION" ./*.pkg.tar.zst --repo "$GITHUB_REPO")

if [ "$RELEASE_URL" ]; then
	telegram -e -t "Build completed successfully in $BUILD_TIME
[Download]($RELEASE_URL)"
fi
telegram -s "CAADBQAD8gADLG6EE1T3chaNrvilFgQ"

echo "Loging out from Github..."
gh auth logout -h github.com
