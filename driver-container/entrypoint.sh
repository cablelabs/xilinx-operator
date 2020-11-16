
# Older FPGA card
if [ "${CARD_VER}" == "vcu1525" ] ; then
    SERVER="https://owncloud.cablelabs.com/index.php/s/Bn2RjIcvbFm4DTQ/download?path=%2F&files="
    RUNTIME="xrt_201830.2.1.0_7.8.2003-xrt.rpm"
    DEPLOYMENT="xilinx-vcu1525-dynamic-5.1-2342198.x86_64.rpm"

# U200 FPGA card
elif [ "${CARD_VER}" == "u200" ] ; then
    SERVER="https://www.xilinx.com/bin/public/openDownload?filename="
    RUNTIME="xrt_202010.2.7.766_7.4.1708-x86_64-xrt.rpm"
    DEPLOYMENT="xilinx-u200-xdma-201830.2-2580015.x86_64.rpm"
else
    echo "CARD_VER env var is not supported or not specified: ${CARD_VER}"
    exit 1
fi

echo "Installing drivers for ${CARD_VER}"

curl -fsSL -o /tmp/${RUNTIME} "${SERVER}${RUNTIME}"
curl -fsSL -o /tmp/${DEPLOYMENT} "${SERVER}${DEPLOYMENT}"

yum-config-manager --enable rhel-7-server-optional-rpms
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y kernel-headers-`uname -r`
yum install -y kernel-devel-`uname -r`
yum install -y /tmp/${RUNTIME}
yum install -y /tmp/${DEPLOYMENT}
echo "modprobe xclmgmt"
modprobe xclmgmt
echo "modprobe xocl"
modprobe xocl
