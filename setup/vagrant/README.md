# Lab VM with Vagrant

A real virtual machine gives you everything a container cannot: `systemd`, extra disks, a firewall you
can safely break, and a kernel of its own. When you ruin it, `vagrant destroy` and start again.

> [!NOTE]
> These Vagrantfiles have not been run in CI. If a step fails on your machine, please open a
> [lesson feedback issue](https://github.com/akintunero/Linux-Projects/issues/new/choose).

## Intel / AMD (Windows, Linux, macOS Intel)

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and
   [Vagrant](https://developer.hashicorp.com/vagrant/install).
2. From this folder:

   ```bash
   vagrant up
   vagrant ssh
   ```

3. Inside the VM the repository is at `/vagrant`:

   ```bash
   cd /vagrant && make check
   ```

The VM has two spare 1 GB disks (`/dev/sdb`, `/dev/sdc`) for the disk, LVM and RAID lessons.

**Start over:** `vagrant destroy -f && vagrant up`.

## Apple Silicon (M1, M2, M3)

VirtualBox does not run on Apple Silicon, so this path uses VMware Fusion and an ARM Ubuntu box.

1. Install [Homebrew](https://brew.sh/) and Vagrant:

   ```bash
   brew install --cask vagrant
   ```

2. Install Rosetta (needed by some tooling) and
   [VMware Fusion](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion):

   ```bash
   softwareupdate --install-rosetta --agree-to-license
   ```

3. Add the VMware provider plugin for Vagrant:

   ```bash
   vagrant plugin install vagrant-vmware-desktop
   ```

4. Start the VM with the Apple Silicon Vagrantfile:

   ```bash
   VAGRANT_VAGRANTFILE=Vagrantfile.apple-silicon vagrant up
   VAGRANT_VAGRANTFILE=Vagrantfile.apple-silicon vagrant ssh
   ```

This variant does not attach the extra disks. For the disk lessons, add virtual disks in VMware Fusion's
VM settings.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `VT-x is disabled in the BIOS` | Enable virtualization (Intel VT-x / AMD-V) in your BIOS/UEFI. |
| VirtualBox errors on Windows with Hyper-V on | Disable Hyper-V/WSL features, or use the [dev container](../README.md) instead. |
| `vagrant up` hangs at *SSH auth* | Run `vagrant up --debug`; usually the box is still booting. Wait 2 minutes and retry. |
| Disk attach fails on a second `vagrant up` | Run `vagrant destroy -f`, delete `.lab-disk*.vdi`, then `vagrant up`. |
