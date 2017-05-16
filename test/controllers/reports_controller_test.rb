require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest

	test "should get index" do
		get reports_url
		assert_response :success
	end

end
