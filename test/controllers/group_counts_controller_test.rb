require 'test_helper'

class GroupCountsControllerTest < ActionDispatch::IntegrationTest

	%w(b2_mother_cig_prev
		b2_mother_cig_first_tri
		b2_mother_cig_second_tri
		b2_mother_cig_last_tri
		m_alcohol_use
		m_drug_use
		m_drug_otc
		m_drug_prescription
		mother_age_group
		mom_race1
		momrace_ethnchs
		b2_source_pay_code
		b2_tobacco_use
		b2_prenatal_yesno
		b2_mother_wic_yesno
		m_breastfeeding
	).each do |v|

#	Change to concept and group

		test "should get group_count_path(v: #{v})" do

			get group_count_path(v: v)
			assert_response :success
		end

	end

end
