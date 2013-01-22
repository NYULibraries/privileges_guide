# This controller handles the permissions assigned to sublibraries
# each permission has a set of possible values (PermissionValues)
class PermissionsController < ApplicationController
  before_filter :authenticate_admin
  
  # GET /permissions
  def index
    @permissions = Permission.by_sort_order

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /permissions/1
  def show
    @permission = Permission.find(params[:id])
    @permission_values = PermissionValue.find_all_by_permission_code(@permission.code)
    @permission_value = PermissionValue.new

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /permissions/new
  def new
    @permission = Permission.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /permissions/1/edit
  def edit
    @permission = Permission.find(params[:id])
  end

  # POST /permissions
  def create
    @permission = Permission.new
    @permission.code = "#{prefix}#{params[:permission][:code]}"
    @permission.web_text = params[:permission][:web_text]
    @permission.from_aleph = (params[:permission][:from_aleph]) ? params[:permission][:from_aleph] : false

    respond_to do |format|
      if @permission.save
        flash[:notice] = t("permissions.create_success")
        format.html { redirect_to(@permission) }
      else
        #If failed, set the code back to user-entered code, without prefix
	      @permission.code = params[:permission][:code]
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /permissions/1
  # PUT /permissions/1.js
  def update
    @permission = Permission.find(params[:id])
    @permissions = Permission.by_sort_order

    respond_to do |format|
      if @permission.update_attributes(params[:permission])
        flash[:notice] = t("permissions.update_success")
        format.html { redirect_to(@permission) }
        format.js { render :nothing => true }
      else
        flash[:error] = t("permissions.update_failure")
        format.html { render :action => "edit" }
        format.js { render :nothing => true }
      end
    end
  end
  
  # PUT /permissions/update_order
  # PUT /permissions/update_order.js
  def update_order
    if params[:permissions]
      params[:permissions].each_with_index do |id, index|
        Permission.update_all(['sort_order=?', index+1],['id=?',id])
      end 
    end
    respond_to do |format|
      format.js { render :layout => false }
      format.html { redirect_to permissions_url, notice: t("permissions.update_order_success")  }
    end
  end

  # DELETE /permissions/1
  def destroy
    @permission = Permission.find(params[:id])
    @permission.destroy

    respond_to do |format|
      format.html { redirect_to permissions_url, notice: t("permissions.delete_succes") }
    end
  end
  
  def prefix
    #This handles local creation of patron statuses by adding a namespace prefix, namely nyu_ag_noaleph_
    @prefix ||= (!params[:permission][:from_aleph].nil?) ? local_creation_prefix : ""
  end
  private :prefix

end
