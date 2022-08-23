module TitlesHelper
	require 'roo'
	include ApplicationHelper
	# attempts to merge all mergees into the master title record - physical objects are reassigned, all non-duplicate creator,
	# publisher, date, genre, form, etc data is also moved over to the master record.
	# Titles that are in active workflow will not be merged unless force_merge = true. It is then up to the calling code to
	# sort out any active component groups since this will leave the title's physical objects in an inconsistent state.
	#
	# This method returns an array of any titles not merged
	def title_merge(master, mergees, force_merge=false)
		failed = []
		fix_component_groups(master, mergees, force_merge)
		mergees.each do |m|
			if m.in_active_workflow? && !force_merge
				failed << m
				next
			end
			if (master.series_id.nil? && !m.series_id.nil?)
				master.series_id = m.series_id
			end
			puts("\n\n\n\nMaster: #{master.summary}\n\nMerge: #{m.summary}")
			master.summary = (master.summary.blank? ? m.summary : master.summary + (m.summary.blank? ? '' : " | #{m.summary}"))
			master.series_part = (master.series_part.blank?  ? m.series_part : master.series_part + (m.series_part.blank? ? '' : " | #{m.series_part}"))
			master.notes = (master.notes.blank? ? m.notes : master.notes + (m.notes.blank? ? '' : " | #{m.notes}"))
			master.subject = (master.subject.blank? ? m.subject : master.subject + (m.subject.blank? ? '' : master.subject + " | #{m.subject}"))
			puts("After: #{master.summary}")
			m.title_original_identifiers.each do |toi|
				unless master.title_original_identifiers.include? toi
					master.title_original_identifiers << toi
				end
			end
			m.title_creators.each do |tc|
				unless master.title_creators.collect.include? tc
					master.title_creators << tc
				end
			end
			m.title_publishers.each do |tp|
				unless master.title_publishers.collect.include? tp
					master.title_publishers << tp
				end
			end
			m.title_forms.each do |tf|
				unless master.title_forms.collect.include? tf
					master.title_forms << tf
				end
			end
			m.title_genres.each do |tg|
				unless master.title_genres.collect.include? tg
					master.title_genres << tg
				end
			end
			m.title_dates.each do |td|
				unless master.title_dates.collect.include? td
					master.title_dates << td
				end
			end
			m.title_locations.each do |tl|
				unless master.title_locations.collect.include? tl
					master.title_locations << tl
				end
			end
			PhysicalObjectTitle.where(title_id: m.id).update_all(title_id: master.id)
			m.delete
		end
		last_mod_id = master&.modifier.nil? ? nil : master.modifier.id
		Modification.new(object_type: 'Title', object_id: master.id, user_id: last_mod_id).save!
		master.modifier = User.current_user_object
		master.save
		failed
	end

	def fix_component_groups(master, mergees, force_merge)
		ms = "This component group was created before other titles were merged into this title."
		master.component_groups.each do |cg|
			cg.group_summary = (cg.group_summary.blank? ? ms : " | #{ms}" )
			cg.save
		end
		ms = "This Component Group belonged to a title that was merged into this record. It may no longer be relevant."
		mergees.each do |t|
			if t.in_active_workflow? && !force_merge
				next
			end
			t.component_groups.each do |cg|
				cg.title_id = master.id
				cg.group_summary = (cg.group_summary.blank? ? ms : " | #{ms}" )
				cg.save
			end
		end
	end

	def title_search_to_xls(titles)


	end

	def title_search_to_csv(titles)
		headers = ["IU Barcode","MDPI Barcode", "All Title(s) on Media", "Matching Title (If more than one title on media)", "Series Title", "Series Part", "Title Country of Origin",
							 "Title Summary", "Title Original Identifiers", "Title Publishers", "Title Creators",
							 "Title Genres","Title Forms", "Title Dates",
							 "Title Locations", "Title Notes", "Title Subject", "Title Name Authority",
							 "IUCat Title Control Number","Catalog Key", "Alternative Title",
							 "Media Type","Medium","Version","Unit","Collection",
							 "Gauge", "Generation","Generation Notes", "Can Size", "Footage", "Duration", "Reel Dates",
							 "Base", "Stock", "Original Identifiers",
							 "Reel Number", "Multiple Items in Can", "Picture Type", "Frame Rate", "Color",
							 "Aspect Ratio", "Anamorphic", "Sound",
							 "Captions/Subtitles", "Format Type", "Content Type", "Sound Field",
							 "Track Count", "Languages", "Format Notes",
							 "Accompanying Documentation", "Accompanying Documentation Location", "Overall Condition", "Condition Notes",
							 "Research Value", "Research Value Notes", "AD Strip", "Shrinkage", "Mold",
							 "Conditions",
							 "Missing Footage", "Miscellaneous", "Conservation Actions", "Title Last Modified By"
							 ]
		CSV.generate(headers: true) do |csv|
			csv << headers
			titles.each do |t|
				t.physical_objects.each do |p|
					p = p.specific
					if p.medium == 'Film'
						csv << [
								p.iu_barcode, p.mdpi_barcode, p.titles_text, t.title_text, t.series_title_text, t.series_part, t.country_of_origin,
								t.summary, (t.title_original_identifiers.collect {|i| "#{i.identifier} [#{i.identifier_type}]"}.join(', ') unless t.title_original_identifiers.size == 0), (t.title_publishers.collect {|p| "#{p.name} [#{p.publisher_type}]"}.join(', ') unless t.title_publishers.size == 0), (t.title_creators.collect {|c| "#{c.name} [#{c.role}]"}.join(', ') unless t.title_creators.size == 0),
								(t.title_genres.collect {|g| g.genre}.join(', ') unless t.title_genres.size == 0), (t.title_forms.collect {|f| f.form}.join(', ') unless t.title_forms.size == 0), (t.title_dates.collect {|d| "#{d.date_text} [#{d.date_type}]"}.join(', ') unless t.title_dates.size == 0),
								(t.title_locations.collect {|l| l.location}.join(', ') unless t.title_locations.size == 0), t.notes, t.subject, t.name_authority,
								p.title_control_number, p.catalog_key, p.alternative_title,
								p.media_type, p.medium, p.humanize_version_fields, p.unit&.name, p.collection&.name,
								p.gauge, p.humanize_generations_fields, p.generation_notes, p.can_size, p.footage, p.duration, (p.physical_object_dates.collect {|d| "#{d.date} [#{d&.controlled_vocabulary.value}]"}.join(', ') unless p.physical_object_dates.size == 0),
								p.humanize_base_fields, p.humanize_stock_fields, (p.physical_object_original_identifiers.collect {|oi| oi.identifier}.join(', ') unless p.physical_object_original_identifiers.size == 0),
								p.reel_number, bool_to_yes_no(p.multiple_items_in_can), p.humanize_picture_type_fields, p.frame_rate, p.humanize_color_fields,
								p.humanize_aspect_ratio_fields, p.anamorphic, p.sound,
								bool_to_yes_no(p.close_caption), p.humanize_sound_format_fields, p.humanize_sound_content_fields, p.humanize_sound_configuration_fields,
								p.track_count, (p.languages.collect {|l| "#{l.language} [#{l.language_type}]"}.join(', ') unless p.languages.size == 0), p.format_notes,
								p.accompanying_documentation, p.accompanying_documentation_location, p.condition_rating, p.condition_notes,
								p.research_value, p.research_value_notes, p.ad_strip, p.shrinkage, p.mold,
								((p.boolean_conditions.collect {|c| "#{c.condition_type} (#{c.comment})"} + p.value_conditions.collect {|c| "#{c.condition_type}: #{c.value} (#{c.comment})"}).join(' | ') unless (p.boolean_conditions.size == 0 && p.value_conditions.size == 0)),
								p.missing_footage, p.miscellaneous, p.conservation_actions, t.modifier&.username
						]
					elsif p.medium == 'Video'
						csv << [
								p.iu_barcode, p.mdpi_barcode, p.titles_text, t.title_text, t.series_title_text, t.series_part, t.country_of_origin,
								t.summary, (t.title_original_identifiers.collect {|i| "#{i.identifier} [#{i.identifier_type}]"}.join(', ') unless t.title_original_identifiers.size == 0), (t.title_publishers.collect {|p| "#{p.name} [#{p.publisher_type}]"}.join(', ') unless t.title_publishers.size == 0), (t.title_creators.collect {|c| "#{c.name} [#{c.role}]"}.join(', ') unless t.title_creators.size == 0),
								(t.title_genres.collect {|g| g.genre}.join(', ') unless t.title_genres.size == 0), (t.title_forms.collect {|f| f.form}.join(', ') unless t.title_forms.size == 0), (t.title_dates.collect {|d| "#{d.date_text} [#{d.date_type}]"}.join(', ') unless t.title_dates.size == 0),
								(t.title_locations.collect {|l| l.location}.join(', ') unless t.title_locations.size == 0), t.notes, t.subject, t.name_authority,
								p.title_control_number, p.catalog_key, p.alternative_title,
								p.media_type, p.medium, p.humanize_version_fields, p.unit&.name, p.collection&.name,
								p.gauge, p.humanize_generations_fields, p.generation_notes, '', '', p.duration, (p.physical_object_dates.collect {|d| "#{d.date} [#{d&.controlled_vocabulary.value}]"}.join(', ') unless p.physical_object_dates.size == 0),
								p.humanize_base_fields, p.humanize_stock_fields, (p.physical_object_original_identifiers.collect {|oi| oi.identifier}.join(', ') unless p.physical_object_original_identifiers.size == 0),
								p.reel_number, '', p.humanize_picture_type_fields, '', p.humanize_color_fields,
								p.humanize_aspect_ratio_fields, '', p.sound,'', p.humanize_sound_format_fields,
								p.humanize_sound_content_fields, p.humanize_sound_configuration_fields,
								'', (p.languages.collect {|l| "#{l.language} [#{l.language_type}]"}.join(', ') unless p.languages.size == 0), p.format_notes,
								p.accompanying_documentation, p.accompanying_documentation_location, p.condition_rating, p.condition_notes,
								p.research_value, p.research_value_notes, '', '', p.mold,
								((p.boolean_conditions.collect {|c| "#{c.condition_type} (#{c.comment})"} + p.value_conditions.collect {|c| "#{c.condition_type}: #{c.value} (#{c.comment})"}).join(' | ') unless (p.boolean_conditions.size == 0 && p.value_conditions.size == 0)),
								p.missing_footage, p.miscellaneous, p.conservation_actions, t.modifier&.username
						]
					elsif p.medium == 'Recorded Sound'
						csv << [
								p.iu_barcode, p.mdpi_barcode, p.titles_text, t.title_text, t.series_title_text, t.series_part, t.country_of_origin,
								t.summary, (t.title_original_identifiers.collect {|i| "#{i.identifier} [#{i.identifier_type}]"}.join(', ') unless t.title_original_identifiers.size == 0), (t.title_publishers.collect {|p| "#{p.name} [#{p.publisher_type}]"}.join(', ') unless t.title_publishers.size == 0), (t.title_creators.collect {|c| "#{c.name} [#{c.role}]"}.join(', ') unless t.title_creators.size == 0),
								(t.title_genres.collect {|g| g.genre}.join(', ') unless t.title_genres.size == 0), (t.title_forms.collect {|f| f.form}.join(', ') unless t.title_forms.size == 0), (t.title_dates.collect {|d| "#{d.date_text} [#{d.date_type}]"}.join(', ') unless t.title_dates.size == 0),
								(t.title_locations.collect {|l| l.location}.join(', ') unless t.title_locations.size == 0), t.notes, t.subject, t.name_authority,
								p.title_control_number, p.catalog_key, p.alternative_title,
								p.media_type, p.medium, p.humanize_version_fields, p.unit&.name, p.collection&.name,
								p.gauge, p.humanize_generations_fields, p.generation_notes, '', '', p.duration, (p.physical_object_dates.collect {|d| "#{d.date} [#{d&.controlled_vocabulary.value}]"}.join(', ') unless p.physical_object_dates.size == 0),
								p.humanize_base_fields, '', (p.physical_object_original_identifiers.collect {|oi| oi.identifier}.join(', ') unless p.physical_object_original_identifiers.size == 0),
								'', '', '', '', '', '', '', '','', '', p.humanize_sound_content_fields, p.humanize_sound_configuration_fields,
								'', (p.languages.collect {|l| "#{l.language} [#{l.language_type}]"}.join(', ') unless p.languages.size == 0), p.format_notes,
								p.accompanying_documentation, p.accompanying_documentation_location, p.condition_rating, p.condition_notes,
								p.research_value, p.research_value_notes, '', '', p.mold,
								((p.boolean_conditions.collect {|c| "#{c.condition_type} (#{c.comment})"} + p.value_conditions.collect {|c| "#{c.condition_type}: #{c.value} (#{c.comment})"}).join(' | ') unless (p.boolean_conditions.size == 0 && p.value_conditions.size == 0)),
								'', p.miscellaneous, p.conservation_actions
						]
					else
						raise "Unsupported Physical Object medium: #{@physical_object.medium}"
					end
				end
			end
		end
	end

end
