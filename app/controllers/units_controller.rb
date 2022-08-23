class UnitsController < ApplicationController

	before_action :set_unit, only: [:show, :edit, :update, :destroy]

	def index
		@units = Unit.all.order('menu_index DESC, abbreviation ASC')
	end

	def show
	end

	def new
		@unit = Unit.new
	end

	def create
		@unit = Unit.new(unit_params)
		respond_to do |format|
			if @unit.save
				format.html { redirect_to @unit, notice: 'Unit was successfully created.' }
				format.json { render :show, status: :created, location: @unit }
			else
				format.html { render :new_physical_object }
				format.json { render json: @unit.errors, status: :unprocessable_entity }
			end
		end
	end

	def edit
	end

	def update
		respond_to do |format|
			if @unit.update(unit_params)
				format.html { redirect_to @unit, notice: 'Unit was successfully updated.' }
				format.json { render :show, status: :ok, location: @unit }
			else
				format.html { render :edit }
				format.json { render json: @unit.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		authorize Unit
		@unit.destroy
		respond_to do |format|
			format.html { redirect_to units_url, notice: 'Unit was successfully destroyed.' }
			format.json { head :no_content }
		end
	end

	private
	def set_unit
		@unit = Unit.find(params[:id])
	end

	def unit_params
		params.require(:unit).permit(:name, :unit_id, :abbreviation, :institution, :campus, :menu_index)
	end
end
