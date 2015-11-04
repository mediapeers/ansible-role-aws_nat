## Ansible AWS NAT role
An ansible role thar configures an Ubuntu based AMI to be a used for a
NAT instance to route traffic from a private VPC subnet.
The resulting AMI can be used to launch an instance into a scaling group to have a failover
when the instance goes down. It's for this reason reusing an unattached ENI so routing
proceeds to work without updating VPC routing tables or IP/DNS records for things pointing to the NAT instance.
See this blog article fro the idea behind this concept:
http://www.cakesolutions.net/teamblogs/making-aws-nat-instances-highly-available-without-the-compromises

Setting up the ENI and VPC is not part of this role!

For hotplugging the ENI into Ubuntu this role uses ubuntu-ec2net utils. See here https://github.com/ademaria/ubuntu-ec2net
They are derived from the utils AWS provides for their own Linux flavour http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#ec2-net-utils

## Requirements
- AWS account with VPC prepared
- AWS Ubuntu base image
- Unattached ENI interface with source/dest check disabled

## Role Variables
* `nat_eni_id: eni-abc123` - The id of the ENI to be attached, create it before and add it to your VPC routing table
* `vpc` - this should contain the return values of the VPC setup with the Ansible VPC module

## Dependencies
Depends on no other ansible roles.

## Example Playbook
Just include the role in your play after you created VPC and ENI. See role example at the end:

```yaml
# Example on how to meet the preconditions for this role:
- name: Create ENI and add it to the VPC routing
  hosts: localhost
  tasks:
    - name: Create ENI
      ec2_eni:
        # some setup stuff
      register: nat_eni

    - name: Disable source/dest check
      ec2_eni:
        eni_id: "{{nat_eni.interface.id}}"
        source_dest_check: false
      register: nat_eni

    - name: Allocating EIP
      ec2_eip:
        in_vpc: true
        # some other params
      register: nat_eip

    - name: Attaching EIP to ENI
      ec2_eip:
        device_id: "{{nat_eni.interface.id}}"
        ip: "{{nat_eip.public_ip}}"
        region: my_region

    - name: Add ENI to VPC routing
      ec2_vpc:
        # some other params
        route_tables:
          - subnets:
            - 172.1.2.0/24
            - 172.1.3.0/24
            routes:
              - dest: 0.0.0.0/0
                gw: "{{ pf_nat_eni.interface.id }}"
      register: vpc

# Startup ec2 instance...

# Role usage example:
- name: Configure NAT instance for AMI
  hosts: ami_baking_instance
  remote_user: ubuntu
  vars:
    nat_eni: "{{ hostvars['localhost']['nat_eni'] }}"
    my_vpc: "{{ hostvars['localhost']['vpc'] }}"
  roles:
    - { role: mpx.aws_nat, nat_eni_id: "{{nat_eni.interface.id}}", vpc: "{{my_vpc}}" }
  tasks:
    # ...

# Create AMI for autoscaling...
```
The reulting AMI will auto attach to the ENI (which survives all the reboots).

You can find the `ec2_eni` module here: https://github.com/ansible/ansible-modules-extras/blob/devel/cloud/amazon/ec2_eni.py

## License
BSD

## Author Information
Stefan Horning <horning@mediapeers.com>

Also includes work from https://github.com/ademaria
