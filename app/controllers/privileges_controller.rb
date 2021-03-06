# This class controls the frontend functions for
# displaying privileges and searching. It also
# offers a JSON API for searching and retrieving
# Patron Statuses and their associated privileges.
#
class PrivilegesController < ApplicationController
  # Redirect authenticated user to their patron status
  before_action :redirect_to_patron_status, only: :index_patron_statuses
  respond_to :html, :json, :js

  # GET /patrons
  # GET /patrons.json
  def index_patron_statuses
    @patron_status_search = patron_status_search
    respond_with(@patron_status_search.hits) do |format|
      format.json { render json: @patron_status_search.results }
    end
  end

  # GET /patrons/1
  # GET /patrons/1.json
  # GET /patrons/1.js
  def show_patron_status
    @patron_status = PatronStatus.find_by_code(params[:patron_status_code]) || PatronStatus.find(params[:id])

    # Add patron status code to parameters so sublibrary search get only those with access
    params[:patron_status_code] = @patron_status.code
    @sublibraries_with_access = patron_status_search.sublibraries_with_access
    @sublibraries = sublibrary_search.hits.group_by { |sublibrary| sublibrary.stored(:under_header) }
    @sublibrary = Sublibrary.find_by_code(params[:sublibrary_code])
    @patron_status_permissions = patron_status_permission_search.sublibrary_permissions if @sublibrary

    respond_with(@patron_status) do |format|
      format.json do
        render json: {
          patron_status_permissions: @patron_status_permissions,
          sublibrary: @sublibrary,
          patron_status: @patron_status
        }, layout: false
      end

      format.html { render :show_patron_status }
    end
  end

  # GET /search?q=
  def search
    #Solr search based on params[:q]
    @patron_status_search = patron_status_search

    respond_to do |format|
      format.json { render json: @patron_status_search.results.map(&:web_text), layout: false }
	    #If only one patron status is returned, redirect just to that one
	    format.html do
        if @patron_status_search.total == 1
          patron_status_hit = @patron_status_search.hits.first
	        redirect_to patron_status_link(patron_status_hit.to_param, patron_status_hit.stored(:web_text))
          return
        end
	    end
    end
  end

  # Redirect to user's patron status as found in the database on first login
  def redirect_to_patron_status
    return if session[:redirected_user] || current_user.nil?

    # If current user exists and the user has not been previously redirected...
    # Redirect user to their patron status page
    params[:patron_status_code] = current_user.patron_status
    @patron_status = patron_status_search.hits.first
    session[:redirected_user] = true # Set this session variable so that the user does not get redirected infinitely and the user can choose other statuses

    return if @patron_status.nil? || performed?

    redirect_to patron_status_link(@patron_status.primary_key, @patron_status.stored(:web_text)) and return
  end

  private

  def patron_status_search
    @patron_status_search ||= Privileges::Search::PatronStatusSearch.new(**patron_status_search_params)
  end

  def patron_status_search_params
    params
      .permit(:q, :sort, :direction, :page, :patron_status_code, :sublibrary_code)
      .to_h
      .symbolize_keys
      .merge(admin_view: admin_view?)
      .select { |_k, v| v.present? }
  end

  def sublibrary_search
    @sublibrary_search ||= Privileges::Search::SublibrarySearch.new(**sublibrary_search_params)
  end

  def sublibrary_search_params
    params.permit(:q, :sort, :direction, :page)
      .select{ |k,v| v.present? }.to_h.symbolize_keys.merge(admin_view: admin_view?)
  end

  def patron_status_permission_search
    @patron_status_permission_search ||= Privileges::Search::PatronStatusPermissionSearch.new(
      patron_status_code: @patron_status&.code,
      sublibrary_code: @sublibrary&.code,
      admin_view: admin_view?
    )
  end
end
