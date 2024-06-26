module ApplicationHelper

	# this method is based on the Luhn algorithm (aka Mod 10)
	# wikipedia provides a clear explanation of it:
	# http://en.wikipedia.org/wiki/Luhn_algorithm#Implementation_of_standard_Mod_10
	def ApplicationHelper.valid_barcode?(barcode, mdpi=false)
		if barcode.is_a?(Integer) || barcode.is_a?(Float)
			barcode = barcode.to_i.to_s
		end

		# IUCAT will auto-assign an ITEM ID when a record is catalogued when it's barcode is not known. Because of this, test
		# for these identifiers. They follow the pattern of xxxxxxx-xxxx
		return false if barcode.include? '-'

		# differentiates between MDPI barcodes (begin with the number 4) and IU barcodes ()begin with the number 3)
		mode = mdpi == true ? '4' : '3'

		if barcode.nil? or barcode.length != 14 or barcode[0] != mode
			return false
		end

		check_digit = barcode.chars.pop.to_i
		sum = 0
		barcode.reverse.chars.each_slice(2).map do |even, odd|
			o = (odd.to_i * 2).divmod(10)
			sum += o[0] == 0 ? o[1] : o[0] + o[1]
			sum += even.to_i
		end
		# need to remove the check_digit from the sum since it was added in the iteration and
		# should not be part of the total sum
		((sum - check_digit) * 9) % 10 == check_digit
	end

	def format_newlines(text)
		text.gsub(/\n/, '<br>').html_safe unless text.nil?
	end

	def ApplicationHelper.real_barcode?(barcode)
		ApplicationHelper.valid_barcode?(barcode) && barcode.to_s != "0"
	end

	def ApplicationHelper.mdpi_barcode_assigned?(barcode)
		b = false
		if (po = PhysicalObject.where(mdpi_barcode: barcode).limit(1)).size == 1
			b = po[0]
		elsif (cs = CageShelf.where(mdpi_barcode: barcode).limit(1)).size == 1
			b = cs[0]
		end
		return b
	end

	def ApplicationHelper.iu_barcode_assigned?(barcode)
		b = false
		if (po = PhysicalObject.where(iu_barcode: barcode)).size == 1
			b = po[0]
		end
		return b
	end

	def ApplicationHelper.current_user_object
		User.current_user_object
	end

	def bool_to_yes_no(val)
		if val.is_a? String
			val.blank? ? '' : (val == '0' ? 'No' : 'Yes')
		else
			val.nil? ? '' : (val ? 'Yes' : 'No')
		end
	end

	def eq_file_location
		# in here so it can used in views
		"tmp/#{User.current_username}_#{"equipment"}.xlsx"
	end

	def medium_symbol_from_params(params)
		if params[:film]
			:film
		elsif params[:video]
			:video
		elsif params[:recorded_sound]
			:recorded_sound
		else
			raise "Unsupported Physical Object Medium #{params.keys}"
		end
	end

	def self.hide_sql
		ActiveRecord::Base.logger.level = 1
	end
	def self.show_sql
		ActiveRecord::Base.logger.level = 0
	end

end
