class CorrectTitleControlNumber < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :catalog_key, :string
    PhysicalObject.transaction do
      the_a_s = PhysicalObject.where("title_control_number LIKE 'a%'")
      the_not_a_s = PhysicalObject.where("title_control_number NOT LIKE 'a%' AND title_control_number IS NOT null and title_control_number != ''")
      total = the_a_s.size + the_not_a_s.size
      current = 1
      the_a_s.each do |p|
	      puts "#{current} of #{total}"
	      current += 1
        p.update(catalog_key: p.title_control_number[1..-1])
      end
      the_not_a_s.each do |p|
	      puts "#{current} of #{total}"
	      current += 1
	      p.update(title_control_number: "a#{p.title_control_number}", catalog_key: p.title_control_number)
      end
    end
  end
end
