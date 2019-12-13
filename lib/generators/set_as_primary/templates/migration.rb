class AddPrimaryColumnTo<%= attributes[:table_name].camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column attributes[:table_name].to_sym, :primary, :boolean, default: false
  end
end

