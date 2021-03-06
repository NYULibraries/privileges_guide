# This class handles the model that maps patron status
# and sublibrary to a given set of permissions
#
class PatronStatusPermissionsController < ApplicationController
  before_action :authenticate_admin

  # POST /patron_status_permissions
  # POST /patron_status_permissions.js
  def create
    @patron_status_permission = PatronStatusPermission.new(patron_status_permission_params)
    @sublibrary = Sublibrary.find_by_code(params[:patron_status_permission][:sublibrary_code])
    @patron_status = PatronStatus.find_by_code(params[:patron_status_permission][:patron_status_code])
    @permission_values = PermissionValue.where(permission_code: params[:permission_code])

    respond_to do |format|
      if @patron_status_permission.save
        # If ajax response is submitted, the partial is rerendered with @permission_values populated
        format.js { render layout: false and return } if request.xhr?
        format.html do
          redirect_to patron_status_path(@patron_status, sublibrary_code: sublibrary_code),
                      notice: t('patron_status_permissions.create_success') and return
        end
      else
        format.js { render layout: false and return } if request.xhr?
        format.html do
          redirect_to patron_status_path(@patron_status, sublibrary_code: sublibrary_code, permission_code: params[:permission_code]),
                      flash: { danger: t('patron_status_permissions.create_failure') } and return
        end
      end
    end
  end

  # PUT /patron_status_permissions/1
  # PUT /patron_status_permissions/1.js
  def update
    @patron_status_permission = PatronStatusPermission.find(params[:id])
    @sublibrary = Sublibrary.find_by_code(@patron_status_permission.sublibrary_code)
    @patron_status = PatronStatus.find_by_code(@patron_status_permission.patron_status_code)
    @permission_values = PermissionValue.where(permission_code: params[:permission_code])
    # @patron_status_permissions = patron_status_permission_search.solr_search if @sublibrary
    respond_to do |format|
      if @patron_status_permission.update_attributes(patron_status_permission_params)
        format.js { render layout: false and return } if request.xhr?# In the case where an ajax response is submitted just save the new value and do nothing
        format.html do
          redirect_to patron_status_path(@patron_status, sublibrary_code: sublibrary_code),
                      notice: t('patron_status_permissions.update_success') and return
        end
      else
        format.js { render layout: false and return }if request.xhr?
        format.html do
          redirect_to patron_status_path(@patron_status, sublibrary_code: sublibrary_code),
                      flash: { danger: t('patron_status_permissions.update_failure') } and return
        end
      end
    end
  end

  # PUT /patron_status_permissions
  def update_multiple
    @sublibrary = Sublibrary.find_by_code(patron_status_permission_params[:sublibrary_code])
    @patron_status = PatronStatus.find_by_code(patron_status_permission_params[:patron_status_code])

    params.require(:update_permission_ids).each do |perm|
      psp = PatronStatusPermission.find(perm.first)
      if psp.permission_value_id != perm.last.to_i
        psp.permission_value_id = perm.last
        psp.save
      end
    end

    respond_to do |format|
      format.html do
        redirect_to patron_status_path(@patron_status, sublibrary_code: sublibrary_code),
                    notice: t('patron_status_permissions.update_multiple_success') and return
      end
    end
  end

  # DELETE /patron_status_permission/1
  def destroy
    @patron_status_permission = PatronStatusPermission.find(params[:id])
    @sublibrary = @patron_status_permission.sublibrary
    @patron_status = @patron_status_permission.patron_status
    @patron_status_permission.destroy

    respond_to do |format|
      format.html do
        redirect_to patron_status_path(@patron_status, sublibrary_code: sublibrary_code),
                    notice: t('patron_status_permissions.destroy_success') and return
      end
    end
  end

  private
  def patron_status_permission_params
    if params[:patron_status_permission].present?
      params.require(:patron_status_permission).permit(:patron_status_code, :sublibrary_code, :permission_value_id, :from_aleph, :visible)
    else
      {}
    end
  end

  # Shortcut for retrieving sublibrary code if it exists
  def sublibrary_code
    @sublibrary_code ||= @sublibrary.code unless @sublibrary.nil?
  end

  # Shortcut for retrieving sublibrary object
  def sublibrary
    @sublibrary ||= ::Sublibrary.find_by_code(params[:sublibrary_code]) if params[:sublibrary_code].present?
  end

  def patron_status_permission_search
    @patron_status_permission_search ||= Privileges::Search::PatronStatusPermissionSearch.new(
      patron_status_code: @patron_status&.code,
      sublibrary_code: @sublibrary&.code,
      admin_view: admin_view?
    )
  end
end
