#
# Copyright Peter Donald
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Chef::Asadmin

use_inline_resources

action :create do
  command = []
  command << "create-auth-realm"
  command << asadmin_target_flag
  command << "--classname" << new_resource.classname
  properties = new_resource.properties.dup
  properties['jaas-context'] = new_resource.jaas_context if new_resource.jaas_context
  properties['assign-groups'] = new_resource.assign_groups if new_resource.assign_groups
  command << "--property" << encode_parameters(properties)
  command << new_resource.name

  bash "asadmin_enable_default_principal_to_role_mapping" do
    # Hack: Force domain to treat groups/roles the same.
    Chef::Log.info "Turning on Default Principal-to-Role-Mapping"
    code asadmin_command("set server-config.security-service.activate-default-principal-to-role-mapping=true")
  end

  bash "asadmin_create_auth_realm #{new_resource.name}" do
    not_if "#{asadmin_command('list-auth-realms')} #{new_resource.target} | grep -x -- '#{new_resource.name}'"
    user new_resource.system_user
    group new_resource.system_group
    Chef::Log.info "Creating Realm: " + new_resource.name
    code asadmin_command(command.join(' '))
  end
end

action :delete do
  command = []
  command << "delete-auth-realm"
  command << asadmin_target_flag
  command << new_resource.name

  bash "asadmin_delete_auth_realm #{new_resource.name}" do
    only_if "#{asadmin_command('list-auth-realms')} #{new_resource.target} | grep -x -- '#{new_resource.name}'"
    user new_resource.system_user
    group new_resource.system_group
    code asadmin_command(command.join(' '))
  end
end
