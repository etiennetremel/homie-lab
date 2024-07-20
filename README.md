# Home lab setup using Talos, Kubernetes, Synology CSI, Gluetun, etc.

## Overview

A single node Kubernetes cluster setup on an Asus NUC 13 Pro i7 with the
following stack:

- cert-manager (LetsEncrypt)
- external-dns
- homeassistant
- ingress-nginx
- jackett
- qbittorrent + gluetun VPN
- radarr
- sonarr
- synology-csi
- talos (Kubernetes)

## Getting started

### 1. Prepare secure boot image to start Talos on the machine (OSX)

```bash
# pull latest SecureBoot image
wget https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.0/metal-amd64-secureboot.iso

hdiutil convert -format UDRW -o metal-amd64-secureboot.img metal-amd64-secureboot.iso
mv metal-amd64-secureboot.img{.dmg,}

# plug the usb key, find the disk number
diskutil list

# use the path to the disk and change the command below accordingly
diskutil unmountDisk /dev/disk3
sudo dd if=metal-amd64-secureboot.img of=/dev/rdisk3 bs=1m
diskutil eject /dev/disk3
```

### 2. Prepare Kubernetes cluster

```bash
# following image include btrfs and iscsi-tools extensions, you can generate
# your own image from https://factory.talos.dev
export TALOS_FACTORY_IMAGE_INSTALLER=factory.talos.dev/installer-secureboot/446d7bb4b23caecb9134bcab115e52d55af742da8e04760817f6a31997dc32d9:v1.7.5

export MACHINE_IP=192.168.94.254

# check which disk are available on the machine, then update the
# talos/tpm-disk-encryption.yaml file accordingly
talosctl -n "$MACHINE_IP" --talosconfig=talosconfig disks

# generate talos config
talosctl gen config homie "https://${MACHINE_IP}:6443" \
  --install-image "$TALOS_FACTORY_IMAGE_INSTALLER" \
  --config-patch @talos/tpm-disk-encryption.yaml

talosctl -n "$MACHINE_IP" apply-config \
  --insecure \
  -f controlplane.yaml

# generate kubeconfig
talosctl -n "$MACHINE_IP" --talosconfig=talosconfig kubeconfig
```

### 3. Install cluster apps

Make appropriate patches to ingresses/secrets. Then:

```bash
# apply kubernetes config using Kustomize
kubectl apply -k ./clusters/homie
```

Notes: while formatting the disk on the first run, the associated pod will stay in a
ContainerCreating state for a while depending on the disk size.

## Cluster upgrade

```bash
# following image include btrfs and iscsi-tools extensions, you can generate
# your own image from https://factory.talos.dev
export TALOS_FACTORY_IMAGE_INSTALLER=factory.talos.dev/installer-secureboot/446d7bb4b23caecb9134bcab115e52d55af742da8e04760817f6a31997dc32d9:v1.7.5

export MACHINE_IP=192.168.94.254

talosctl upgrade -n "$MACHINE_IP" \
  --talosconfig=talosconfig \
  --image "$TALOS_FACTORY_IMAGE_INSTALLER" \
  --preserve
```

### 4. Testing

Make sure the VPN is not leaking your IP by downloading the IP Leak torrent
magnet from https://ipleak.net.
The IP will be disclosed in the description.
