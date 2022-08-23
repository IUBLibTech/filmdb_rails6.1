class ChangeProductionDatesToPublicationType < ActiveRecord::Migration[4.2]
  def change
    TitleDate.all.each do |td|
      td.update(date_type: 'Publication Date')
    end
  end
end
