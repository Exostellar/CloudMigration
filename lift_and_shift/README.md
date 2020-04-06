# Lift and Shift
Lift and Shift is a tool that facilitates lifting a first layer virtual machine from a VMware vSphere environment to a public cloud as a second layer virtual machine. 

## Preparation
Before running lift_and_shift.sh on Xen host VM, the following preparations are needed.
1. Target VM is powered on;
2. Add the public key of xen host to target VM;
3. Special characters needs to be escaped in the password for vCenter by using `%` followed by the ASCII hex value;
4. Install vCenter Server root certificates on Xen host VM, refer to [this link](https://kb.vmware.com/s/article/2108294#certificate_download_in_small_deployments) for detailed information;
5. The destination VM must have Xen-blanket installed. For more details about how to install Xen-blanket, please refer to [this project](https://github.com/Exotanium/Xen-Blanket-NG).

## Getting started
Specify the information about the target and destination VM in config section of the script, then run the following command on the destination VM.
```./lift_and_shift.sh```
