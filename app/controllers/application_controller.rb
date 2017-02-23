class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	def valid_find_page
		#	0 is apparently bad.
		( !params[:page].blank? && ( params[:page].to_i > 0 ) ) ? params[:page] : 1
	end

end
