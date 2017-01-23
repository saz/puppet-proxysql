# This has to be a separate type to enable collecting
Puppet::Type.newtype(:proxy_mysql_user) do
  @doc = 'Manage a ProxySQL mysql_user. This includes management of users password as well as privileges.'

  ensurable

  autorequire(:file) { '/root/.my.cnf' }
  autorequire(:class) { 'mysql::client' }

  newparam(:name, :namevar => true) do
    desc 'The name of the user to manage.'
  end

  newparam(:load_to_runtime) do
    desc 'Load this entry to the active runtime.'
    defaultto :true
    newvalues(:true, :false)
  end

  newparam(:save_to_disk) do
    desc 'Perist this entry to the disk.'
    defaultto :true
    newvalues(:true, :false)
  end

  newproperty(:password) do
    desc 'The password of the user. You can use mysql_password() for creating a hashed password.'
    newvalue(/\w*/)
  end

  newproperty(:active) do
    desc "Is the user active or not."
    defaultto 1
    newvalue(/[01]/)
  end

  newproperty(:use_ssl) do
    desc "Use ssl or not."
    defaultto 0
    newvalue(/[01]/)
  end

  newproperty(:default_hostgroup) do
    desc "Default hostgroup for the user."
    defaultto 0
    newvalue(/\d+/)
  end

  newproperty(:default_schema) do
    desc "Default schema for the user."
    newvalue(/\w+/)
  end

  newproperty(:schema_locked) do
    desc "Is the user locked in the default schema or not."
    defaultto 0
    newvalue(/[01]/)
  end

  newproperty(:transaction_persistent) do
    desc "Disable routing across hostgroups once a transaction has started for a specific user."
    defaultto 0
    newvalue(/[01]/)
  end

  newproperty(:fast_forward) do
    desc "Use fast forwrd or not."
    defaultto 0
    newvalue(/[01]/)
  end

  newproperty(:backend) do
    desc "Backend or not."
    defaultto 1
    newvalue(/[01]/)
  end

  newproperty(:frontend) do
    desc "Frontend or not."
    defaultto 1
    newvalue(/[01]/)
  end

  newproperty(:max_connections) do
    desc "Max concurrent connections for the user."
    defaultto 10000
    newvalue(/\d+/)
  end


end