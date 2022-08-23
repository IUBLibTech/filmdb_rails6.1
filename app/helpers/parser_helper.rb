module ParserHelper
  # the column headers that spreadsheets should contain - only the 5 metadata fields required to create a physical object
  # are required in the spreadsheet headers, but if optional fields are supplied, they must conform to this vocabulary
  PO_HEADERS = [
      'Medium', 'Unit', 'Collection', 'Current Location', 'IU Barcode', 'MDPI Barcode', 'IUCat Title No.',
      'Format Notes', 'Overall Condition', 'Research Value', 'Overall Condition Notes', 'Condition Type', 'Miscellaneous Condition Type', 'Conservation Actions',
      'Accompanying Documentation', 'Created By', 'Email Address', 'Research Value Notes', 'Date Created',
      'Accompanying Documentation Location', 'ALF Shelf Location', 'Catalog Key'
  ]
  # The indexes in PO_HEADERS at which each attribute occurs
  MEDIUM, UNIT, COLLECTION, CURRENT_LOCATION, IU_BARCODE, MDPI_BARCODE, IUCAT_TITLE_NO = 0,1,2,3,4,5,6
  FORMAT_NOTES, OVERALL_CONDITION, RESEARCH_VALUE, OVERALL_CONDITION_NOTES = 7,8,9,10
  CONDITION_TYPE, MISCELLANEOUS_CONDITION_TYPE, CONSERVATION_ACTIONS = 11,12,13
  ACCOMPANYING_DOCUMENTATION, CREATED_BY, EMAIL_ADDRESS, RESEARCH_VALUE_NOTES, DATE_CREATED = 14,15,16,17,18
  ACCOMPANYING_DOCUMENTATION_LOCATION, ALF_SHELF_LOCATION, CATALOG_KEY = 19,20,21

  # regexes for parsing
  CONDITION_PATTERN = /([a-zA-z]+) \(([\d])\)/
  NAME_ROLE_PATTERN = /^([a-zA-Z ]+) \(([a-zA-z ]+)\)$/

  # Delimiter used in columns with multiple values present
  DELIMITER = ' ; '

  def self.duplicate_count(array)
    array.each_with_object(Hash.new(0)) do |value, hash|
      # Keep a count of all the unique values encountered
      hash[value] += 1
    end.each_with_object([ ]) do |(value,count), result|
      # Collect those with count > 1 into a result array.
      if (count > 1)
        result << value
      end
    end
  end

end
