module ForemanInventoryUpload
  module Generators
    class Slice
      attr_accessor :slice_id

      def initialize(hosts, output = [], slice_id = Foreman.uuid)
        @stream = JsonStream.new(output)
        @hosts = hosts
        @slice_id = slice_id
      end

      def render
        report_slice(@hosts)
        @stream.out
      end

      private

      def report_slice(hosts_batch)
        @stream.object do
          @stream.simple_field('report_slice_id', @slice_id)
          @stream.array_field('hosts', :last) do
            first = true
            hosts_batch.each do |host|
              @stream.comma unless first
              first = false
              report_host(host)
            end
          end
        end
      end

      def report_host(host)
        @stream.object do
          @stream.simple_field('display_name', host.name)
          @stream.simple_field('fqdn', host.fqdn)
          @stream.simple_field('account', host.subscription_facet.pools.first.account_number.to_s)
          @stream.simple_field('subscription_manager_id', host.subscription_facet.uuid)
          @stream.simple_field('satellite_id', host.subscription_facet.uuid)
          @stream.simple_field('bios_uuid', fact_value(host, 'dmi::system::uuid'))
          @stream.simple_field('vm_uuid', fact_value(host, 'virt::uuid'))
          @stream.array_field('ip_addresses') do
            @stream.raw(host.interfaces.map do |nic|
              @stream.stringify_value(nic.ip) if nic.ip
            end.compact.join(', '))
          end
          @stream.array_field('mac_addresses') do
            @stream.raw(host.interfaces.map do |nic|
              @stream.stringify_value(nic.mac) if nic.mac
            end.compact.join(', '))
          end
          @stream.object_field('system_profile', :last) do
            report_system_profile(host)
          end
        end
      end

      def report_system_profile(host)
        @stream.simple_field('number_of_cpus', fact_value(host, 'cpu::cpu(s)').to_i)
        @stream.simple_field('number_of_sockets', fact_value(host, 'cpu::cpu_socket(s)').to_i)
        @stream.simple_field('cores_per_socket', fact_value(host, 'cpu::core(s)_per_socket').to_i)
        @stream.simple_field('system_memory_bytes', fact_value(host, 'memory::memtotal').to_i)
        @stream.array_field('network_interfaces') do
          @stream.raw(host.interfaces.map do |nic|
            {
              'ipv4_addresses': [nic.ip].compact,
              'ipv6_addresses': [nic.ip6].compact,
              'mtu': nic.mtu,
              'mac_address': nic.mac,
              'name': nic.identifier,
            }.compact.to_json
          end.join(', '))
        end
        @stream.simple_field('bios_vendor', fact_value(host, 'dmi::bios::vendor'))
        @stream.simple_field('bios_version', fact_value(host, 'dmi::bios::version'))
        @stream.simple_field('bios_release_date', fact_value(host, 'dmi::bios::relase_date'))
        if (cpu_flags = fact_value(host, 'lscpu::flags'))
          @stream.array_field('cpu_flags') do
            @stream.raw(cpu_flags.split.map do |flag|
              @stream.stringify_value(flag)
            end.join(', '))
          end
        end
        @stream.simple_field('os_release', fact_value(host, 'distribution::name'))
        @stream.simple_field('os_kernel_version', fact_value(host, 'uname::release'))
        @stream.simple_field('arch', host.architecture&.name)
        @stream.simple_field('subscription_status', host.subscription_status_label)
        @stream.simple_field('katello_agent_running', host.content_facet&.katello_agent_installed?)
        @stream.simple_field('satellite_managed', true)
        unless (installed_products = host.subscription_facet&.installed_products).empty?
          @stream.array_field('installed_products') do
            @stream.raw(installed_products.map do |product|
              {
                'name': product.name,
                'id': product.cp_product_id,
              }.to_json
            end.join(', '))
          end
        end
        @stream.array_field('installed_packages', :last) do
          first = true
          host.installed_packages.each do |package|
            @stream.raw("#{first ? '' : ', '}#{@stream.stringify_value(package.nvra)}")
            first = false
          end
        end
      end

      def fact_value(host, fact_name)
        value_record = host.fact_values.find do |fact_value|
          fact_value.fact_name_id == ForemanInventoryUpload::Generators::Queries.fact_names[fact_name]
        end
        value_record&.value
      end
    end
  end
end
