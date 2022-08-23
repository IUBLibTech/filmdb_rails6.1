class WorkflowStatsController < ApplicationController
	include PhysicalObjectsHelper

	def shipped_so_far
		@physical_objects = PhysicalObject.joins(:workflow_statuses).where("workflow_statuses.status_name = '#{WorkflowStatus::SHIPPED_EXTERNALLY}' and physical_object_id is not null").uniq
		#@total = @physical_objects.inject(0){|sum, p| p.estimated_duration_in_sec + sum}
		respond_to do |format|
			format.csv {send_data pos_to_cvs(@physical_objects), filename: 'shipped_so_far.csv' }
		end
	end

	def digitization_staging_stats
		ns = 'Not Specified'
		@physical_objects = PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::TWO_K_FOUR_K_SHELVES)
		@gauges = {}
		@can_sizes = {ns => 0}
		@scan_resolutions = {"nil" => 0}
		@physical_objects.each do |p|
			p = p.specific
			if p.has_attribute?(:guage)
				if @gauges[p.gauge].nil?
					@gauges[p.gauge] = 0
				end
				@gauges[p.gauge] += 1
			end

			if (p.has_attribute?(:can_size))
				if p.can_size.blank?
					@can_sizes[ns] += 1
				else
					if @can_sizes[p.can_size].nil?
						@can_sizes[p.can_size] = 0
					end
					@can_sizes[p.can_size] += 1
				end
			end

			cg = p.active_scan_settings
			if @scan_resolutions[cg.scan_resolution].nil?
				if cg.scan_resolution.blank?
					@scan_resolutions['nil'] += 1
					next
				else
					@scan_resolutions[cg.scan_resolution] = 0
				end
			end
			@scan_resolutions[cg.scan_resolution] += 1

		end
		render partial: 'digitization_staging_stats'
	end

	private
	def pos_to_cvs(physical_objects)
		headers = ["IU Barcode", "Title(s)", "Collection", "Estimated Duration"]
		CSV.generate(headers: true) do |csv|
			csv << headers
			physical_objects.each do |p|
				csv << [p.iu_barcode, p.titles_text, (p.collection.blank? ? "" : p.collection.name), hh_mm_sec(p.estimated_duration_in_sec)]
			end
			csv << ['', '', '', hh_mm_sec(physical_objects.inject(0){|sum, p| sum + p.estimated_duration_in_sec})]
		end
	end

end
