
module StatsHelper
  def rs_gens
    gens = Hash.new
    RecordedSound::GENERATION_FIELDS.each do |gf|
      count = RecordedSound.where(gf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = recorded_sounds.id").where(po_sql_where).size
      gens[RecordedSound::GENERATION_FIELDS_HUMANIZED[gf]] = count unless count == 0
    end
    gens
  end
  def film_gens
    gens = Hash.new
    Film::GENERATION_FIELDS.each do |gf|
      count = Film.where(gf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = films.id").where(po_sql_where).size
      gens[Film::GENERATION_FIELDS_HUMANIZED[gf]] = count unless count == 0
    end
    gens
  end
  def video_gens
    gens = Hash.new
    Video::GENERATION_FIELDS.each do |gf|
      count = Video.where(gf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = videos.id").where(po_sql_where).size
      gens[Video::GENERATION_FIELDS_HUMANIZED[gf]] = count unless count == 0
    end
    gens
  end

  def po_sql_where
    sql = @unit ? " unit_id = #{@unit.id}" : ""
    sql += @collection ? (sql.length > 0 ? " AND " : "")+"collection_id = #{@collection.id}" : ""
    sql += @startTime ? (sql.length > 0 ? " AND " : "")+"physical_objects.created_at >= '#{@startTime}' AND physical_objects.created_at <= '#{@endTime}' " : ""
    sql
  end
end
