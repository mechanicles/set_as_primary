class AddPrimaryColumnTo<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column :<%= table_name %>, :<%= flag_name %>, :boolean, default: false, null: false
    <%- if support_partial_index -%>
    # NOTE: Please uncomment following line if you want only one 'true' (constraint) in the table.
    # add_index :<%= table_name %>, <%= index_on %>, unique: true, where: "(<%= table_name %>.<%= flag_name %> IS TRUE)"
    <%- end -%>
  end
end

