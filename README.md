# CloudMigration
CloudMigration is a tool for cloud migration. It consists of two tools that could work in three different senarios.
1. **For preparing a first layer VM running on VMware ESXi for cross-cloud migration.** The lift and shift tool will lift the first layer VM and convert its image so that it could run on top of Xen as a second layer VM.
2. **For live migration between private cloud and public cloud.** The migration tool could be used to set up Xen and the network that is required for live migration between private and public clouds.
2. **For live migration across public clouds.** The migration tool could also be used to set up Xen and the network that is required for live migration between public clouds.
