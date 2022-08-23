class CreateTitleForms < ActiveRecord::Migration[4.2]
  def up
    create_table :title_forms do |t|
      t.integer :title_id, limit: 8
      t.string :form
      t.timestamps
    end
    vals = [
        'Advertising', 'Advertising - Company promotion', 'Advertising - Infomercial', 'Advertising - Political commercial',
        'Advertising - Promotional announcement', 'Advertising - Public service announcement', 'Amateur', 'Amateur - Home Movie',
        'Animation', 'Animation - Abstract animation', 'Animation - Cameraless animation', 'Animation - Clay animation',
        'Animation - Combination live action and animation', 'Animation - Computer animation', 'Animation - Cutout animation',
        'Animation - Pinscreen animation', 'Animation - Pixillation animation', 'Animation - Silhouette animation', 'Animation - Time-lapse animation',
        'Anthology', 'Audition', 'Excerpt', 'Feature', 'Outtake', 'Performance', 'Puppet', 'Serial', 'Series', 'Short', 'Stock shot',
        'Television', 'Television commercial', 'Television feature', 'Television mini-series', 'Television pilot', 'Television series',
        'Television special', 'Trailer', 'Unedited'
    ]
    vals.each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'TitleForm', model_attribute: ':form', value: v, index: i).save
    end
  end

  def down
    drop_table :title_forms
  end
end
