require 'test_helper'

class GroupCountsControllerTest < ActionDispatch::IntegrationTest

	Observation::ENUMERATED_CONCEPTS[0..4].each do |concept|
	
		Observation::ENUMERATED_CONCEPTS[-5..-1].each do |group|

			test "should get group_count_path(concept: #{concept}, group: #{group})" do
				get group_count_path( concept: concept, group: group )
				assert_response :success
			end

		end

	end

end
