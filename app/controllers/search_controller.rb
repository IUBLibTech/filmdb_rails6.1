class SearchController < ApplicationController
  include PhysicalObjectsHelper
	def barcode_search
		@physical_object = PhysicalObject.where("iu_barcode = ? OR mdpi_barcode = ?", params[:barcode], params[:barcode]).first
		if @physical_object.nil?
			@physical_object = PhysicalObjectOldBarcode.includes(:physical_object).where(iu_barcode: params[:barcode]).first&.physical_object
		end
		if @physical_object
			redirect_to @physical_object
		else
			@obj = CageShelf.where(mdpi_barcode: params[:barcode]).first
			if @obj
				@cage = @obj.cage
				render 'cages/cage'
			else
				render 'search/search_results'
			end
		end
	end

  def search
		po = PhysicalObject.where("iu_barcode = ? OR mdpi_barcode = ?", params[:barcode], params[:barcode]).first
		if po.nil?
			po = PhysicalObjectOldBarcode.includes(:physical_object).where(iu_barcode: params[:barcode]).first&.physical_object
		end

		@pos = PhysicalObject.joins(:physical_object_original_identifiers).where("physical_object_original_identifiers.identifier = ?", params[:barcode])
		@pos << po unless po.nil?
		if @pos.size == 0
			# check for cage shelves
			@obj = CageShelf.where(mdpi_barcode: params[:barcode]).first
			redirect_to @obj
		elsif @pos.size == 1
			redirect_to @pos.first
		else
			render 'search/search_results'
		end
	end

end