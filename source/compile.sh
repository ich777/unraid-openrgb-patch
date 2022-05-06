# Create necessary directories, download source and patch files
cd ${DATA_DIR}/linux-$UNAME
mkdir -p /OPENRGB/lib/modules/${UNAME}/kernel/drivers/i2c/busses
cd ${DATA_DIR}/linux-$UNAME
wget -O ${DATA_DIR}/linux-$UNAME/OpenRGB.patch https://gitlab.com/CalcProgrammer1/OpenRGB/-/raw/master/OpenRGB.patch
patch -p1 < ${DATA_DIR}/linux-$UNAME/OpenRGB.patch
echo "CONFIG_I2C_NCT6775=m" >> ${DATA_DIR}/linux-$UNAME/.config
while true; do echo -e "n"; sleep 1s; done | make modules_prepare

# Compile modules
cd ${DATA_DIR}/linux-$UNAME/
make SUBDIRS=drivers/i2c/busses/ -j${CPU_COUNT}

# Copy modules to destination
cp ${DATA_DIR}/linux-$UNAME/drivers/i2c/busses/i2c-nct6775.ko \
  ${DATA_DIR}/linux-$UNAME/drivers/i2c/busses/i2c-piix4.ko \
  /OPENRGB/lib/modules/${UNAME}/kernel/drivers/i2c/busses

# Compress modules
while read -r line
do
  xz --check=crc32 --lzma2 $line
done < <(find /OPENRGB/lib/modules/${UNAME}/kernel/drivers/i2c/busses -name "*.ko")

# Download and install icon
cd ${DATA_DIR}
mkdir -p /OPENRGB/usr/local/emhttp/plugins/openrgb-patch/images
wget -O /OPENRGB/usr/local/emhttp/plugins/openrgb-patch/images/openrgb-patch.png https://raw.githubusercontent.com/ich777/docker-templates/master/ich777/images/openrgb.png

# Create Slackware package
PLUGIN_NAME="openrgb_patch"
BASE_DIR="/OPENRGB"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"
mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/OpenRGB.patch
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5