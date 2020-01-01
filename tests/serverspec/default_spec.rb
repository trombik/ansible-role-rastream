require "spec_helper"
require "serverspec"

service = "rastream"
log_dir = "/var/log/argus/rastream"
systemd_unit_file = nil
extra_groups = []
user = "argus"
group = "argus"
default_group = "wheel"
default_user = "root"
ports = []
extra_packages = []

case os[:family]
when "ubuntu"
  systemd_unit_file = "/lib/systemd/system/rastream.service"
  default_group = "root"
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

if systemd_unit_file
  describe file(systemd_unit_file) do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
    case os[:family]
    when "ubuntu"
      its(:content) { should match(/#{Regexp.escape("EnvironmentFile=-/etc/default/rastream")}/) }
    when "redhat"
      its(:content) { should match(/#{Regexp.escape("EnvironmentFile=-/etc/sysconfig/rastream")}/) }
    end
  end
end

describe user(user) do
  it { should belong_to_group group }
  extra_groups.each do |g|
    it { should belong_to_group g }
  end
end

describe file(log_dir) do
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "openbsd"
  describe file("/etc/rc.conf.local") do
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
    its(:content) { should match(/^#{Regexp.escape("#{service}_flags=-4")}/) }
  end
when "redhat"
  describe file("/etc/sysconfig/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end
when "ubuntu"
  describe file("/etc/default/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/#{Regexp.escape("RASTREAM_OPTIONS=\"-S 127.0.0.1 -M time 1m -w #{log_dir}/%Y/%m/%d/%H.%M.%S.ra\"")}/) }
  end
when "freebsd"
  describe file("/etc/rc.conf.d") do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
  end

  describe file("/etc/rc.conf.d/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

describe file(log_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 755 }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
