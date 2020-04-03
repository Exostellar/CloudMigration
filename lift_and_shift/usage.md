# Requirements
Before running lift_and_shift.sh on Xen host VM, make sure
1. Target VM is powered on;
2. Add the public key of xen host to target VM;
3. Special characters needs to be escaped in the password for vCenter by using % followed by the ASCII hex value;
4. Install vCenter Server root certificates on Xen host VM, refer to [this link](https://kb.vmware.com/s/article/2108294#certificate_download_in_small_deployments) for detailed information;
5. Set the parameters in config section in the script.
