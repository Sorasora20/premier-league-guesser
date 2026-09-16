class Player < ApplicationRecord
  def age
    return nil unless date_of_birth
    now = Time.now.utc.to_date
    now.year - date_of_birth.year - ((now.month > date_of_birth.month || (now.month == date_of_birth.month && now.day >= date_of_birth.day)) ? 0 : 1)
  end

  def tier
    return 'Unranked' if popularity.nil?

    case popularity
    when 10.0..Float::INFINITY then 'S'
    when 3.0...10.0 then 'A'
    when 0.5...3.0 then 'B'
    when 0.1...0.5 then 'C'
    else 'D'
    end
  end
end
