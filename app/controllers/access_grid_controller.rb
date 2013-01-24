# This class controls the frontend functions for 
# displaying privileges and searching. It also 
# offers a JSON API for searching and retrieving 
# Patron Statuses and their associated privileges.
#
class AccessGridController < ApplicationController
  # Redirect authenticated user to their patron status
  before_filter :redirect_to_patron_status, :only => :index_patron_statuses
    
  # GET /patrons
  # GET /patrons.json
  def index_patron_statuses
    @patron_statuses = patron_statuses_hits
    
    respond_to do |format|
      format.json do
        render :json => patron_statuses_results, 
        :layout => false and return
      end
      format.html
    end
  end
  
  # GET /patrons/1
  # GET /patrons/1.json
  # GET /patrons/1.js
  def show_patron_status
    @patron_status = PatronStatus.find(params[:id])
    # Add patron status code to parameters so sublibrary search get only those with access
    params.merge!({:patron_status_code => @patron_status.code})
    @sublibraries_with_access = sublibraries_with_access
    @sublibraries = sublibraries_hits.group_by {|sublibrary| sublibrary.stored(:under_header)}
    @sublibrary = Sublibrary.find_by_code(params[:sublibrary_code])
  	@patron_status_permissions = patron_status_sublibrary_permissions
	  
    respond_to do |format|
      format.json do 
        render :json => {
          :patron_status_permissions => @patron_status_permissions, 
          :sublibrary => @sublibrary, 
          :patron_status => @patron_status }, 
        :layout => false and return
      end
	    format.js do
	      render :layout => false and return if request.xhr?
	    end
	    format.html unless performed?
    end
  end
  
  # GET /search?q=
  def search
    #Solr search based on params[:q]
    @patron_statuses = patron_statuses_search

    respond_to do |format|
	    #If only one patron status is returned, redirect just to that one
	    format.html do 
	      redirect_to patron_status_link(@patron_statuses.results[0].id, @patron_statuses.results[0].web_text) and return if @patron_statuses.results.count == 1 
	    end
	    format.json do 
	      render :json => @patron_statuses.results.map(&:web_text), 
	             :layout => false and return
      end
    end
  end
  
  # Redirect to user's patron status as found in the database on first login
  def redirect_to_patron_status
    #If current user exists and the user has not been previously redirected...
    if !session[:redirected_user] && !current_user.nil?
      debugger
      #Redirect user to their patron status page
      params.merge!({:patron_status_code => current_user.user_attributes[:bor_status]})
      @patron_status = patron_statuses_hits.first
      session[:redirected_user] = true #Set this session variable so that the user does not get redirected infinitely and the user can choose other statuses
      unless @patron_status.nil?
        redirect_to patron_status_link(@patron_status.primary_key, @patron_status.stored(:web_text)) and return unless performed?
      end
    end
  end

end



