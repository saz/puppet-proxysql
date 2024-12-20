# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'proxysql'))
Puppet::Type.type(:proxy_mysql_server).provide(:proxysql, parent: Puppet::Provider::Proxysql) do
  desc 'Manage servers for a ProxySQL instance.'
  commands mysql: 'mysql'

  # Build a property_hash containing all the discovered information about MySQL
  # servers.
  def self.instances
    instances = []
    servers = mysql([defaults_file, '-NBe',
                     'SELECT `hostname`, `port`, `hostgroup_id` FROM `mysql_servers`'].compact).split(%r{\n})

    # To reduce the number of calls to MySQL we collect all the properties in
    # one big swoop.
    servers.each do |line|
      hostname, port, hostgroup_id = line.split(%r{\t})
      query = 'SELECT `hostname`, `port`, `hostgroup_id`, `status`, `weight`, `compression`,  ' \
              '`max_connections`, `max_replication_lag`, `use_ssl`, `max_latency_ms`, `comment`  ' \
              'FROM `mysql_servers` ' \
              "WHERE `hostname` =  '#{hostname}' AND `port` = #{port} AND `hostgroup_id` = '#{hostgroup_id}'"

      @hostname, @port, @hostgroup_id, @status, @weight, @compression,
      @max_connections, @max_replication_lag, @use_ssl, @max_latency_ms,
      @comment = mysql([defaults_file, '-NBe', query].compact).chomp.split(%r{\t})
      name = "#{hostname}:#{port}-#{hostgroup_id}"

      instances << new(
        name: name,
        ensure: :present,
        hostname: @hostname,
        port: @port,
        hostgroup_id: @hostgroup_id,
        status: @status,
        weight: @weight,
        compression: @compression,
        max_connections: @max_connections,
        max_replication_lag: @max_replication_lag,
        use_ssl: @use_ssl,
        max_latency_ms: @max_latency_ms,
        comment: @comment
      )
    end
    instances
  end

  # We iterate over each proxy_mysql_server entry in the catalog and compare it against
  # the contents of the property_hash generated by self.instances
  def self.prefetch(resources)
    servers = instances
    resources.each_key do |name|
      provider = servers.find { |server| server.name == name }
      resources[name].provider = provider if provider
    end
  end

  def create
    _name = @resource[:name]
    hostname = @resource.value(:hostname)
    port = @resource.value(:port) || 3306
    hostgroup_id = @resource.value(:hostgroup_id) || 0
    status = @resource.value(:status) || 'ONLINE'
    weight = @resource.value(:weight) || 1
    compression = @resource.value(:compression) || 0
    max_connections = @resource.value(:max_connections) || 1000
    max_replication_lag = @resource.value(:max_replication_lag) || 0
    use_ssl = @resource.value(:use_ssl) || 0
    max_latency_ms = @resource.value(:max_latency_ms) || 0
    comment = @resource.value(:comment) || ''

    query = 'INSERT INTO mysql_servers (`hostname`, `port`, `hostgroup_id`, `status`, `weight`, `compression`,  ' \
            '`max_connections`, `max_replication_lag`, `use_ssl`, `max_latency_ms`, `comment`) ' \
            "VALUES ('#{hostname}', #{port}, #{hostgroup_id}, '#{status}', #{weight}, #{compression},  " \
            "#{max_connections}, #{max_replication_lag}, #{use_ssl}, #{max_latency_ms}, '#{comment}')"
    mysql([defaults_file, '-e', query].compact)
    @property_hash[:ensure] = :present

    exists? ? (return true) : (return false)
  end

  def destroy
    hostname = @resource.value(:hostname)
    port = @resource.value(:port)
    hostgroup_id = @resource.value(:hostgroup_id)
    query = 'DELETE FROM `mysql_servers` ' \
            "WHERE `hostname` =  '#{hostname}' AND `port` = #{port} AND `hostgroup_id` = '#{hostgroup_id}'"
    mysql([defaults_file, '-e', query].compact)

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def flush
    update_server(@property_flush) if @property_flush
    @property_hash.clear

    load_to_runtime = @resource[:load_to_runtime]
    mysql([defaults_file, '-NBe', 'LOAD MYSQL SERVERS TO RUNTIME'].compact) if load_to_runtime == :true

    save_to_disk = @resource[:save_to_disk]
    mysql([defaults_file, '-NBe', 'SAVE MYSQL SERVERS TO DISK'].compact) if save_to_disk == :true
  end

  def update_server(properties)
    hostname = @resource.value(:hostname)
    port = @resource.value(:port)
    hostgroup_id = @resource.value(:hostgroup_id)

    return false if properties.empty?

    values = []
    properties.each do |field, value|
      values.push("`#{field}` = '#{value}'")
    end

    query = "UPDATE mysql_servers SET #{values.join(', ')} " \
            "WHERE `hostname` =  '#{hostname}' AND `port` = #{port} AND `hostgroup_id` = '#{hostgroup_id}'"
    mysql([defaults_file, '-e', query].compact)

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  # Generates method for all properties of the property_hash
  mk_resource_methods

  def status=(value)
    @property_flush[:status] = value
  end

  def weight=(value)
    @property_flush[:weight] = value
  end

  def compression=(value)
    @property_flush[:compression] = value
  end

  def max_connections=(value)
    @property_flush[:max_connections] = value
  end

  def max_replication_lag=(value)
    @property_flush[:max_replication_lag] = value
  end

  def use_ssl=(value)
    @property_flush[:use_ssl] = value
  end

  def max_latency_ms=(value)
    @property_flush[:max_latency_ms] = value
  end

  def comment=(value)
    @property_flush[:comment] = value
  end
end
