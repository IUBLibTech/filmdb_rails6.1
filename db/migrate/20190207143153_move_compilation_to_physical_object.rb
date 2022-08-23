class MoveCompilationToPhysicalObject < ActiveRecord::Migration[4.2]
  def up
    # Current version of the database does not need this migration
    # Title.transaction do
    #   add_column :physical_objects, :compilation, :string
    #   tos = Title.where.not(compilation: [nil, ''])
    #   tos.each do |t|
    #     pos = t.physical_objects
    #     pos.each do |p|
    #       p.update!(compilation: t.compilation)
    #     end
    #   end
    #   remove_column :titles, :compilation
    # end
  end

  def down
    # there is no rollback from this migration as there is no way to know which title to assign the compilation to
    # if the physical object has multiple titles.
  end
end
