module EdgeCodeHelper
  # KODAK edge codes are visual representations of the dates film stock was produced. They are comprised of a sequence
  # of 1 - 3 symbols, with the sumbols being a circle, triangle, square, "X", or "+".
  #
  # This module converts individual symbols to numbers that can be stored in the database.

  CIRCLE_HTML = '&#9679;'
  TRIANGEL_HTML = "&#9650;"
  SQUARE_HTML = '&#9632;'
  MULT_HTML = "&#10006;"
  PLUS_HTML = '&#10010;'

  CIRCLE = 'c'
  TRIANGLE = 't'
  SQUARE = 's'
  MULT = 'm'
  PLUS = 'p'

  CODE_MAP = {
    CIRCLE => CIRCLE_HTML, TRIANGLE => TRIANGEL_HTML, SQUARE => SQUARE_HTML, MULT => MULT_HTML, PLUS => PLUS_HTML
  }

  ALL = %w(c cc ccc cs csc csm ct ctc cp cpc cmt s sc scc sct ss ssc sst st stc stt sp spc spt t tc tcc tct ts tsc tst
tt ttc ttt tp tpc tpt p pc pcc pct ps psc pst pt ptc ptt pp ppc ppt mcc mct mst msc mtc mtt mtm mpc mpt mpm)

  # takes one of the values from ALL and converts it to an HTML representation of the code
  def self.codeToHTML(x)
    html = ""
    x.chars.each do |c|
      html << CODE_MAP[c]
    end
    html.html_safe
  end

  def self.options_for_select
    vals = []
    ALL.each do |c|
      vals << [codeToHTML(c).html_safe, c]
    end
    vals
  end

end
