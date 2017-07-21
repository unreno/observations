require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest

	test "should get index" do
		get reports_url
		assert_response :success
	end

	%w{
		birth_counts_by_quarter_reports
		birth_counts_by_month_reports
		parallel_coords_reports
		parallel_coords_csv_reports
		completed_immunizations_reports
		individual_vaccination_counts_by_month_year_reports
		total_vaccination_counts_reports
		birth_weight_to_mom_age_reports
		birth_weight_to_tot_cigs_reports
		birth_weight_group_to_percent_of_reports
		birth_res_zip_code_percents_reports
		ave_birth_weight_to_zip_reports
	}.each do |route|

		test "should get #{route}" do
			get eval("#{route}_url")
			assert_response :success
		end

	end

end
