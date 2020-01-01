class AddPrimaryColumnTo<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column :<%= table_name %>, :<%= flag_name %>, :boolean, default: false, null: false

    # NOTE: Please uncomment this line if you want only one 'true' (constraint) in the table.
    # add_index :<%= table_name %>, <%= index_on.inspect %>, unique: true, where: "(<%= table_name %>.<%= flag_name %> IS TRUE)"
  end
end

