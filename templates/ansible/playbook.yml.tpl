---

# configure the gateways with vpn connections and dnsmasq for the site

- hosts: gateways
  become: yes
  gather_facts: yes
  vars:
    ansible_python_interpreter: "/usr/bin/env python3"
  tasks:
  - import_role:
      name: ${server_role}
  - import_role:
      name: ${gateway_role}
  - import_role:
      name: ${wireguard_role}
  - import_role:
      name: ${dnsmasq_role}


# configure the samba servers

- hosts: samba
  become: yes
  gather_facts: no
  vars:
    ansible_python_interpreter: "/usr/bin/env python3"
  tasks:
  - import_role:
      name: ${server_role}

- hosts: samba_initial
  become: yes
  gather_facts: no
  vars:
    ansible_python_interpreter: "/usr/bin/env python3"
  tasks:
  - import_role:
      name: ${samba_initial_role}

- hosts: samba_join
  become: yes
  gather_facts: no
  vars:
    ansible_python_interpreter: "/usr/bin/env python3"
  tasks:
  - import_role:
      name: ${samba_join_role}


# associate the dhcp options with the vpcs now dns is running everywhere

- hosts: gateways
  become: yes
  gather_facts: no
  vars:
    ansible_python_interpreter: "/usr/bin/env python3"
  tasks:
  - name: associate dhcp option set for ${site0_name}
    local_action:
      module: amazon.aws.ec2_vpc_dhcp_option
      profile: ${site0_aws_profile}
      region: ${site0_aws_region}
      vpc_id: ${site0_aws_vpc_id}
      dhcp_options_id: ${site0_aws_dhcp_options_id}
    run_once: True
    become: no
  - name: associate dhcp option set for ${site1_name}
    local_action:
      module: amazon.aws.ec2_vpc_dhcp_option
      profile: ${site1_aws_profile}
      region: ${site1_aws_region}
      vpc_id: ${site1_aws_vpc_id}
      dhcp_options_id: ${site1_aws_dhcp_options_id}
    run_once: True
    become: no
  - name: reset networking
    reboot:

- hosts: samba
  become: yes
  gather_facts: no
  vars:
    ansible_python_interpreter: "/usr/bin/env python3"
  tasks:
  - name: reset networking
    reboot:
