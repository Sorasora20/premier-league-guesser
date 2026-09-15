require 'open-uri'
require 'nokogiri'
require 'date'

puts "既存のPlayerデータをリセットしています..."
Player.destroy_all

BASE_URL = 'https://www.transfermarkt.co.uk'
LEAGUE_URL = 'https://www.transfermarkt.co.uk/premier-league/startseite/wettbewerb/GB1'

HEADERS = {
  'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
  'Accept-Language' => 'en-GB,en-US;q=0.9,en;q=0.8',
  'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
}

# ==========================================
# ステップ1: 全クラブのURLを取得
# ==========================================
puts "【ステップ1】プレミアリーグのクラブ一覧を取得中..."
league_html = URI.open(LEAGUE_URL, HEADERS).read
league_doc = Nokogiri::HTML(league_html)

club_urls = []
league_doc.css('table.items > tbody > tr > td.hauptlink > a').each do |link|
  href = link['href']
  if href.include?('startseite/verein')
    club_urls << "#{BASE_URL}#{href}"
  end
end
club_urls.uniq!

puts "全 #{club_urls.count} クラブのURLを取得しました。"

# ==========================================
# ステップ2: 全選手のURLを取得
# ==========================================
puts "【ステップ2】各クラブから選手のURLを収集しています（少し時間がかかります）..."
player_urls = []

club_urls.each do |club_url|
  sleep(rand(2.0..3.0))
  begin
    club_html = URI.open(club_url, HEADERS).read
    club_doc = Nokogiri::HTML(club_html)
    
    club_doc.css('table.items td.hauptlink a').each do |link|
      href = link['href']
      if href.include?('/profil/spieler/')
        player_urls << "#{BASE_URL}#{href}"
      end
    end
  rescue => e
    puts "クラブURLの取得中にエラー: #{club_url} (#{e.message})"
  end
end
player_urls.uniq!

puts "全 #{player_urls.count} 人の選手URLを収集しました！"
puts "いよいよ選手の詳細データを取得してDBに保存します..."
puts "※完了まで30分〜40分ほどかかる場合があります。そのままお待ちください。"

# ==========================================
# ステップ3: 選手ごとの詳細データを取得＆DB保存
# ==========================================
player_urls.each_with_index do |url, index|
  begin
    sleep(rand(2.0..4.0)) # ⚠️絶対にこのsleepを消さないでください
    
    html = URI.open(url, HEADERS).read
    doc = Nokogiri::HTML(html)

    # name
    name = doc.at_css('h1.data-header__headline-wrapper')&.text&.strip&.gsub(/[0-9#\n]/, '')&.strip
    
    # 日付フォーマットの修正 (DD/MM/YYYY または MMM DD, YYYY の両方に対応)
    dob_node = doc.at_xpath("//span[contains(text(), 'Date of birth')]/following-sibling::span")
    date_of_birth = nil
    if dob_node
      dob_text = dob_node.text.strip
      if dob_match = dob_text.match(/(\d{2})\/(\d{2})\/(\d{4})/)
        # 例: 17/01/2001
        date_of_birth = Date.strptime(dob_match[0], '%d/%m/%Y')
      elsif dob_match = dob_text.match(/([A-Z][a-z]{2} \d{1,2}, \d{4})/)
        # 例: Oct 23, 1999
        date_of_birth = Date.parse(dob_match[1])
      end
    end

    # 身長フォーマットの修正 ("5 ft 10 in" を cm に変換)
    height_node = doc.at_xpath("//span[contains(text(), 'Height:')]/following-sibling::span")
    height = nil
    if height_node
      height_text = height_node.text.strip
      if height_text.match(/(\d+)\s*ft\s*(\d+)\s*in/)
        # フィートとインチをcmに変換し整数で保存 (1 ft = 30.48 cm, 1 in = 2.54 cm)
        ft = $1.to_i
        inch = $2.to_i
        height = ((ft * 30.48) + (inch * 2.54)).round
      elsif height_text.match(/(\d+)[.,](\d+)\s*m/)
        # 例: 1,78 m -> 178
        height = ($1 + $2).ljust(3, '0').to_i
      else
        height = height_text.gsub(/[^0-9]/, '').to_i
      end
    end

    # nationality
    nationality_node = doc.at_xpath("//span[contains(text(), 'Citizenship:')]/following-sibling::span")
    nationality = nationality_node ? nationality_node.text.strip.gsub(/\s+/, ' ') : nil

    # position (余分な改行やスペースを整理)
    position_node = doc.at_xpath("//span[contains(text(), 'Position:')]/following-sibling::span")
    position = position_node ? position_node.text.strip.gsub(/\s+/, ' ') : nil

    # preferred_foot
    foot_node = doc.at_xpath("//span[contains(text(), 'Foot:')]/following-sibling::span")
    preferred_foot = foot_node ? foot_node.text.strip : nil

    # club (余分な改行やスペースを整理)
    club_node = doc.at_xpath("//span[contains(text(), 'Current club:')]/following-sibling::span")
    club = club_node ? club_node.text.strip.gsub(/\s+/, ' ') : nil

    # DBへ保存
    Player.find_or_create_by!(name: name) do |p|
      p.club = club
      p.date_of_birth = date_of_birth
      p.height = height
      p.nationality = nationality
      p.position = position
      p.preferred_foot = preferred_foot
    end
    
    puts "[#{index + 1}/#{player_urls.count}] ✅ 保存成功: #{name} (#{club}) - #{height}cm - #{date_of_birth}"

  rescue OpenURI::HTTPError => e
    puts "[#{index + 1}/#{player_urls.count}] ❌ アクセスエラー (#{url}): #{e.message}"
    sleep(10)
  rescue => e
    puts "[#{index + 1}/#{player_urls.count}] ❌ データ抽出エラー (#{url}): #{e.message}"
  end
end

puts "🎉 全ての処理が完了しました！ (現在登録されている選手数: #{Player.count}人)"