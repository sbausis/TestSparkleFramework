#!/bin/sh

#  ProductPackaging.sh
#  Test
#
#  Created by Simon Pascal Baur on 21/10/14.
#  Copyright (c) 2014 Simon Pascal Baur. All rights reserved.

#set -e
set -x

####################

if [ "_${CONFIGURATION}" != "_Release" ]; then
	exit 0
fi

INFO_PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
echo -e "INFO_PLIST : ${INFO_PLIST}"
[ -z "${INFO_PLIST}" ] && exit 1

INFO_DOMAIN="${INFO_PLIST%/Info.plist}/Info"
echo -e "INFO_DOMAIN : ${INFO_DOMAIN}"
[ -z "${INFO_DOMAIN}" ] && exit 1

PRODUCT="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
echo -e "PRODUCT : ${PRODUCT}"
[ -z "${PRODUCT}" ] && exit 1

CFBundleVersion=`defaults read "${INFO_DOMAIN}" CFBundleVersion`
echo -e "CFBundleVersion : ${CFBundleVersion}"
[ -z "${CFBundleVersion}" ] && exit 1

CFBundleShortVersionString=`defaults read "${INFO_DOMAIN}" CFBundleShortVersionString`
echo -e "CFBundleShortVersionString : ${CFBundleShortVersionString}"
[ -z "${CFBundleShortVersionString}" ] && exit 1

if [ -n "${CFBundleVersion}" ]; then
	ARCHIVE="${PRODUCT%.*}_v${CFBundleVersion}.tar.gz"
else
	ARCHIVE="${PRODUCT%.*}.tar.gz"
fi
echo -e "ARCHIVE : ${ARCHIVE}"
[ -z "${ARCHIVE}" ] && exit 1

if [ -f "${SOURCE_ROOT}/.sparkle" ]; then
	
	cd "${SOURCE_ROOT}"
    git add .sparkle
  
    if [ ! -d "${SOURCE_ROOT}/Sparkle/bin" ]; then
		
		cd "${SOURCE_ROOT}"
		SPARKLE_MODULE=`cat .gitmodules | grep Sparkle`
		SPARKLE_STATUS=`git submodule status | grep Sparkle`
		if [ -z "${SPARKLE_MODULE}" ]; then
			git submodule add -b master https://github.com/sbausis/Sparkle.git
		else
			if [ "_${SPARKLE_STATUS:1:1}" == "_-" ]; then
				git submodules init Sparkle
				git submodules update Sparkle
			else
				echo -e "ERROR - ${SUPrivateDSAKeyFile}"
				exit 1
			fi
		fi
		
	fi
	
	SUPublicDSAKeyFile=`defaults read "${INFO_DOMAIN}" SUPublicDSAKeyFile`
	echo -e "SUPublicDSAKeyFile : ${SUPublicDSAKeyFile}"

	if [ -n "$SUPublicDSAKeyFile" ]; then
		SUPrivateDSAKeyFile="${SUPublicDSAKeyFile%*pub.pem}"
		if [ "${SUPublicDSAKeyFile}" != "${SUPrivateDSAKeyFile}" ]; then
			SUPrivateDSAKeyFile="${SOURCE_ROOT}/${SUPublicDSAKeyFile%*pub.pem}priv.pem"
		else
			SUPrivateDSAKeyFile="${SOURCE_ROOT}/dsa_priv.pem"
		fi
		if [ ! -f "${SUPrivateDSAKeyFile}" ]; then
			echo -e "ERROR - ${SUPrivateDSAKeyFile} - DSA Private Key not found..."
			exit 1
		fi
	else
		SUPublicDSAKeyFile="${SOURCE_ROOT}/dsa_pub.pem"
		SUPrivateDSAKeyFile="${SOURCE_ROOT}/dsa_priv.pem"
	fi
	echo -e "SUPrivateDSAKeyFile : ${SUPrivateDSAKeyFile}"
	
	if [ ! -f "${SUPrivateDSAKeyFile}" ] && [ -f "${SOURCE_ROOT}/Sparkle/bin/generate_keys.sh" ]; then
		echo -e "Creating PEM-Keys..."
		cd "${SOURCE_ROOT}"
		bash "${SOURCE_ROOT}/Sparkle/bin/generate_keys.sh" || exit 1
		git add dsa_pub.pem || exit 1
		
	fi
	
	DSAPRIV_GITIGNORE=`cat .gitignore | grep dsa_priv.pem`
	if [ -z "${DSAPRIV_GITIGNORE}" ]; then
		cd "${SOURCE_ROOT}"
		echo -e "*dsa_priv.pem*" >> .gitignore
		git add .gitignore || exit 1
	fi
	
	SUFeedURL=`cat "${SOURCE_ROOT}/.sparkle"`
	if [ -n "${SUFeedURL}" ]; then
		defaults write "${INFO_DOMAIN}" SUFeedURL -string "${SUFeedURL}" || exit 1
	fi

    defaults write "${INFO_DOMAIN}" SUEnableAutomaticChecks -bool YES || exit 1
    defaults write "${INFO_DOMAIN}" SUEnableSystemProfiling -bool NO || exit 1
    defaults write "${INFO_DOMAIN}" SUShowReleaseNotes -bool YES || exit 1
    defaults write "${INFO_DOMAIN}" SUScheduledCheckInterval -int 86400 || exit 1
    defaults write "${INFO_DOMAIN}" SUAllowsAutomaticUpdates -bool YES || exit 1

fi

####################

if [ ! -e "${PRODUCT}" ]; then
	exit 1
fi

tar -C "${BUILT_PRODUCTS_DIR}" -czf "${ARCHIVE}" "${FULL_PRODUCT_NAME}" || exit 1

if [ -f "${SUPrivateDSAKeyFile}" ] && [ -f "${SOURCE_ROOT}/Sparkle/bin/sign_update.sh" ]; then
	
	DSA_SIGNATURE=`bash "${SOURCE_ROOT}/Sparkle/bin/sign_update.sh" "${ARCHIVE}" "${SUPrivateDSAKeyFile}"`
	
	SIGNATURE_FILE="${PRODUCT%.*}_v${CFBundleVersion}.signature"
	if [ -n "${DSA_SIGNATURE}" ]; then
		echo "${DSA_SIGNATURE}" > "${SIGNATURE_FILE}"
	else
		rm -f "${SIGNATURE_FILE}"
		exit 1
	fi
	
	if [ -z "${SUPublicDSAKeyFile}" ]; then
		SUPublicDSAKeyFile="./dsa_pub.pem"
	fi	
	defaults write "${INFO_DOMAIN}" SUPublicDSAKeyFile -string "${SUPublicDSAKeyFile##*/}" || exit 1
	
else
	
	cd "${SOURCE_ROOT}"
	if [ -f "${SUPublicDSAKeyFile}" ] || [ -f "dsa_pub.pem" ]; then
		echo -e "STOOOP"
		exit 1
	fi
	echo -e "STOOOP"
	exit 1
fi

####################

exit 0