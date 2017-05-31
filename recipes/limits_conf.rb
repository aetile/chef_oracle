# -*- mode: ruby; coding: utf-8; -*-

# Set system limits for Oracle user
node['limits']['params'].each do |lim_domain, lim_params|
  if lim_domain == 'system'
    lim_domain = '*'
  end
  lim_params.each do |lim_type, lim_config|
    lim_config.each do |lim_item, lim_value|
      set_limit lim_domain do
        type lim_type
        item lim_item
        value lim_value
        action [:delete, :create]
      end
    end
  end
end

