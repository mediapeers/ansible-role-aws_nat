require 'spec_helper'

describe "AWS NAT setup" do
  describe package('awscli') do
    it { should be_installed }
  end

  describe file('/etc/udev/rules.d/53-ec2-network-interfaces.rules') do
    it { should be_file }
    it { should be_owned_by('root') }
    it { should be_mode(644) }
  end

  describe file('/etc/udev/rules.d/75-persistent-net-generator.rules') do
    it { should be_file }
    it { should be_owned_by('root') }
    it { should be_mode(644) }
  end

  describe file('/etc/dhcp/dhclient-exit-hooks.d/ec2dhcp') do
    it { should be_file }
    it { should be_owned_by('root') }
    it { should be_mode(644) }
  end

  describe file('/etc/network/ec2net-functions') do
    it { should be_file }
    it { should be_owned_by('root') }
    it { should be_mode(644) }
  end

  describe file('/etc/network/ec2net.hotplug') do
    it { should be_file }
    it { should be_owned_by('root') }
    it { should be_mode(744) }
  end

  describe file('/etc/sysctl.conf') do
    it { should be_file }
    its(:content) { should include('net.ipv4.ip_forward=1') }
  end

  describe command('sudo iptables -t nat -S') do
    its(:stdout) { should include("-A POSTROUTING -s 10.10.1.0/24 -o eth1 -j MASQUERADE") }
    its(:stdout) { should include("-A POSTROUTING -s 10.10.2.0/24 -o eth1 -j MASQUERADE") }
  end

  describe file('/etc/rc.local') do
    it { should be_file }
    its(:content) { should include(
      "curl --silent http://169.254.169.254/latest/meta-data/instance-id | xargs aws ec2 attach-network-interface --network-interface-id #{ANSIBLE_VARS.fetch('nat_eni_id', 'Fail')}"
    ) }
    it(:content) { should include('sleep 30 && ifdown eth0') }
  end

  describe file('/home/ubuntu/.ssh/config') do
    it { should be_file }
    its(:content) { should include("Host *\nStrictHostKeyChecking no") }
  end
end
