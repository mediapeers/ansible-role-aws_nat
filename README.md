## Ansible AWS NAT role
An ansible role that creates an Ubuntu based AMI that's configured to be a used for a
NAT instance to route traffic from a private VPC subnet.
It the AMI will be used to launch an instance into a scaling group have a failover
when the instance goes down. It's for this reason reusing an attached ENI so routing
proceeds to work without updating VPC routing tables or IP/DNS records for things pointing to the NAT instance.
See this blog article fro the idea behind this concept:
http://www.cakesolutions.net/teamblogs/making-aws-nat-instances-highly-available-without-the-compromises

Setting up the ENI and VPC is not par of this role!

For hotplugging the ENI into Ubuntu this role uses ubuntu-ec2net utils. See here https://github.com/ademaria/ubuntu-ec2net
They are derived from the utils AWS provides for their own Linux flavour http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#ec2-net-utils

## Requirements
- AWS account
- Ubuntu base image
- Unattached ENI interface with source/dest check disabled

## Role Variables
`eni_id: eni-abc123 # The id of the ENI to be attached, create it before and add it to your VPC routing table`

## Dependencies
Ansible

## Example Playbook
Just include the role in your play. For example:

```yaml
- hosts: ami_backing_instance
  remote_user: ubuntu
  roles:
    - { role: mpx.aws_nat, eni_id: 'eni-a33db567' }
```

## License
BSD

## Author Information
Stefan Horning <horning@mediapeers.com>

Also includes work from https://github.com/ademaria
