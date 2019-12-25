class AddPrimaryColumnTo<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column :<%= table_name.to_sym %>, :primary, :boolean, default: false, null: false
  end
end

