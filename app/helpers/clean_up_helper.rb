module CleanUpHelper

  def clean_duplicate_title_summary
    titles = Title.where("summary like '% | %'")
    titles.each do |t|
      sums = t.summary.split(" | ")
      if all_sums_equal?(sums)
        t.update(summary: sums[0]) unless sums.length == 0
      end
    end
  end

  def all_sums_equal?(sums)
    return true if sums.size == 0
    sum = sums[0]
    return true if sums.size == 1
    all_equal = true
    [1..sums.size].each do |s|
      if sums[s] != sum
        all_equal = false
        break
      end
    end
    all_equal
  end
end
