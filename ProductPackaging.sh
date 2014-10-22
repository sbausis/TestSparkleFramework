#!/bin/sh

#  ProductPackaging.sh
#  Test
#
#  Created by Simon Pascal Baur on 21/10/14.
#  Copyright (c) 2014 Simon Pascal Baur. All rights reserved.

#set -e
set -x

####################

INFO_PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
echo -e "INFO_PLIST : ${INFO_PLIST}"

INFO_DOMAIN="${INFO_PLIST%/Info.plist}/Info"
echo -e "INFO_DOMAIN : ${INFO_DOMAIN}"

PRODUCT="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
echo -e "PRODUCT : ${PRODUCT}"

CFBundleVersion=`defaults read "${INFO_DOMAIN}" CFBundleVersion`
echo -e "CFBundleVersion : ${CFBundleVersion}"

CFBundleShortVersionString=`defaults read "${INFO_DOMAIN}" CFBundleShortVersionString`
echo -e "CFBundleShortVersionString : ${CFBundleShortVersionString}"

if [ -n "${CFBundleVersion}" ]; then
	ARCHIVE="${PRODUCT%.*}_v${CFBundleVersion}.tar.gz"
else
	ARCHIVE="${PRODUCT%.*}.tar.gz"
fi
echo -e "ARCHIVE : ${ARCHIVE}"

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
			echo -e "ERROR - ${SUPrivateDSAKeyFile} - DSA Public Key not found..."
			exit 1
		fi
	else
		SUPrivateDSAKeyFile="${SOURCE_ROOT}/dsa_priv.pem"
	fi
	echo -e "SUPrivateDSAKeyFile : ${SUPrivateDSAKeyFile}"
	
	if [ ! -f "${SUPrivateDSAKeyFile}" ] && [ -f "${SOURCE_ROOT}/Sparkle/bin/generate_keys.sh" ]; then
		echo -e "Creating PEM-Keys..."
		cd "${SOURCE_ROOT}"
		bash "${SOURCE_ROOT}/Sparkle/bin/generate_keys.sh"
		git add dsa_pub.pem
		
	fi
	
	DSAPRIV_GITIGNORE=`cat .gitignore | grep dsa_priv.pem`
	if [ -z "${DSAPRIV_GITIGNORE}" ]; then
		cd "${SOURCE_ROOT}"
		echo -e "*dsa_priv.pem" >> .gitignore
		git add .gitignore
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
		SUPublicDSAKeyFile="dsa_pub.pem"
		defaults write "${INFO_DOMAIN}" SUPublicDSAKeyFile -string "${SUPublicDSAKeyFile}" || exit 1
	fi
	
fi

####################

exit 0