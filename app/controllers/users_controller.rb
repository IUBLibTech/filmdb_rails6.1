class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  skip_before_action :signed_in_user, only: [:show_update_location, :update_location]

  # GET /users
  # GET /users.json
  def index
    authorize User
    @users = User.all.order(:last_name)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    authorize User
  end


  # GET /users/new_physical_object
  def new
    authorize User
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    authorize User
  end

  # POST /users
  # POST /users.json
  def create
    authorize User
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new_physical_object }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    authorize User
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    #authorize User
    #@user.destroy
    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  def show_update_location
    @user = User.find(params[:id])
    render 'update_location'
  end

  def update_location
    @user = User.find(params[:id])
    # rails will not actually save the record if nothing has been altered... need to call touch if the user simply timed out and the location remains the same
    if @user.worksite_location == params[:user][:worksite_location]
	    @user.touch
    else
	    @user.update(worksite_location: params[:user][:worksite_location])
    end
    redirect_back_or_to root_url
  end

  def deleters
    @deletes = DeleteLogEntry.all.order("id DESC")
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(
          :username, :email_address, :first_name, :last_name, :active, :can_delete,
          :works_in_both_locations, :worksite_location, :can_update_physical_object_location,
          :can_edit_users, :can_add_cv
      )
    end
end
