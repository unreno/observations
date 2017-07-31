class GroupCountsController < ApplicationController

	def show
		@concepts = Observation::ENUMERATED_CONCEPTS
		if params[:concept].present? and params[:group].present?
			@results = Observation.group_counts params[:concept], params[:group]
		end
	end

end
