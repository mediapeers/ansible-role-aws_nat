require 'spec_helper'

describe "AWS NAT setup" do
  describe package('awscli') do
    it { should be_installed }
  end

  describe file('/etc/') do
    it { should be_file }
  end
end
