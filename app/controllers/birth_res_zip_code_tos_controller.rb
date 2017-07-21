class BirthResZipCodeTosController < ApplicationController

	def show
#		@concepts = %w{ b2_prenatal_yesno m_alcohol_use m_drug_use }
		@concepts = Observation::ENUMERATED_CONCEPTS
		if params[:v].present?
			@value = case params[:v]
				when 'b2_prenatal_yesno' then 'Prenatal Care'
				when 'm_alcohol_use' then 'Alcohol Use'
				when 'm_drug_use' then 'Drug Use'
				when 'm_drug_otc' then 'OTC Drug Use'
				when 'm_drug_prescription' then 'Prescription Drug Use'
				when 'b2_source_pay_code' then 'Source Pay'
				when 'b2_tobacco_use' then 'Tobacco Use'
				when 'mother_age_group' then "Mother's Age Group"

				when 'mom_race1' then "Mother's CDC Race"
				when 'momrace_ethnchs' then "Mother's race & ethnic NCHS"
	
				when 'b2_mother_wic_yesno' then "WIC"
				when 'm_breastfeeding' then "Breastfeeding"
				else params[:v]
			end
			@results = Observation.birth_res_zip_code_to params[:v]
		end
	end

end
