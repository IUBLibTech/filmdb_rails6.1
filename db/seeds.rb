# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# users
User.new(username: 'jaalbrec', first_name: 'Andrew', last_name: 'Albrecht', email_address: 'jaalbrec@indiana.edu', active: true, can_delete: true).save
User.new(username: 'carton', first_name: 'Carla', last_name: 'Arton', email_address: 'carton@indiana.edu', active: true, can_delete: true).save
User.new(username: 'jauhrich', first_name: 'Andy', last_name: 'Uhrich', email_address: 'jauhrich@indiana.edu', active: true, can_delete: true).save
User.new(username: 'shmichae', first_name: 'Sherri', last_name: 'Michaels', email_address: 'shmichae@indiana.edu', active: true).save
User.new(username: 'wgcowan', first_name: 'Will', last_name: 'Cowan', email_address: 'wgcowan@indiana.edu', active: true).save
User.new(username: 'rstoeltj', first_name: 'Rachael', last_name: 'Stoeltje', email_address: 'rstoeltj@indiana.edu', active: true, can_delete: true).save
User.new(username: 'aploshay', first_name: 'Adam', last_name: 'Ploshay', email_address: 'aploshay@iu.edu', active: true).save
User.new(username: 'goodpass', first_name: 'Sabrina', last_name: 'Goodpaster', email_address: 'goodpass@indiana.edu', active: true).save
User.new(username: 'jlhardes', first_name: 'Julie', last_name: 'Hardesty', email_address: 'jlhardes@iu.edu', active: true)
# Units
Unit.new(abbreviation: 'B-IULMIA', name: "Indiana University, Bloomington. Indiana University Libraries Moving Image Archive.", institution: "Indiana University", campus: "Bloomington", menu_index: 1).save
Unit.new(abbreviation: 'B-AAAMC', name: "Indiana University, Bloomington. Archives of African American Music and Culture.", institution: "Indiana University", campus: "Bloomington", menu_index: 2).save
Unit.new(abbreviation: 'B-ARCHIVES', name: "Indiana University, Bloomington. Office of University Archives and Records Management.", institution: "Indiana University", campus: "Bloomington", menu_index: 3).save
Unit.new(abbreviation: 'B-ATM', name: "Indiana University, Bloomington. Archives of Traditional Music.", institution: "Indiana University", campus: "Bloomington", menu_index: 4).save
Unit.new(abbreviation: 'B-BFCA', name: "Indiana University, Bloomington. Black film Center/Archives.", institution: "Indiana University", campus: "Bloomington", menu_index: 5).save
Unit.new(abbreviation: 'B-CEDIR', name: "Indiana University, Bloomington. Indiana Institute on Disability and Community. Center for Disability Information & Referral.", institution: "Indiana University", campus: "Bloomington", menu_index: 6).save
Unit.new(abbreviation: 'B-FINEARTS', name: "Indiana University, Bloomington. Fine Arts Library.", institution: "Indiana University", campus: "Bloomington", menu_index: 7).save
Unit.new(abbreviation: 'B-GBL', name: "Indiana University, Bloomington. Glenn A. Black Laboratory of Archaeology.", institution: "Indiana University", campus: "Bloomington", menu_index: 8).save
Unit.new(abbreviation: 'B-IUAM', name: "Indiana University, Bloomington. Art Museum.", institution: "Indiana University", campus: "Bloomington", menu_index: 9).save
Unit.new(abbreviation: 'B-KINSEY', name: "Indiana University, Bloomington. Kinsey Institute for Research in Sex, Gender, and Reproduction.", institution: "Indiana University", campus: "Bloomington", menu_index: 10).save
Unit.new(abbreviation: 'B-LIBERIA', name: "Indiana University, Bloomington. Liberian Collections.", institution: "Indiana University", campus: "Bloomington", menu_index: 11).save
Unit.new(abbreviation: 'B-LILLY', name: "Indiana University, Bloomington. Lilly Library.", institution: "Indiana University", campus: "Bloomington", menu_index: 12).save
Unit.new(abbreviation: 'B-MATHERS', name: "Indiana University, Bloomington. William Hammond Mathers Museum.", institution: "Indiana University", campus: "Bloomington", menu_index: 13).save

# seed misc collections for each
Unit.all.each do |u|
  # future database builds should not use misc collections
  # if u.misc_collection.nil?
  #   Collection.new(name: 'Misc [not in collection]', unit: u).save
  # end
end
