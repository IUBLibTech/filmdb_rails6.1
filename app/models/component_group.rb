class ComponentGroup < ApplicationRecord
  belongs_to :title
  has_many :component_group_physical_objects
  has_many :physical_objects, through: :component_group_physical_objects

  accepts_nested_attributes_for :component_group_physical_objects, allow_destroy: true


  BEST_COPY_WELLS = 'Best Copy (Wells)'
  BEST_COPY_MDPI_WELLS = 'Best Copy (MDPI - WELLS)'
  BEST_COPY_ALF = 'Best Copy (MDPI)'
  REFORMATTING_MDPI = 'Reformatting (MDPI)'
  CATALOG_WELLS = "Cataloging"
  DIGITIZATION_WELLS = "Digitization"
  EVALUATION_WELLS = "Evaluation"
  EXHIBITION_WELLS = "Exhibition"
  RESEARCHER_WELLS = "Researcher"
  TEACHING_WELLS = "Teaching"

  # new, generic CG type for EVERYTHING post-MDPI - implementation started 5/24
  WORKFLOW_WELLS = "Workflow (Wells)"
  WORKFLOW_ALF = "Workflow (ALF)"


  ALL_TYPES = [
      BEST_COPY_ALF, BEST_COPY_MDPI_WELLS, BEST_COPY_WELLS, REFORMATTING_MDPI, CATALOG_WELLS, DIGITIZATION_WELLS,
      EVALUATION_WELLS, EXHIBITION_WELLS, RESEARCHER_WELLS, TEACHING_WELLS
  ]
  ALF_TYPES = [BEST_COPY_ALF, REFORMATTING_MDPI, WORKFLOW_ALF]
  BEST_COPY_TYPES = [BEST_COPY_ALF, BEST_COPY_MDPI_WELLS]

  MDPI_GROUP_TYPES = [BEST_COPY_ALF, BEST_COPY_MDPI_WELLS, REFORMATTING_MDPI]
  ALF_DELIVERY_GROUPS = [BEST_COPY_ALF, REFORMATTING_MDPI, WORKFLOW_ALF]
  WELLS_DELIVERY_GROUPS = [BEST_COPY_MDPI_WELLS, CATALOG_WELLS, DIGITIZATION_WELLS,
                           EVALUATION_WELLS, EXHIBITION_WELLS, RESEARCHER_WELLS, TEACHING_WELLS, WORKFLOW_WELLS]

  COLOR_SPACE_LIN_10 = 'Linear 10 bit'
  COLOR_SPACE_LIN_16 = 'Linear 16 bit'
  COLOR_SPACE_LOG_10 = 'Logarithmic 10 bit'
  COLOR_SPACES = [COLOR_SPACE_LIN_10, COLOR_SPACE_LIN_16, COLOR_SPACE_LOG_10]

  SCAN_RESOLUTIONS = %w(2k 4k 5k HD)
  CLEAN = %w(Yes No Hand\ clean\ only)

  # sort pos by component group type on the Pull Request page
  PULL_REQUEST_GROUP_SORT_ORDER = [WORKFLOW_WELLS, WORKFLOW_ALF, REFORMATTING_MDPI, BEST_COPY_ALF, BEST_COPY_MDPI_WELLS, BEST_COPY_WELLS, CATALOG_WELLS, DIGITIZATION_WELLS, EVALUATION_WELLS, EXHIBITION_WELLS, RESEARCHER_WELLS, TEACHING_WELLS]

  def generations
    gen_set = Set.new
    physical_objects.each do |p|
      p.humanize_boolean_generation_fields().split(',').each do |g|
        gen_set << g.strip
      end
    end
    gen_set.to_a.sort.join(', ').tr('"', '')
  end

  # this check is to see if ALL physical objects in the CG are in storage (ingested, not ingested, freezer, awaiting freezer)
  # can be queued for pull request
  def can_be_pulled?
    physical_objects.each do |p|
      unless p.current_workflow_status.can_be_pulled?
        return false
      end
    end
    true
  end

  # this checks to see if ALL physical objects in the CG are at Just Inventoried (Wells or ALF), and as such can move
  # into their respective next location in workflow (based on their component group type)
  def can_move_into_workflow?
    physical_objects.each do |p|
      return false if (p.current_location != WorkflowStatus::JUST_INVENTORIED_ALF && p.current_location != WorkflowStatus::JUST_INVENTORIED_WELLS)
    end
    true
  end

  # checks to see if at least one physical object satisfies can_be_pulled? and everything else is either in can_be_pulled? state
  # or is can_move_into_workflow state
  def can_move_or_be_pulled?
    one_pullable = physical_objects.select{|p| p.current_workflow_status.can_be_pulled? }.size > 0
    all = physical_objects.each {|p| p.current_workflow_status.can_be_pulled? || (p.current_location != WorkflowStatus::JUST_INVENTORIED_ALF && p.current_location != WorkflowStatus::JUST_INVENTORIED_WELLS) }.size == physical_objects.size
    one_pullable && all
  end

  def deliver_to_alf?
    ALF_DELIVERY_GROUPS.include?(group_type)
  end

  def deliver_to_wells?
   WELLS_DELIVERY_GROUPS.include?(group_type)
  end

  def is_reformating?
	  group_type.include?('Reformatting') || group_type.include?('Best Copy')
  end

  def all_present?
    physical_objects.size == 0 || physical_objects.collect{|p| p.current_location}.uniq.size == 1
  end

  def pos_best_copy_able?
    locs = physical_objects.collect { |p| p.current_location }.uniq - [WorkflowStatus::MISSING]
    locs == [WorkflowStatus::BEST_COPY_MDPI_WELLS] || locs == [WorkflowStatus::BEST_COPY_ALF]
  end

  def whose_workflow
    MDPI_GROUP_TYPES.include?(group_type) ? WorkflowStatus::MDPI : WorkflowStatus::IULMIA
  end

  def is_mdpi_workflow?
    MDPI_GROUP_TYPES.include?(group_type)
  end
  def is_iulmia_workflow?
    !is_mdpi_workflow?
  end

	def in_active_workflow?
    # noinspection RubyResolve
    physical_objects.any?{|p| p.active_component_group == self}
  end

  def humanize_delivery_location
    if group_type == WORKFLOW_ALF
      "ALF"
    elsif group_type == WORKFLOW_WELLS
      "Wells"
    else
      group_type
    end
  end

end
