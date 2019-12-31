class AddPrimaryColumnTo<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column :<%= table_name %>, :<%= flag_name %>, :boolean, default: false, null: false
    add_index :<%= table_name %>, <%= index_on.inspect %>, unique: true, where: "(<%= table_name %>.<%= flag_name %> IS TRUE)"
  end
end

