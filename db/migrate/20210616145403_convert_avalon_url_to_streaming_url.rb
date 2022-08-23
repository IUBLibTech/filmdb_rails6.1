class ConvertAvalonUrlToStreamingUrl < ActiveRecord::Migration[4.2]
  require 'net/http'
  require 'net/https'
  def up
    titles = Title.all
    titles.each_with_index  do |t, i|
      puts "Updating stream url for title #{i+1} of #{titles.size}"
      if t.digitized?
        a_url = t.avalon_url
        puts "\t#{a_url}"
        t.update(stream_url: a_url[:url]) unless a_url[:url].blank?
      end
    end
  end
  def down
    Title.all.update(stream_url: nil)
  end
end
