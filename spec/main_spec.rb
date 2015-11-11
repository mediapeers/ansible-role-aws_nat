require 'spec_helper'

describe "AWS NAT setup" do
  package('awscli') do
    it { should be_installed }
  end

  describe file('/root/.aws') do
    it { should be_directory }
    it { should be_mode(775) }
  end

  describe file('/root/.aws/config') do
    it { should be_file }
    it { should be_mode(600) }
    its(:content) { should include("region = us-east-1") }
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

  describe file('/etc/rc.local') do
    it { should be_file }
    its(:content) { should include(
      "curl --silent http://169.254.169.254/latest/meta-data/instance-id | xargs aws ec2 attach-network-interface --network-interface-id #{ANSIBLE_VARS.fetch('nat_eni_id', 'Fail')}"
    ) }
  end

  describe file('/etc/sysctl.conf') do
    it { should be_file }
    its(:content) { should include('net.ipv4.ip_forward=1') }
  end

  describe file('/etc/rc.local') do
    its(:content) { should include("iptables -t nat -A POSTROUTING -o eth1 -s 10.10.1.0/24 -j MASQUERADE") }
    its(:content) { should include("iptables -t nat -A POSTROUTING -o eth1 -s 10.10.2.0/24 -j MASQUERADE") }
    its(:content) { should include('sleep 30 && ifdown eth0') }
  end

  describe file('/home/ubuntu/.ssh/config') do
    it { should be_file }
    its(:content) { should include("Host *\nStrictHostKeyChecking no") }
  end
end
