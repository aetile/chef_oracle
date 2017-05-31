# -*- mode: ruby; coding: utf-8; -*-

# Create LVM volumes
include_recipe 'lvm::default'

# Does not support physical volume resize
if node['lvm']['enabled']
  node['lvm']['vgs'].each do |lvm_vg_name, lvm_vg|
    # Create LVM physical volumes
    lvm_vg['devices'].each do |lvm_pv|
      #lvm_pv_action = (lvm.physical_volumes[lvm_pv].nil?) ? :create : :resize
      lvm_physical_volume "#{lvm_pv}" do
        # action lvm_pv_action
         action :create
         not_if "pvs | grep #{lvm_pv}"
      end
    end

    #lvm_vg['devices'].each do |lvm_pv|
    #  #lvm_pv_action = (lvm.physical_volumes[lvm_pv].nil?) ? :create : :resize
    #  lvm_physical_volume lvm_pv do
    #    # action lvm_pv_action
    #     action :resize
    #     only_if "pvs | grep #{lvm_pv}"
    #  end
    #end

    # Create LVM volume groups  
    #lvm_vg_action = (lvm.volume_groups[lvm_vg_name].nil?) ? :create : :extend
    lvm_volume_group lvm_vg_name do
      physical_volumes lvm_vg['devices']
      #action lvm_vg_action
      action :create
      not_if "vgs | grep #{lvm_vg_name}"
    end

    lvm_volume_group lvm_vg_name do
      physical_volumes lvm_vg['devices']
      #action lvm_vg_action
      action :extend
      only_if "vgs | grep #{lvm_vg_name}"
    end

    # Create LVM logical volumes
    lvm_vg['lvs'].each do |lvm_lv_name, lvm_lv|
      #lvm_lv_action = (lvm.logical_volumes[lvm_lv_name].nil?) ? :create : :resize
      lvm_logical_volume lvm_lv_name do
        group lvm_vg_name
        size lvm_lv['default_size']
        filesystem lvm_lv['fs_type']
        mount_point lvm_lv['mount_point']
        #action lvm_lv_action
        action :create
        not_if "lvs | grep #{lvm_lv_name}"
      end

      lvm_logical_volume lvm_lv_name do
        group lvm_vg_name
        size lvm_lv['default_size']
        filesystem lvm_lv['fs_type']
        mount_point lvm_lv['mount_point']
        #action lvm_lv_action
        action :resize
        only_if "lvs | grep #{lvm_lv_name}"
      end
    end
  end
end

