class AddCopyrightMetadataToTitles < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :in_copyright, :string
    add_column :titles, :copyright_end_date_edtf, :string
    add_column :titles, :copyright_end_date, :date
    add_column :titles, :copyright_verified_by_iu_cp_research, :boolean
    add_column :titles, :copyright_verified_by_viewing_po, :boolean
    add_column :titles, :copyright_verified_by_other, :boolean
    add_column :titles, :copyright_notes, :text
  end
end
