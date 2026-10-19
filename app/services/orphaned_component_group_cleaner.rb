# app/services/orphaned_component_group_cleaner.rb
# title deletions result in workflow statuses that reference component groups that have dead titles. Since workflow
# status is computed at multiple locations, need to update all dead CGs to reference the first title of any PO in the CG
# that has active workflow statuses
class OrphanedComponentGroupCleaner
  def retitle_cgs
    bad_cgs = ComponentGroup.includes(:physical_objects).left_outer_joins(:title).where(titles: { id: nil })
    bad_cgs.each do |cg|
      puts "#{cg.id}"
      cg.physical_objects.each do |p|
        puts "\t#{p.iu_barcode}"
      end
    end
    ComponentGroup.transaction do
      bad_cgs.each do |cg|
        pos = cg.physical_objects

        if pos.empty?
          cg.destroy!
        else
          tid = pos.first.titles.first.id
          cg.update!(title_id: tid)
        end
      end
    end
  end

end