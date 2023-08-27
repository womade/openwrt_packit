#!/usr/bin/env bash
#==============================================================================================
#
# Description: Automatically Packaged OpenWrt
# Function: Use Flippy's kernrl files and script to Packaged openwrt
# Copyright (C) 2021 https://github.com/womade/openwrt_packit
# Copyright (C) 2021 https://github.com/ophub/Y-ZHENG-openwrt-actions
#
#======================================= Functions list =======================================
#
# error_msg         : Output error message
# init_var          : Initialize all variables
# init_packit_repo  : Initialize packit openwrt repo
# query_kernel      : Query the latest kernel version
# check_kernel      : Check kernel files integrity
# download_kernel   : Download the kernel
# make_openwrt      : Loop to make OpenWrt files
# out_github_env    : Output github.com variables
#
#=============================== Set make environment variables ===============================
#
# Set the default package source download repository
SCRIPT_REPO_URL_VALUE="https://github.com/womade/openwrt_packit"
SCRIPT_REPO_BRANCH_VALUE="main"

# Set the *rootfs.tar.gz package save name
PACKAGE_FILE="openwrt-armvirt-64-generic-rootfs.tar.gz"

# Set the list of supported device
PACKAGE_OPENWRT=(
    "rock5b" "h88k" "h88k-v3" "ak88"
    "r66s" "r68s" "h66k" "h68k" "h69k" "h69k-max" "e25" "photonicat" "cm3"
    "beikeyun" "l1pro"
    "vplus"
    "s922x" "s922x-n2" "s905x3" "s905x2" "s912" "s905d" "s905"
    "qemu"
    "diy"
)
# Set the list of devices using the [ rk3588 ] kernel
PACKAGE_OPENWRT_RK3588=("rock5b" "h88k" "h88k-v3" "ak88")
# Set the list of devices using the [ 6.x.y ] kernel
PACKAGE_OPENWRT_KERNEL6=("r66s" "r68s" "h66k" "h68k" "h69k" "h69k-max" "e25" "photonicat" "cm3")
# All are packaged by default, and independent settings are supported, such as: [ s905x3_s905d_rock5b ]
PACKAGE_SOC_VALUE="all"

# Set the default packaged kernel download repository
KERNEL_REPO_URL_VALUE="breakings/OpenWrt"
# Set kernel tag: kernel_stable, kernel_rk3588
KERNEL_TAGS=("stable" "rk3588")
STABLE_KERNEL=("6.1.1" "5.15.1")
RK3588_KERNEL=("5.10.110")
KERNEL_AUTO_LATEST_VALUE="true"

# Set the working directory under /opt
SELECT_PACKITPATH_VALUE="openwrt_packit"
SELECT_OUTPUTPATH_VALUE="output"
GZIP_IMGS_VALUE="auto"
SAVE_OPENWRT_ARMVIRT_VALUE="true"

# Set the default packaging script
SCRIPT_VPLUS_FILE="mk_h6_vplus.sh"
SCRIPT_BEIKEYUN_FILE="mk_rk3328_beikeyun.sh"
SCRIPT_L1PRO_FILE="mk_rk3328_l1pro.sh"
SCRIPT_CM3_FILE="mk_rk3566_radxa-cm3-rpi-cm4-io.sh"
SCRIPT_R66S_FILE="mk_rk3568_r66s.sh"
SCRIPT_R68S_FILE="mk_rk3568_r68s.sh"
SCRIPT_H66K_FILE="mk_rk3568_h66k.sh"
SCRIPT_H68K_FILE="mk_rk3568_h68k.sh"
SCRIPT_H69K_FILE="mk_rk3568_h69k.sh"
SCRIPT_E25_FILE="mk_rk3568_e25.sh"
SCRIPT_PHOTONICAT_FILE="mk_rk3568_photonicat.sh"
SCRIPT_ROCK5B_FILE="mk_rk3588_rock5b.sh"
SCRIPT_H88K_FILE="mk_rk3588_h88k.sh"
SCRIPT_H88KV3_FILE="mk_rk3588_h88k-v3.sh"
SCRIPT_S905_FILE="mk_s905_mxqpro+.sh"
SCRIPT_S905D_FILE="mk_s905d_n1.sh"
SCRIPT_S905X2_FILE="mk_s905x2_x96max.sh"
SCRIPT_S905X3_FILE="mk_s905x3_multi.sh"
SCRIPT_S912_FILE="mk_s912_zyxq.sh"
SCRIPT_S922X_FILE="mk_s922x_gtking.sh"
SCRIPT_S922X_N2_FILE="mk_s922x_odroid-n2.sh"
SCRIPT_QEMU_FILE="mk_qemu-aarch64_img.sh"
SCRIPT_DIY_FILE="mk_diy.sh"

