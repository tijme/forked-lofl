# Ansible role

Define your variables in `vars.yaml`, see `vars.example.yaml` for inspiration.

Execute using the following command, where `router_vm` is the VM where you want to run the router in:

    ansible-playbook -i router_vm, playbook.yaml -e @vars.yaml