# Set make.env related parameters
WHOAMI_VALUE="Y-ZHENG"
OPENWRT_VER_VALUE="auto"
SW_FLOWOFFLOAD_VALUE="1"
HW_FLOWOFFLOAD_VALUE="0"
SFE_FLOW_VALUE="1"
ENABLE_WIFI_K504_VALUE="1"
ENABLE_WIFI_K510_VALUE="1"
DISTRIB_REVISION_VALUE="R$(date +%Y.%m.%d)"
DISTRIB_DESCRIPTION_VALUE="OpenWrt"

# Set font color
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
PROMPT="[\033[93m PROMPT \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#==============================================================================================

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

init_var() {
    echo -e "${STEPS} Start Initializing Variables..."

    # Install the compressed package
    sudo apt-get -qq update
    sudo apt-get -qq install -y curl wget subversion git coreutils p7zip p7zip-full zip unzip gzip xz-utils pigz zstd jq tar

    # Specify the default value
    [[ -n "${SCRIPT_REPO_URL}" ]] || SCRIPT_REPO_URL="${SCRIPT_REPO_URL_VALUE}"
    [[ "${SCRIPT_REPO_URL}" == http* ]] || SCRIPT_REPO_URL="https://github.com/${SCRIPT_REPO_URL}"
    [[ -n "${SCRIPT_REPO_BRANCH}" ]] || SCRIPT_REPO_BRANCH="${SCRIPT_REPO_BRANCH_VALUE}"
    [[ -n "${KERNEL_REPO_URL}" ]] || KERNEL_REPO_URL="${KERNEL_REPO_URL_VALUE}"
    [[ -n "${PACKAGE_SOC}" ]] || PACKAGE_SOC="${PACKAGE_SOC_VALUE}"
    [[ -n "${KERNEL_AUTO_LATEST}" ]] || KERNEL_AUTO_LATEST="${KERNEL_AUTO_LATEST_VALUE}"
    [[ -n "${GZIP_IMGS}" ]] || GZIP_IMGS="${GZIP_IMGS_VALUE}"
    [[ -n "${SELECT_PACKITPATH}" ]] || SELECT_PACKITPATH="${SELECT_PACKITPATH_VALUE}"
    [[ -n "${SELECT_OUTPUTPATH}" ]] || SELECT_OUTPUTPATH="${SELECT_OUTPUTPATH_VALUE}"
    [[ -n "${SAVE_OPENWRT_ARMVIRT}" ]] || SAVE_OPENWRT_ARMVIRT="${SAVE_OPENWRT_ARMVIRT_VALUE}"
    [[ -n "${GH_TOKEN}" ]] && GH_TOKEN="${GH_TOKEN}" || GH_TOKEN=""

    # Specify the default packaging script
    [[ -n "${SCRIPT_VPLUS}" ]] || SCRIPT_VPLUS="${SCRIPT_VPLUS_FILE}"
    [[ -n "${SCRIPT_BEIKEYUN}" ]] || SCRIPT_BEIKEYUN="${SCRIPT_BEIKEYUN_FILE}"
    [[ -n "${SCRIPT_L1PRO}" ]] || SCRIPT_L1PRO="${SCRIPT_L1PRO_FILE}"
    [[ -n "${SCRIPT_CM3}" ]] || SCRIPT_CM3="${SCRIPT_CM3_FILE}"
    [[ -n "${SCRIPT_R66S}" ]] || SCRIPT_R66S="${SCRIPT_R66S_FILE}"
    [[ -n "${SCRIPT_R68S}" ]] || SCRIPT_R68S="${SCRIPT_R68S_FILE}"
    [[ -n "${SCRIPT_H66K}" ]] || SCRIPT_H66K="${SCRIPT_H66K_FILE}"
    [[ -n "${SCRIPT_H68K}" ]] || SCRIPT_H68K="${SCRIPT_H68K_FILE}"
    [[ -n "${SCRIPT_H69K}" ]] || SCRIPT_H69K="${SCRIPT_H69K_FILE}"
    [[ -n "${SCRIPT_E25}" ]] || SCRIPT_E25="${SCRIPT_E25_FILE}"
    [[ -n "${SCRIPT_PHOTONICAT}" ]] || SCRIPT_PHOTONICAT="${SCRIPT_PHOTONICAT_FILE}"
    [[ -n "${SCRIPT_ROCK5B}" ]] || SCRIPT_ROCK5B="${SCRIPT_ROCK5B_FILE}"
    [[ -n "${SCRIPT_H88K}" ]] || SCRIPT_H88K="${SCRIPT_H88K_FILE}"
    [[ -n "${SCRIPT_H88KV3}" ]] || SCRIPT_H88KV3="${SCRIPT_H88KV3_FILE}"
    [[ -n "${SCRIPT_S905}" ]] || SCRIPT_S905="${SCRIPT_S905_FILE}"
    [[ -n "${SCRIPT_S905D}" ]] || SCRIPT_S905D="${SCRIPT_S905D_FILE}"
    [[ -n "${SCRIPT_S905X2}" ]] || SCRIPT_S905X2="${SCRIPT_S905X2_FILE}"
    [[ -n "${SCRIPT_S905X3}" ]] || SCRIPT_S905X3="${SCRIPT_S905X3_FILE}"
    [[ -n "${SCRIPT_S912}" ]] || SCRIPT_S912="${SCRIPT_S912_FILE}"
    [[ -n "${SCRIPT_S922X}" ]] || SCRIPT_S922X="${SCRIPT_S922X_FILE}"
    [[ -n "${SCRIPT_S922X_N2}" ]] || SCRIPT_S922X_N2="${SCRIPT_S922X_N2_FILE}"
    [[ -n "${SCRIPT_QEMU}" ]] || SCRIPT_QEMU="${SCRIPT_QEMU_FILE}"
    [[ -n "${SCRIPT_DIY}" ]] || SCRIPT_DIY="${SCRIPT_DIY_FILE}"

    # Specify make.env variable
    [[ -n "${WHOAMI}" ]] || WHOAMI="${WHOAMI_VALUE}"
    [[ -n "${OPENWRT_VER}" ]] || OPENWRT_VER="${OPENWRT_VER_VALUE}"
    [[ -n "${SW_FLOWOFFLOAD}" ]] || SW_FLOWOFFLOAD="${SW_FLOWOFFLOAD_VALUE}"
    [[ -n "${HW_FLOWOFFLOAD}" ]] || HW_FLOWOFFLOAD="${HW_FLOWOFFLOAD_VALUE}"
    [[ -n "${SFE_FLOW}" ]] || SFE_FLOW="${SFE_FLOW_VALUE}"
    [[ -n "${ENABLE_WIFI_K504}" ]] || ENABLE_WIFI_K504="${ENABLE_WIFI_K504_VALUE}"
    [[ -n "${ENABLE_WIFI_K510}" ]] || ENABLE_WIFI_K510="${ENABLE_WIFI_K510_VALUE}"
    [[ -n "${DISTRIB_REVISION}" ]] || DISTRIB_REVISION="${DISTRIB_REVISION_VALUE}"
    [[ -n "${DISTRIB_DESCRIPTION}" ]] || DISTRIB_DESCRIPTION="${DISTRIB_DESCRIPTION_VALUE}"

    # Confirm package object
    [[ "${PACKAGE_SOC}" != "all" ]] && {
        unset PACKAGE_OPENWRT
        oldIFS="${IFS}"
        IFS="_"
        PACKAGE_OPENWRT=(${PACKAGE_SOC})
        IFS="${oldIFS}"

        # Reset required kernel tags
        KERNEL_TAGS_TMP=()
        for kt in "${PACKAGE_OPENWRT[@]}"; do
            if [[ " ${PACKAGE_OPENWRT_RK3588[@]} " =~ " ${kt} " ]]; then
                KERNEL_TAGS_TMP+=("rk3588")
            else
                KERNEL_TAGS_TMP+=("stable")
            fi
        done
        # Remove duplicate kernel tags
        KERNEL_TAGS=()
        KERNEL_TAGS=($(echo "${KERNEL_TAGS_TMP[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    }
    echo -e "${INFO} Package SoC: [ $(echo ${PACKAGE_OPENWRT[@]} | xargs) ]"
    echo -e "${INFO} Kernel tags: [ $(echo ${KERNEL_TAGS[@]} | xargs) ]"

    # Reset STABLE_KERNEL options
    [[ -n "${KERNEL_VERSION_NAME}" && " ${KERNEL_TAGS[@]} " =~ " stable " ]] && {
        unset STABLE_KERNEL
        oldIFS="${IFS}"
        IFS="_"
        STABLE_KERNEL=(${KERNEL_VERSION_NAME})
        IFS="${oldIFS}"
        echo -e "${INFO} Stable kernel: [ $(echo ${STABLE_KERNEL[@]} | xargs) ]"
    }

    # Convert kernel library address to api format
    echo -e "${INFO} Kernel download repository: [ ${KERNEL_REPO_URL} ]"
    [[ "${KERNEL_REPO_URL}" =~ ^https: ]] && KERNEL_REPO_URL="$(echo ${KERNEL_REPO_URL} | awk -F'/' '{print $4"/"$5}')"
    kernel_api="https://api.github.com/repos/${KERNEL_REPO_URL}"
    echo -e "${INFO} Kernel Query API: [ ${kernel_api} ]"
}

init_packit_repo() {
    cd /opt

    # clone ${SELECT_PACKITPATH} repo
    echo -e "${STEPS} Start cloning repository [ ${SCRIPT_REPO_URL} ], branch [ ${SCRIPT_REPO_BRANCH} ] into [ ${SELECT_PACKITPATH} ]"
    git clone -q --single-branch --depth=1 --branch=${SCRIPT_REPO_BRANCH} ${SCRIPT_REPO_URL} ${SELECT_PACKITPATH}

    # Check the *rootfs.tar.gz package
    [[ -z "${OPENWRT_ARMVIRT}" ]] && error_msg "The [ OPENWRT_ARMVIRT ] variable must be specified."

    # Load *-armvirt-64-default-rootfs.tar.gz
    rm -f ${SELECT_PACKITPATH}/${PACKAGE_FILE}
    if [[ "${OPENWRT_ARMVIRT}" == http* ]]; then
        echo -e "${STEPS} wget [ ${OPENWRT_ARMVIRT} ] file into [ ${SELECT_PACKITPATH} ]"
        wget ${OPENWRT_ARMVIRT} -q -O ${SELECT_PACKITPATH}/${PACKAGE_FILE}
        [[ "${?}" -eq "0" ]] || error_msg "Openwrt rootfs file download failed."
    else
        echo -e "${STEPS} copy [ ${GITHUB_WORKSPACE}/${OPENWRT_ARMVIRT} ] file into [ ${SELECT_PACKITPATH} ]"
        cp -f ${GITHUB_WORKSPACE}/${OPENWRT_ARMVIRT} ${SELECT_PACKITPATH}/${PACKAGE_FILE}
        [[ "${?}" -eq "0" ]] || error_msg "Openwrt rootfs file copy failed."
    fi

    # Normal ${PACKAGE_FILE} file should not be less than 10MB
    armvirt_rootfs_size="$(ls -l ${SELECT_PACKITPATH}/${PACKAGE_FILE} 2>/dev/null | awk '{print $5}')"
    echo -e "${INFO} armvirt_rootfs_size: [ ${armvirt_rootfs_size} ]"
    if [[ "${armvirt_rootfs_size}" -ge "10000000" ]]; then
        echo -e "${INFO} [ ${SELECT_PACKITPATH}/${PACKAGE_FILE} ] loaded successfully."
    else
        error_msg "The [ ${SELECT_PACKITPATH}/${PACKAGE_FILE} ] failed to load."
    fi

    # Add custom script
    [[ -n "${SCRIPT_DIY_PATH}" ]] && {
        rm -f ${SELECT_PACKITPATH}/${SCRIPT_DIY}
        if [[ "${SCRIPT_DIY_PATH}" == http* ]]; then
            echo -e "${INFO} Use wget to download custom script file: [ ${SCRIPT_DIY_PATH} ]"
            wget ${SCRIPT_DIY_PATH} -q -O ${SELECT_PACKITPATH}/${SCRIPT_DIY}
            [[ "${?}" -eq "0" ]] || error_msg "Custom script file download failed."
        else
            echo -e "${INFO} Copy custom script file: [ ${SCRIPT_DIY_PATH} ]"
            cp -f ${GITHUB_WORKSPACE}/${SCRIPT_DIY_PATH} ${SELECT_PACKITPATH}/${SCRIPT_DIY}
            [[ "${?}" -eq "0" ]] || error_msg "Custom script file copy failed."
        fi
        chmod +x ${SELECT_PACKITPATH}/${SCRIPT_DIY}
        echo -e "List of [ ${SELECT_PACKITPATH} ] directory files:\n $(ls -l ${SELECT_PACKITPATH})"
    }
}

query_kernel() {
    echo -e "${STEPS} Start querying the latest kernel..."

    # Check the version on the kernel library
    x="1"
    for vb in ${KERNEL_TAGS[@]}; do
        {
            # Select the corresponding kernel directory and list
            if [[ "${vb}" == "rk3588" ]]; then
                down_kernel_list=(${RK3588_KERNEL[@]})
            else
                down_kernel_list=(${STABLE_KERNEL[@]})
            fi

            # Query the name of the latest kernel version
            TMP_ARR_KERNELS=()
            i=1
            for kernel_var in ${down_kernel_list[@]}; do
                echo -e "${INFO} (${i}) Auto query the latest kernel version of the same series for [ ${vb} - ${kernel_var} ]"

                # Identify the kernel <VERSION> and <PATCHLEVEL>, such as [ 6.1 ]
                kernel_verpatch="$(echo ${kernel_var} | awk -F '.' '{print $1"."$2}')"

                # Set the token for api.github.com
                [[ -n "${GH_TOKEN}" ]] && ght="-H \"Authorization: Bearer ${GH_TOKEN}\"" || ght=""

                # Query the latest kernel version
                latest_version="$(
                    curl -s \
                        -H "Accept: application/vnd.github+json" \
                        ${ght} \
                        ${kernel_api}/releases/tags/kernel_${vb} |
                        jq -r '.assets[].name' |
                        grep -oE "${kernel_verpatch}\.[0-9]+" |
                        sort -rV | head -n 1
                )"

                if [[ "$?" -eq "0" && -n "${latest_version}" ]]; then
                    TMP_ARR_KERNELS[${i}]="${latest_version}"
                else
                    TMP_ARR_KERNELS[${i}]="${kernel_var}"
                fi

                echo -e "${INFO} (${i}) [ ${vb} - ${TMP_ARR_KERNELS[$i]} ] is latest kernel."

                let i++
            done

            # Reset the kernel array to the latest kernel version
            if [[ "${vb}" == "rk3588" ]]; then
                unset RK3588_KERNEL
                RK3588_KERNEL=(${TMP_ARR_KERNELS[@]})
                echo -e "${INFO} The latest version of the rk3588 kernel: [ ${RK3588_KERNEL[@]} ]"
            else
                unset STABLE_KERNEL
                STABLE_KERNEL=(${TMP_ARR_KERNELS[@]})
                echo -e "${INFO} The latest version of the stable kernel: [ ${STABLE_KERNEL[@]} ]"
            fi

            let x++
        }
    done
}

check_kernel() {
    [[ -n "${1}" ]] && check_path="${1}" || error_msg "Invalid kernel path to check."
    check_files=($(cat "${check_path}/sha256sums" | awk '{print $2}'))
    m="1"
    for cf in ${check_files[@]}; do
        {
            # Check if file exists
            [[ -s "${check_path}/${cf}" ]] || error_msg "The [ ${cf} ] file is missing."
            # Check if the file sha256sum is correct
            tmp_sha256sum="$(sha256sum "${check_path}/${cf}" | awk '{print $1}')"
            tmp_checkcode="$(cat ${check_path}/sha256sums | grep ${cf} | awk '{print $1}')"
            [[ "${tmp_sha256sum}" == "${tmp_checkcode}" ]] || error_msg "[ ${cf} ]: sha256sum verification failed."
            let m++
        }
    done
    echo -e "${INFO} All [ ${#check_files[@]} ] kernel files are sha256sum checked to be complete.\n"
}

download_kernel() {
    echo -e "${STEPS} Start downloading the kernel..."

    cd /opt

    x="1"
    for vb in ${KERNEL_TAGS[@]}; do
        {
            # Set the kernel download list
            if [[ "${vb}" == "rk3588" ]]; then
                down_kernel_list=(${RK3588_KERNEL[@]})
            else
                down_kernel_list=(${STABLE_KERNEL[@]})
            fi

            # Kernel storage directory
            kernel_path="kernel/${vb}"
            [[ -d "${kernel_path}" ]] || mkdir -p ${kernel_path}

            # Download the kernel to the storage directory
            i="1"
            for kernel_var in ${down_kernel_list[@]}; do
                if [[ ! -d "${kernel_path}/${kernel_var}" ]]; then
                    kernel_down_from="https://github.com/${KERNEL_REPO_URL}/releases/download/kernel_${vb}/${kernel_var}.tar.gz"
                    echo -e "${INFO} (${x}.${i}) [ ${vb} - ${kernel_var} ] Kernel download from [ ${kernel_down_from} ]"

                    wget "${kernel_down_from}" -q -P "${kernel_path}"
                    [[ "${?}" -ne "0" ]] && error_msg "Failed to download the kernel files from the server."

                    tar -mxf "${kernel_path}/${kernel_var}.tar.gz" -C "${kernel_path}"
                    [[ "${?}" -ne "0" ]] && error_msg "[ ${kernel_var} ] kernel decompression failed."
                else
                    echo -e "${INFO} (${x}.${i}) [ ${vb} - ${kernel_var} ] Kernel is in the local directory."
                fi

                # If the kernel contains the sha256sums file, check the files integrity
                [[ -f "${kernel_path}/${kernel_var}/sha256sums" ]] && check_kernel "${kernel_path}/${kernel_var}"

                let i++
            done

            # Delete downloaded kernel temporary files
            rm -f ${kernel_path}/*.tar.gz
            sync

            let x++
        }
    done
}

make_openwrt() {
    echo -e "${STEPS} Start packaging OpenWrt..."

    i="1"
    for PACKAGE_VAR in ${PACKAGE_OPENWRT[@]}; do
        {
            # Distinguish between different OpenWrt and use different kernel
            if [[ -n "$(echo "${PACKAGE_OPENWRT_RK3588[@]}" | grep -w "${PACKAGE_VAR}")" ]]; then
                build_kernel=(${RK3588_KERNEL[@]})
                vb="rk3588"
            else
                build_kernel=(${STABLE_KERNEL[@]})
                vb="$(echo "${KERNEL_TAGS[@]}" | sed -e "s|rk3588||" | xargs)"
            fi

            k="1"
            for kernel_var in ${build_kernel[@]}; do
                {
                    # Rockchip rk3568 series only support 6.x.y and above kernel
                    [[ -n "$(echo "${PACKAGE_OPENWRT_KERNEL6[@]}" | grep -w "${PACKAGE_VAR}")" && "${kernel_var:0:1}" -ne "6" ]] && {
                        echo -e "${STEPS} (${i}.${k}) ${PROMPT} ${PACKAGE_VAR} cannot use ${kernel_var} kernel, skip."
                        let k++
                        continue
                    }

                    # Check the available size of server space
                    now_remaining_space="$(df -Tk ${PWD} | grep '/dev/' | awk '{print $5}' | echo $(($(xargs) / 1024 / 1024)))"
                    [[ "${now_remaining_space}" -le "3" ]] && {
                        echo -e "${WARNING} If the remaining space is less than 3G, exit this packaging. \n"
                        break
                    }

                    cd /opt/kernel

                    # Copy the kernel to the packaging directory
                    rm -f *.tar.gz
                    cp -f ${vb}/${kernel_var}/* .
                    #
                    boot_kernel_file="$(ls boot-${kernel_var}* 2>/dev/null | head -n 1)"
                    KERNEL_VERSION="${boot_kernel_file:5:-7}"
                    [[ "${vb}" == "rk3588" ]] && RK3588_KERNEL_VERSION="${KERNEL_VERSION}" || RK3588_KERNEL_VERSION=""
                    echo -e "${STEPS} (${i}.${k}) Start packaging OpenWrt: [ ${PACKAGE_VAR} ], Kernel directory: [ ${vb} ], Kernel version: [ ${KERNEL_VERSION} ]"
                    echo -e "${INFO} Remaining space is ${now_remaining_space}G. \n"

                    cd /opt/${SELECT_PACKITPATH}

                    # If flowoffload is turned on, then sfe is forced to be closed by default
                    [[ "${SW_FLOWOFFLOAD}" -eq "1" ]] && SFE_FLOW="0"

                    if [[ -n "${OPENWRT_VER}" && "${OPENWRT_VER}" == "auto" ]]; then
                        OPENWRT_VER="$(cat make.env | grep "OPENWRT_VER=\"" | cut -d '"' -f2)"
                        echo -e "${INFO} (${i}.${k}) OPENWRT_VER: [ ${OPENWRT_VER} ]"
                    fi

                    # Generate a custom make.env file
                    rm -f make.env 2>/dev/null
                    cat >make.env <<EOF
WHOAMI="${WHOAMI}"
OPENWRT_VER="${OPENWRT_VER}"
RK3588_KERNEL_VERSION="${RK3588_KERNEL_VERSION}"
KERNEL_VERSION="${KERNEL_VERSION}"
KERNEL_PKG_HOME="/opt/kernel"
SW_FLOWOFFLOAD="${SW_FLOWOFFLOAD}"
HW_FLOWOFFLOAD="${HW_FLOWOFFLOAD}"
SFE_FLOW="${SFE_FLOW}"
ENABLE_WIFI_K504="${ENABLE_WIFI_K504}"
ENABLE_WIFI_K510="${ENABLE_WIFI_K510}"
DISTRIB_REVISION="${DISTRIB_REVISION}"
DISTRIB_DESCRIPTION="${DISTRIB_DESCRIPTION}"
EOF

                    echo -e "${INFO} make.env file info:"
                    cat make.env

                    # Select the corresponding packaging script
                    case "${PACKAGE_VAR}" in
                        vplus)      [[ -f "${SCRIPT_VPLUS}" ]]      && sudo ./${SCRIPT_VPLUS} ;;
                        beikeyun)   [[ -f "${SCRIPT_BEIKEYUN}" ]]   && sudo ./${SCRIPT_BEIKEYUN} ;;
                        l1pro)      [[ -f "${SCRIPT_L1PRO}" ]]      && sudo ./${SCRIPT_L1PRO} ;;
                        cm3)        [[ -f "${SCRIPT_CM3}" ]]        && sudo ./${SCRIPT_CM3} ;;
                        r66s)       [[ -f "${SCRIPT_R66S}" ]]       && sudo ./${SCRIPT_R66S} ;;
                        r68s)       [[ -f "${SCRIPT_R68S}" ]]       && sudo ./${SCRIPT_R68S} ;;
                        h66k)       [[ -f "${SCRIPT_H66K}" ]]       && sudo ./${SCRIPT_H66K} ;;
                        h68k)       [[ -f "${SCRIPT_H68K}" ]]       && sudo ./${SCRIPT_H68K} ;;
                        h69k)       [[ -f "${SCRIPT_H69K}" ]]       && sudo ./${SCRIPT_H69K} ;;
                        h69k-max)   [[ -f "${SCRIPT_H69K}" ]]       && sudo ./${SCRIPT_H69K} "max" ;;
                        rock5b)     [[ -f "${SCRIPT_ROCK5B}" ]]     && sudo ./${SCRIPT_ROCK5B} ;;
                        ak88)       [[ -f "${SCRIPT_H88K}" ]]       && sudo ./${SCRIPT_H88K} ;;
                        h88k)       [[ -f "${SCRIPT_H88K}" ]]       && sudo ./${SCRIPT_H88K} "25" ;;
                        h88k-v3)    [[ -f "${SCRIPT_H88KV3}" ]]     && sudo ./${SCRIPT_H88KV3} ;;
                        e25)        [[ -f "${SCRIPT_E25}" ]]        && sudo ./${SCRIPT_E25} ;;
                        photonicat) [[ -f "${SCRIPT_PHOTONICAT}" ]] && sudo ./${SCRIPT_PHOTONICAT} ;;
                        s905)       [[ -f "${SCRIPT_S905}" ]]       && sudo ./${SCRIPT_S905} ;;
                        s905d)      [[ -f "${SCRIPT_S905D}" ]]      && sudo ./${SCRIPT_S905D} ;;
                        s905x2)     [[ -f "${SCRIPT_S905X2}" ]]     && sudo ./${SCRIPT_S905X2} ;;
                        s905x3)     [[ -f "${SCRIPT_S905X3}" ]]     && sudo ./${SCRIPT_S905X3} ;;
                        s912)       [[ -f "${SCRIPT_S912}" ]]       && sudo ./${SCRIPT_S912} ;;
                        s922x)      [[ -f "${SCRIPT_S922X}" ]]      && sudo ./${SCRIPT_S922X} ;;
                        s922x-n2)   [[ -f "${SCRIPT_S922X_N2}" ]]   && sudo ./${SCRIPT_S922X_N2} ;;
                        qemu)       [[ -f "${SCRIPT_QEMU}" ]]       && sudo ./${SCRIPT_QEMU} ;;
                        diy)        [[ -f "${SCRIPT_DIY}" ]]        && sudo ./${SCRIPT_DIY} ;;
                        *)          echo -e "${WARNING} Have no this SoC. Skipped." && continue ;;
                    esac

                    # Generate compressed file
                    echo -e "${STEPS} (${i}.${k}) Start making compressed files in the [ ${SELECT_OUTPUTPATH} ] directory."
                    cd /opt/${SELECT_PACKITPATH}/${SELECT_OUTPUTPATH}
                    case "${GZIP_IMGS}" in
                        7z | .7z)      ls *.img | head -n 1 | xargs -I % sh -c '7z a -t7z -r %.7z %; rm -f %' ;;
                        zip | .zip)    ls *.img | head -n 1 | xargs -I % sh -c 'zip %.zip %; rm -f %' ;;
                        zst | .zst)    zstd --rm *.img ;;
                        xz | .xz)      xz -z *.img ;;
                        gz | .gz | *)  pigz -f *.img ;;
                    esac

                    echo -e "${SUCCESS} (${i}.${k}) OpenWrt packaging succeeded: [ ${PACKAGE_VAR} - ${vb} - ${kernel_var} ] \n"
                    sync

                    let k++
                }
            done

            let i++
        }
    done

    echo -e "${SUCCESS} All packaged completed. \n"
}

out_github_env() {
    echo -e "${STEPS} Output github.com environment variables..."
    if [[ -d "/opt/${SELECT_PACKITPATH}/${SELECT_OUTPUTPATH}" ]]; then

        cd /opt/${SELECT_PACKITPATH}/${SELECT_OUTPUTPATH}

        if [[ "${SAVE_OPENWRT_ARMVIRT}" == "true" ]]; then
            echo -e "${INFO} copy [ ${PACKAGE_FILE} ] into [ ${SELECT_OUTPUTPATH} ]"
            cp -f ../${PACKAGE_FILE} .
        fi

        # Generate a sha256sum verification file for each OpenWrt file
        for file in *; do [[ ! -d "${file}" ]] && sha256sum "${file}" >"${file}.sha"; done

        echo "PACKAGED_OUTPUTPATH=${PWD}" >>${GITHUB_ENV}
        echo "PACKAGED_OUTPUTDATE=$(date +"%m.%d.%H%M")" >>${GITHUB_ENV}
        echo "PACKAGED_STATUS=success" >>${GITHUB_ENV}
        echo -e "PACKAGED_OUTPUTPATH: ${PWD}"
        echo -e "PACKAGED_OUTPUTDATE: $(date +"%m.%d.%H%M")"
        echo -e "PACKAGED_STATUS: success"
        echo -e "${INFO} PACKAGED_OUTPUTPATH files list:"
        echo -e "$(ls /opt/${SELECT_PACKITPATH}/${SELECT_OUTPUTPATH} 2>/dev/null) \n"
    else
        echo -e "${ERROR} Packaging failed. \n"
        echo "PACKAGED_STATUS=failure" >>${GITHUB_ENV}
    fi
}

# Show welcome message
echo -e "${STEPS} Welcome to use the OpenWrt packaging tool! \n"
echo -e "${INFO} Server CPU configuration information: \n$(cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c) \n"
echo -e "${INFO} Server space usage before starting to compile:\n$(df -hT ${PWD}) \n"

# Packit OpenWrt
init_var
init_packit_repo
[[ "${KERNEL_AUTO_LATEST}" == "true" ]] && query_kernel
download_kernel
make_openwrt
out_github_env

# Show server end information
echo -e "${INFO} Server space usage after compilation:\n$(df -hT ${PWD}) \n"
echo -e "${SUCCESS} The packaging process has been completed. \n"
